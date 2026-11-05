classdef TestLiteratureRCWA < matlab.unittest.TestCase
    %TESTLITERATURERCWA RCWA against converged values published for classic
    %   gratings (see benchmarks/benchmark_literature_rcwa.m for sources).

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function granetMetallicGratingTE(tc)
            % n = 0.22 + 6.71i lamellar grating, period = wavelength = depth,
            % fill 0.5, 30 deg. Published (Granet 1999): TE 0.7342789 (the
            % Littrow order -1), TM R0 0.8484781 (granetMetallicGratingTM).
            os = orf.rcwa1D(tc.granet(), 1, pi/6, 0, "s", N=80);
            tc.verifyEqual(os.R(os.m == -1), 0.7342789, 'AbsTol', 1e-4);
        end

        function lalanneHugoninDielectricGrating(tc)
            % n = 2.3 ridges (fill 0.234) in air on n = 1.5, period 2 um,
            % depth 1 um, 1 um, 30 deg, TM: first transmitted order 51.062 %
            % (their order -1 is our +1).
            g = orf.makeStructure([2 Inf], orf.materialConst(1), orf.materialConst(1.5), ...
                {orf.makeLayer(1, orf.materialConst(1), {orf.shapeRect(0.468, Inf, orf.materialConst(2.3))})});
            o = orf.rcwa1D(g, 1, pi/6, 0, "p", N=80);
            tc.verifyEqual(o.T(o.m == 1), 0.51062, 'AbsTol', 5e-5);
        end
    end

    methods (Test, TestTags = {'Slow'})
        function granetMetallicGratingTM(tc)
            % TM converges as 1/N for metals: extrapolate from N = 160, 320 (~30 s)
            r0 = zeros(1, 2);
            for k = 1:2
                op = orf.rcwa1D(tc.granet(), 1, pi/6, 0, "p", N=160*k);
                r0(k) = op.R(op.m == 0);
            end
            tc.verifyEqual(r0(1), 0.8484781, 'AbsTol', 3e-4);
            tc.verifyEqual(2 * r0(2) - r0(1), 0.8484781, 'AbsTol', 5e-5);
        end
    end

    methods (Static, Access = private)
        function g = granet()
            met = orf.materialConst(0.22 + 6.71i);
            g = orf.makeStructure([1 Inf], orf.materialConst(1), met, ...
                {orf.makeLayer(1, orf.materialConst(1), {orf.shapeRect(0.5, Inf, met)})});
        end
    end
end
