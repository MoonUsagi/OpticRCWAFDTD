classdef TestPolygonsAndImport < matlab.unittest.TestCase
    %TESTPOLYGONSANDIMPORT Polygon shapes, sloped sidewalls, GDSII import.

    properties
        Dir
    end

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (TestMethodSetup)
        function tempDir(tc)
            tc.Dir = string(tempname); mkdir(tc.Dir);
            tc.addTeardown(@() rmdir(tc.Dir, 's'));
        end
    end

    methods (Test)
        function gdsPathsBecomePolygons(tc)
            % an L-shaped waveguide path: mitred area = width x centre-line
            % length; square ends add width^2/2 each, round ends a circle
            xy = [0 0; 10 0; 10 5]; w = 1;
            f = fullfile(tc.Dir, "path.gds");
            paths = struct('xy', {xy, xy, xy, [0 0; 3 4]}, 'width', {w, w, w, 0.5}, ...
                'pathtype', {0, 2, 1, 0}, 'layer', {1, 2, 3, 4});
            orf.gdsWrite(f, struct('name', "WG", 'polygons', {{}}, 'paths', paths));
            lib = orf.gdsRead(f);
            [P, L] = orf.gdsFlatten(lib);
            tc.verifyEqual(L, [1 2 3 4]);
            A = cellfun(@(p) polyarea(p(:, 1), p(:, 2)), P);
            n = 32;                                                 % 2 x 16-segment caps
            tc.verifyEqual(A(1), 15, 'AbsTol', 1e-9);
            tc.verifyEqual(A(2), 16, 'AbsTol', 1e-9);
            tc.verifyEqual(A(3), 15 + n / 2 * 0.25 * sin(2 * pi / n), 'AbsTol', 1e-9);
            tc.verifyEqual(A(4), 2.5, 'AbsTol', 1e-9);              % diagonal segment
            tc.verifyEqual(max(P{1}), [10.5 5], 'AbsTol', 1e-12);   % flush end at y = 5
            tc.verifyEqual(min(P{2}), [-0.5 -0.5], 'AbsTol', 1e-12);
        end

        function polygonEqualsRectangle(tc)
            % a square polygon (also rotated by 90 deg) samples exactly like
            % the rectangle on the same grid
            si = orf.materialConst(3.5);
            sq = [-0.1 -0.1; 0.1 -0.1; 0.1 0.1; -0.1 0.1];
            mk = @(s) orf.makeStructure([0.4 0.4], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.3, orf.materialConst(1), {s})});
            run = @(s) orf.rcwa2D(mk(s), 1.0, 0.2, 0.5, "p", Nx=4, Nsample=[400 400], Symmetry="none");
            a = run(orf.shapeRect(0.2, 0.2, si));
            b = run(orf.shapePolygon(sq, si));
            c = run(orf.shapePolygon(sq * [0 1; -1 0], si));
            tc.verifyEqual(b.T, a.T, 'AbsTol', 1e-12);
            tc.verifyEqual(c.T, a.T, 'AbsTol', 1e-12);
        end

        function verticalSidewallIsOneLayer(tc)
            si = orf.materialConst(3.5); air = orf.materialConst(1);
            shp = orf.shapeCircle(0.12, si);
            one = orf.makeStructure([0.4 0.4], air, orf.materialConst(1.45), {orf.makeLayer(0.4, air, {shp})});
            sl = orf.makeStructure([0.4 0.4], air, orf.materialConst(1.45), ...
                orf.slantedLayers(0.4, air, shp, 90, NSlices=4));
            a = orf.rcwa2D(one, 1.0, 0, 0, "s", Nx=4);
            b = orf.rcwa2D(sl, 1.0, 0, 0, "s", Nx=4);
            tc.verifyEqual(b.T, a.T, 'AbsTol', 1e-10);
        end

        function slopedSidewallGeometryAndConvergence(tc)
            % 80 deg circle, base at the bottom: radii shrink upward by
            % h cot(80); the staircase converges as 1/NSlices^2
            air = orf.materialConst(1); si = orf.materialConst(3.5);
            L = orf.slantedLayers(0.4, air, orf.shapeCircle(0.15, si), 80, NSlices=4);
            r = cellfun(@(l) l.shapes{1}.radius, L);
            tc.verifyEqual(r, 0.15 - (0.4 - ((1:4) - 0.5) * 0.1) * cotd(80), 'AbsTol', 1e-14);
            Lp = orf.slantedLayers(0.4, air, orf.shapePolygon([-0.1 -0.1; 0.1 -0.1; 0.1 0.1; -0.1 0.1], si), ...
                80, NSlices=2, Base="top");
            w = 0.2 - 2 * 0.1 * cotd(80);                        % first slice: 0.1 above the base
            tc.verifyEqual(polyarea(Lp{1}.shapes{1}.vertices(:, 1), Lp{1}.shapes{1}.vertices(:, 2)), w^2, 'AbsTol', 1e-8);
            T = zeros(1, 3);
            for k = 1:3
                dev = orf.makeStructure([0.4 0.4], air, orf.materialConst(1.45), ...
                    orf.slantedLayers(0.4, air, orf.shapeCircle(0.15, si), 80, NSlices=4 * 2^(k-1)));
                T(k) = orf.rcwa2D(dev, 1.0, 0, 0, "s", Nx=4).Ttot;
            end
            ratio = abs(T(1) - T(2)) / abs(T(2) - T(3));
            tc.verifyGreaterThan(ratio, 2.5);                    % ~4 for second order
        end

        function cone3DFillsTheRightVolume(tc)
            % mean eps of a cone in a box equals the analytic frustum volume
            % (e.z is arithmetic across vertical walls; on the cone's 14 deg
            % slanted wall its harmonic part along z reads ~0.6 % low)
            d = 0.01; x = (-0.3:d:0.3 - d).'; z = (0:d:0.4 - d).';
            shapes = {{"cone", [0 0 0.2 0.1 0 0.4 2]}};
            e = orf.epsComponents3D(x, x, z, 1, shapes, Period=[0.6 0.6]);
            V = pi * 0.4 / 3 * (0.2^2 + 0.2 * 0.1 + 0.1^2);
            fill = (mean(e.z, 'all') - 1) / (4 - 1);
            tc.verifyEqual(fill, V / (0.6 * 0.6 * 0.4), 'RelTol', 1e-2);
            p = struct('xy', [-0.2 -0.1; 0.2 -0.1; 0 0.2], 'z1', 0, 'z2', 0.4, 'n', 2);
            e = orf.epsComponents3D(x, x, z, 1, {{"polygon", p}}, Period=[0.6 0.6]);
            fill = (mean(e.z, 'all') - 1) / 3;
            tc.verifyEqual(fill, 0.4 * 0.3 / 2 / 0.36, 'RelTol', 3e-3);
        end

        function gdsRoundTripGrating(tc)
            f = fullfile(tc.Dir, "gc.gds");
            per = 0.62 * ones(1, 5); ff = [0.9 0.8 0.7 0.6 0.5];
            info = orf.gratingToGDS(f, per, ff, Width=12);
            lib = orf.gdsRead(f);
            tc.verifyEqual(lib.dbUnit, 1e-3, 'AbsTol', 1e-15);
            polys = orf.gdsFlatten(lib, Layer=2);
            tc.verifyNumElements(polys, 5);
            xs = cell2mat(cellfun(@(p) [min(p(:, 1)) max(p(:, 1))], polys(:), 'UniformOutput', false));
            tc.verifyEqual(sortrows(xs), sortrows(info.grooves), 'AbsTol', 1e-3);
        end

        function gdsRoundTripMetalensWithReferences(tc)
            f = fullfile(tc.Dir, "lens.gds");
            D = [0.1 0.2 0; 0.15 0.2 0.1];
            orf.metalensToGDS(f, D, 0.4, Vertices=64, DbUnit=1e-5);   % fine grid for the area check
            [polys, layers] = orf.gdsFlatten(orf.gdsRead(f));
            tc.verifyNumElements(polys, nnz(D));
            tc.verifyEqual(unique(layers), 1);
            area = sort(cellfun(@(p) polyarea(p(:, 1), p(:, 2)), polys));
            tc.verifyEqual(area, sort(pi * D(D > 0).'.^2 / 4), 'RelTol', 2e-3);
        end

        function referenceTransforms(tc)
            % GDSII order: reflect about x, magnify, rotate, translate
            tri = [0 0; 1 0; 0 2];
            lib.name = "T"; lib.dbUnit = 1e-3;
            refs = struct('cell', "A", 'xy', [10 0], 'angle', 90, 'mag', 2, 'reflect', true);
            noRef = struct('cell', {}, 'xy', {}, 'angle', {}, 'mag', {}, 'reflect', {});
            noArr = struct('cell', {}, 'cols', {}, 'rows', {}, 'xy', {}, 'angle', {}, 'mag', {}, 'reflect', {});
            arr = struct('cell', "A", 'cols', 2, 'rows', 1, 'xy', [0 0; 20 0; 0 5], 'angle', 0, 'mag', 1, 'reflect', false);
            lib.cells = struct('name', {"A", "TOP"}, 'polygons', {{tri}, {}}, 'layers', {1, []}, ...
                'datatypes', {0, []}, 'refs', {noRef, refs}, 'arefs', {noArr, arr});
            p = orf.gdsFlatten(lib);
            tc.verifyNumElements(p, 3);
            % (x, y) -> reflect (x, -y) -> x2 -> rotate 90: (2y, 2x) -> + (10, 0)
            tc.verifyEqual(p{1}, [10 0; 10 2; 14 0], 'AbsTol', 1e-12);
            tc.verifyEqual(p{3}, tri + [10 0], 'AbsTol', 1e-12);
        end

        function importedShapesSimulateLikeOriginals(tc)
            f = fullfile(tc.Dir, "cell.gds");
            sq = [-0.1 -0.05; 0.1 -0.05; 0.1 0.05; -0.1 0.05];
            orf.gdsWrite(f, struct('name', "CELL", 'polygons', {{sq + [0.03 0.02]}}, 'layers', 1));
            shapes = orf.gdsToShapes(orf.gdsFlatten(orf.gdsRead(f)), orf.materialConst(2));
            mk = @(s) orf.makeStructure([0.4 0.3], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.2, orf.materialConst(1), s)});
            a = orf.rcwa2D(mk({orf.shapeRect(0.2, 0.1, orf.materialConst(2), [0.03 0.02])}), 0.8, 0.1, 0.2, "s", ...
                Nx=3, Nsample=[400 300], Symmetry="none");
            b = orf.rcwa2D(mk(shapes), 0.8, 0.1, 0.2, "s", Nx=3, Nsample=[400 300], Symmetry="none");
            tc.verifyEqual(b.T, a.T, 'AbsTol', 1e-12);
        end
    end
end
