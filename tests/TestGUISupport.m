classdef TestGUISupport < matlab.unittest.TestCase
    %TESTGUISUPPORT Progress callbacks, cancellation, resource estimates,
    %   automatic convergence.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function rcwaReportsProgressAndCanBeCancelled(tc)
            dev = TestGUISupport.twoLayers();
            log = [];
            orf.rcwa2D(dev, 1.0, 0, 0, "s", Nx=3, Progress=@(f, ~) record(f));
            tc.verifyEqual(log, [0.5 1], 'AbsTol', 1e-12);
            tc.verifyError(@() orf.rcwa2D(dev, 1.0, 0, 0, "s", Nx=3, ...
                Progress=@(~, ~) error('orf:cancelled', 'stop')), 'orf:cancelled');
            % batches split into chunks report a monotone overall fraction
            devs = repmat({dev}, 1, 5);
            log = [];
            orf.rcwa2D(devs, 1.0, 0, 0, "s", Nx=3, BatchSize=2, Progress=@(f, ~) record(f));
            tc.verifyTrue(all(diff(log) > 0) && abs(log(end) - 1) < 1e-12);
            function record(f), log(end + 1) = f; end
        end

        function fdtdReportsProgressAndCanBeCancelled(tc)
            dx = 0.02; x = (0:dx:4).'; z = (0:3).' * dx;
            s = struct('x', x, 'z', z, 'npml', [15 0], 'periodicZ', true, 'lambdas', 1.5, ...
                'monitors', [30 170], 'eps', ones(numel(x), 4));
            s.source = struct('ix', 40, 'profile', ones(4, 1), 'neff', 1, 'lambda0', 1.5, 'bw', 0.3);
            fr = [];
            s.progress = @(f, ~) record(f);
            o = orf.fdtd2DTE(s);
            tc.verifyTrue(o.converged);
            tc.verifyGreaterThan(numel(fr), 3);
            tc.verifyTrue(all(fr >= 0 & fr <= 1));
            tc.verifyGreaterThan(fr(end), 0.9);              % decayed to the shutoff
            s.progress = @(f, ~) cancelAfter(f);
            tc.verifyError(@() orf.fdtd2DTE(s), 'orf:cancelled');
            function record(f), fr(end + 1) = f; end
            function cancelAfter(f)
                if f > 0.2, error('orf:cancelled', 'stop'); end
            end
        end

        function estimatesHaveTheRightScale(tc)
            e = orf.estimateResources("rcwa", Nx=5, NStructures=2);
            tc.verifyEqual(e.harmonics, 121);
            tc.verifyGreaterThan(e.seconds, 0);
            tc.verifySubstring(e.text, "121 harmonics");
            es = orf.estimateResources("rcwa", Nx=5, NStructures=2, Symmetry=true);
            tc.verifyLessThan(es.seconds, e.seconds / 10);   % ~64x fewer flops
            e3 = orf.estimateResources("fdtd3D", Grid=[100 100 200], Steps=1000);
            tc.verifyEqual(e3.cells, 2e6);
            tc.verifyEqual(e3.memoryGB, 12 * 2e6 * 8 / 1e9, 'RelTol', 1e-12);
            tc.verifyGreaterThan(e3.cellsPerSecond, 1e6);
        end

        function convergeNStopsWhenStable(tc)
            dev = TestGUISupport.twoLayers();
            r = orf.convergeN(@(N) orf.rcwa2D(dev, 1.0, 0, 0, "s", Nx=N).Ttot, Tol=1e-3, Ns=1:2:15);
            tc.verifyTrue(r.converged);
            tc.verifyLessThan(r.history.change(end), 1e-3);
            tc.verifyEqual(r.value, orf.rcwa2D(dev, 1.0, 0, 0, "s", Nx=r.N).Ttot);
            tc.verifyWarning(@() orf.convergeN(@(N) 1 / N, Tol=1e-9, Ns=1:3), ...
                'orf:convergeN:notConverged');
        end
    end

    methods (Static)
        function dev = twoLayers()
            si = orf.materialConst(3.5); air = orf.materialConst(1);
            dev = orf.makeStructure([0.5 0.5], air, orf.materialConst(1.45), ...
                {orf.makeLayer(0.2, air, {orf.shapeCircle(0.15, si)}), ...
                 orf.makeLayer(0.1, air, {orf.shapeRect(0.3, 0.2, si)})});
        end
    end
end
