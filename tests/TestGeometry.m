classdef TestGeometry < matlab.unittest.TestCase
    %TESTGEOMETRY Shared structure description and permittivity sampling.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function uniformStackMatchesDirectTMM(tc)
            air = orf.materialConst(1); sio2 = orf.materialConst(1.45); si = orf.materialConst(3.48);
            dev = orf.makeStructure([Inf Inf], air, si, ...
                {orf.makeLayer(0.2, sio2), orf.makeLayer(0.11, si)});
            lam = linspace(1.2, 1.7, 11).';
            [n, d] = orf.structureToTMM(dev, lam);
            a = orf.tmm(lam, n, d, deg2rad(15), "p");
            b = orf.tmm(lam, [1 1.45 3.48 3.48], [0.2 0.11], deg2rad(15), "p");
            tc.verifyEqual(a.r, b.r, 'AbsTol', 1e-14);
        end

        function patternedLayerRejectedByTMM(tc)
            air = orf.materialConst(1);
            dev = orf.makeStructure([0.5 0.5], air, air, ...
                {orf.makeLayer(0.6, air, {orf.shapeCircle(0.1, orf.materialConst(2))})});
            tc.verifyError(@() orf.structureToTMM(dev, 1.0), 'structureToTMM:patterned');
        end

        function circleFillFraction(tc)
            P = 0.4; r = 0.12; nHi = 2.4;
            layer = orf.makeLayer(0.6, orf.materialConst(1), {orf.shapeCircle(r, orf.materialConst(nHi))});
            [x, y] = orf.cellGrid([P P], 1000, 1000);
            e = orf.layerEps(layer, [P P], x, y, 0.94);
            ff = mean(abs(e(:) - 1) > 1e-9);
            tc.verifyEqual(ff, pi*r^2/P^2, 'AbsTol', 1e-3);
        end

        function periodicWrapAtCorner(tc)
            P = 0.4; r = 0.12;
            mHi = orf.materialConst(2.4);
            centred = orf.makeLayer(0.6, orf.materialConst(1), {orf.shapeCircle(r, mHi)});
            corner = orf.makeLayer(0.6, orf.materialConst(1), {orf.shapeCircle(r, mHi, [P/2 P/2])});
            [x, y] = orf.cellGrid([P P], 400, 400);
            e1 = orf.layerEps(centred, [P P], x, y, 0.94);
            e2 = orf.layerEps(corner, [P P], x, y, 0.94);
            tc.verifyEqual(mean(e2(:)), mean(e1(:)), 'AbsTol', 1e-12);
        end

        function laterShapePaintsOver(tc)
            layer = orf.makeLayer(0.1, orf.materialConst(1), ...
                {orf.shapeRect(0.4, 0.4, orf.materialConst(2)), orf.shapeCircle(0.05, orf.materialConst(3))});
            e = orf.layerEps(layer, [1 1], 0, 0, 1.0);
            tc.verifyEqual(e, complex(9));
        end

        function grating1DWithSubsampling(tc)
            % Line of width 0.25 in a 1 um period on a 4-point grid: the
            % line edges fall mid-cell, so those cells average to half.
            layer = orf.makeLayer(0.3, orf.materialConst(1), {orf.shapeRect(0.25, Inf, orf.materialConst(2))});
            [x, y] = orf.cellGrid([1 Inf], 4);
            tc.verifyEqual(y, 0);
            e = orf.layerEps(layer, [1 Inf], x, y, 1.0, 8);
            tc.verifyEqual(e, complex([1; 2.5; 2.5; 1]), 'AbsTol', 1e-12);
        end

        function lossyMaterialEps(tc)
            layer = orf.makeLayer(0.1, orf.materialConst(1 + 0.5i));
            e = orf.layerEps(layer, [1 1], 0, 0, 1.0);
            tc.verifyEqual(e, complex((1 + 0.5i)^2));
            tc.verifyGreaterThan(imag(e), 0);
        end
    end
end
