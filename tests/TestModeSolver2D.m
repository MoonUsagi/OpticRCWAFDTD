classdef TestModeSolver2D < matlab.unittest.TestCase
    %TESTMODESOLVER2D wgModes2D: slab limits, symmetry, SOI strip.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Static)
        function [m, y, e] = slabIn2D()
            % x-invariant Si slab (|y| < 0.11) in SiO2: periodic x, 4 cells.
            dy = 0.01; y = (-1.5:dy:1.5).' + dy/2; x = ((0:3).' + 0.5) * 0.05;
            boxes = [-Inf Inf -0.11 0.11 3.476];
            m = orf.wgModes2D(x, y, 1.444, boxes, 1.55, 2, PeriodicX=true);
            e = m.eps;
        end
    end

    methods (Test)
        function slabLimitTE(tc)
            % E_x polarised (parallel to the layers) = 1D TE on the E_x grid.
            [m, y, e] = TestModeSolver2D.slabIn2D();
            ref = orf.slabModes(y, sqrt(e.x(1, :)).', 1.55, "TE");
            tc.verifyEqual(m.neff(1), ref.neff, 'AbsTol', 1e-9);
            tc.verifyGreaterThan(m.teFraction(1), 0.999);
        end

        function slabLimitTM(tc)
            % E_y polarised (normal to the layers) = 1D TM for h_x on the
            % E_y grid, with eps_y at the points and eps_z between them.
            [m, y, e] = TestModeSolver2D.slabIn2D();
            dy = y(2) - y(1);
            ref = orf.slabModes(y + dy/2, sqrt(e.y(1, :)).', 1.55, "TM", EpsHalf=e.z(1, 2:end).');
            tc.verifyEqual(m.neff(2), ref.neff, 'AbsTol', 2e-7);   % wall treatment differs at the edge
            tc.verifyLessThan(m.teFraction(2), 1e-3);
        end

        function squareCoreIsDegenerate(tc)
            % 90-degree symmetry: the two fundamental modes share neff.
            d = 0.01; c = ((-100:99).' + 0.5) * d;
            m = orf.wgModes2D(c, c, 1.444, [-0.2 0.2 -0.2 0.2 3.476], 1.55, 2);
            tc.verifyEqual(m.neff(1), m.neff(2), 'AbsTol', 1e-6);
            % exact degeneracy: eigs may return any mix, but the pair spans both
            tc.verifyEqual(sum(m.teFraction), 1, 'AbsTol', 1e-3);
        end

        function soiStripTE0(tc)
            % 500 x 220 nm Si strip in SiO2 at 1550 nm: TE0 near 2.44 (literature
            % ~2.44-2.45); refining the grid must change neff by < 3e-3.
            n = zeros(1, 2);
            for k = 1:2
                d = 0.02 / k;
                x = ((-round(1.5/d):round(1.5/d)-1).' + 0.5) * d;
                y = ((-round(1.2/d):round(1.2/d)-1).' + 0.5) * d;
                m = orf.wgModes2D(x, y, 1.444, [-0.25 0.25 -0.11 0.11 3.476], 1.55, 2);
                [~, iTE] = max(m.teFraction);
                n(k) = m.neff(iTE);
            end
            tc.verifyGreaterThan(n(2), 2.40);
            tc.verifyLessThan(n(2), 2.48);
            tc.verifyLessThan(abs(n(2) - n(1)), 3e-3);
        end
    end
end
