classdef TestDesignIO < matlab.unittest.TestCase
    %TESTDESIGNIO saveDesign / loadDesign round trips.

    properties
        File
    end

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (TestMethodSetup)
        function tempFile(tc)
            tc.File = string(tempname) + ".json";
            tc.addTeardown(@() TestDesignIO.deleteIfExists(tc.File));
        end
    end

    methods (Test)
        function deviceGivesIdenticalResults(tc)
            % Every material kind and both shapes, two layers; the reloaded
            % device must give bit-identical RCWA results.
            tl = orf.materialTaucLorentz(120, 3.6, 2.4, 1.6, 1.0, Name="a-Si film");
            tab = orf.materialTable([0.9 1.0 1.1], [2.0 2.1 2.2], [0 0.01 0.02], "measured");
            dev = orf.makeStructure([0.5 0.45], orf.material("air"), orf.material("SiO2"), { ...
                orf.makeLayer(0.3, orf.materialConst(1.2 + 0.01i), ...
                    {orf.shapeCircle(0.12, tl, [0.05 0]), orf.shapeRect(0.1, 0.3, tab, [-0.15 0.02])}), ...
                orf.makeLayer(0.1, orf.material("Si3N4"))});
            orf.saveDesign(tc.File, struct('device', dev));
            back = orf.loadDesign(tc.File);
            run = @(d) orf.rcwa2D(d, 1.0, 0.2, 0.3, "p", Nx=4, Symmetry="none");
            a = run(dev); b = run(back.device);
            tc.verifyEqual(b.R, a.R);
            tc.verifyEqual(b.t, a.t);
            tc.verifyEqual(back.device.layers{1}.shapes{1}.mat.name, "a-Si film");
        end

        function singleLayerAndShapeStayCells(tc)
            % one-element lists must come back as cells, not structs
            dev = orf.makeStructure([0.7 Inf], orf.material("air"), orf.materialConst(1.45), ...
                {orf.makeLayer(0.5, orf.material("air"), {orf.shapeRect(0.35, Inf, orf.materialConst(3.48))})});
            orf.saveDesign(tc.File, dev);
            back = orf.loadDesign(tc.File);
            tc.verifyClass(back.layers, 'cell');
            tc.verifyClass(back.layers{1}.shapes, 'cell');
            tc.verifyEqual(back.period, [0.7 Inf]);
            o1 = orf.rcwa1D(dev, 1.55, 0, 0, "s", N=10); o2 = orf.rcwa1D(back, 1.55, 0, 0, "s", N=10);
            tc.verifyEqual(o2.T, o1.T);
        end

        function parametersRoundTrip(tc)
            p = struct('lambdas', 1.50:0.01:1.60, 'pol', "s", 'pols', ["s" "p"], 'useGPU', false, ...
                'boxes', [-Inf Inf 0 0.22 3.476; 1 2 3 4 5], 'gamma', 2 - 1i, 'empty', [], ...
                'list', {{1, [1 2 3], "x"}}, 'nested', struct('a', NaN, 'b', {{}}));
            orf.saveDesign(tc.File, p);
            [q, info] = orf.loadDesign(tc.File);
            tc.verifyEqual(q.lambdas, p.lambdas, 'AbsTol', 1e-15);
            tc.verifyEqual(q.pol, "s");
            tc.verifyEqual(q.pols, ["s" "p"]);
            tc.verifyEqual(q.useGPU, false);
            tc.verifyEqual(q.boxes, p.boxes);
            tc.verifyEqual(q.gamma, 2 - 1i);
            tc.verifyEmpty(q.empty);
            tc.verifyEqual(q.list, {1, [1 2 3], "x"});
            tc.verifyTrue(isnan(q.nested.a));
            tc.verifyEqual(q.nested.b, {});
            tc.verifyEqual(info.orfVersion, orf.version);
        end

        function readableAndRejectsHandles(tc)
            orf.saveDesign(tc.File, struct('core', orf.material("Si")));
            txt = fileread(tc.File);
            tc.verifySubstring(txt, '"orfMaterial": "library"');
            tc.verifySubstring(txt, '"name": "Si"');
            tc.verifyError(@() orf.saveDesign(tc.File, struct('f', @sin)), 'orf:saveDesign:handle');
            fid = fopen(tc.File, 'w'); fprintf(fid, '{"a": 1}'); fclose(fid);
            tc.verifyError(@() orf.loadDesign(tc.File), 'orf:loadDesign:format');
        end
    end

    methods (Static)
        function deleteIfExists(f)
            if isfile(f), delete(f); end
        end
    end
end
