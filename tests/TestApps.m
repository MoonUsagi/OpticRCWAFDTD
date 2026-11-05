classdef TestApps < matlab.unittest.TestCase
    %TESTAPPS The two design apps, built hidden and driven through their
    %   public methods (the dialogs themselves are not tested).

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function metalensDesignerRunsAndRoundTrips(tc)
            app = orf.MetalensDesigner(Visible=false);
            tc.addTeardown(@() delete(app));
            p = app.params();
            tc.verifyEqual(p.lambda0, 0.94);
            p.D = 4; p.f = 4; p.nLib = 9; p.N = 3; p.pillar = orf.materialConst(3.5 + 0.01i);
            app.setParams(p);
            q = app.params();
            tc.verifyEqual(q.pillar.nk(q.lambda0), 3.5 + 0.01i);
            r = app.run();
            tc.verifyEqual(r.metrics.fwhmLimit, q.lambda0 / (2 * r.NA), 'RelTol', 1e-12);
            tc.verifyGreaterThan(r.metrics.efficiency, 0.3);
            tc.verifySize(r.diameters, [10 10]);
            tc.verifySubstring(app.estimate(), "Lens: 10 x 10 cells");
            f = app.cellField(0.2);
            % absorbing pillar: flux is 1 - R below the cell and T above it
            tc.verifyEqual(f.flux([1 end]), [1 - f.out.Rtot, f.out.Ttot], 'AbsTol', 1e-9);
            % parameters survive a design file
            file = string(tempname) + ".json";
            tc.addTeardown(@() delete(file));
            orf.saveDesign(file, struct('app', "MetalensDesigner", 'params', q));
            app2 = orf.MetalensDesigner(Visible=false);
            tc.addTeardown(@() delete(app2));
            d = orf.loadDesign(file);
            app2.setParams(d.params);
            q2 = app2.params();
            tc.verifyEqual(q2.pillar.nk(1), q.pillar.nk(1));
            tc.verifyEqual(rmfield(q2, {'pillar', 'substrate'}), rmfield(q, {'pillar', 'substrate'}));
        end
    end

    methods (Test, TestTags = {'Slow'})
        function gratingCouplerDesignerRuns(tc)
            app = orf.GratingCouplerDesigner(Visible=false);
            tc.addTeardown(@() delete(app));
            p = app.params();
            p.nPer = 8; p.dx = 0.04; p.nLam = 3; p.useGPU = false;
            app.setParams(p);
            tc.verifySubstring(app.estimate(), "fdtd2D");
            out = app.run();
            tc.verifyLessThan(max(abs(out.res.balance)), 1e-2);
            tc.verifyGreaterThan(out.best.eta, 0.05);
            tc.verifyEqual(out.params.nPer, 8);
        end
    end
end
