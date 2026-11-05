classdef (TestTags = {'Slow'}) TestFDTD3D < matlab.unittest.TestCase
    %TESTFDTD3D Validate fdtd3D: TMM, RCWA cross-check, guided-mode dispersion.
    %   Small grids so the suite runs on a laptop CPU (~1-2 min in total).

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Static)
        function sim = planeWaveSim(x, y, z, d, lam, lambda0, bw, zSrc, zR, zT)
            % x-polarised plane wave toward +z in air, periodic x and y.
            izOf = @(zz) round((zz - z(1)) / d) + 1;
            Na = numel(x); Nb = numel(y);
            src = struct('axis', 3, 'index', izOf(zSrc), 'Ea', ones(Na, Nb), ...
                'Eb', zeros(Na, Nb), 'Ha', zeros(Na, Nb), 'Hb', ones(Na, Nb), ...
                'neff', 1, 'lambda0', lambda0, 'bw', bw);
            sim = struct('x', x, 'y', y, 'z', z, 'npml', [0 0 round(0.3/d)], ...
                'periodic', [true true false], 'source', src, 'lambdas', lam, ...
                'monitors', struct('axis', {3, 3}, 'index', {izOf(zR), izOf(zT)}));
        end

        function [o, m, sim, msEps] = stripRun(extra)
            % 500 x 220 nm SOI strip along x (d = 40 nm), TE0 mode source.
            if nargin < 1, extra = struct(); end
            d = 0.04; x = (0:d:2.6).'; y = ((-30:29).' + 0.5) * d; z = ((-25:24).' + 0.5) * d;
            e = orf.epsComponents3D(x, y, z, 1.444, {{"box", [-Inf Inf -0.25 0.25 -0.11 0.11 3.476]}});
            pl = @(A) squeeze(A(1, :, :));
            % mode-solver plane (a, b) = (y, z): its E_x, E_y, E_z are the 3D E_y, E_z, E_x
            msEps = struct('x', pl(e.y), 'y', pl(e.z), 'z', pl(e.x));
            m = orf.wgModes2D(y, z, 1.444, zeros(0, 5), 1.55, 2, Eps=msEps);
            [~, iTE] = max(m.teFraction);
            f = @(F) real(F(:, :, iTE));
            m.prof = struct('Ea', f(m.Ex), 'Eb', f(m.Ey), 'Ha', f(m.Hx), 'Hb', f(m.Hy));
            m.neffTE = m.neff(iTE);
            ixOf = @(xx) round(xx / d) + 1;
            src = struct('axis', 1, 'index', ixOf(0.6), 'Ea', m.prof.Ea, 'Eb', m.prof.Eb, ...
                'Ha', m.prof.Ha, 'Hb', m.prof.Hb, 'neff', m.neffTE, 'lambda0', 1.55, 'bw', 0.1);
            sim = struct('x', x, 'y', y, 'z', z, 'eps', e, 'npml', [8 8 8], 'source', src, ...
                'lambdas', 1.55, 'monitors', struct('axis', {1, 1, 1}, ...
                'index', {ixOf(0.4), ixOf(0.9), ixOf(2.0)}));
            for fn = string(fieldnames(extra)).', sim.(fn) = extra.(fn); end
            o = orf.fdtd3D(sim);
        end
    end

    methods (Test)
        function slabMatchesTMM(tc)
            d = 0.01; x = (0:1).' * d; y = x; z = (0:d:6).'; lam = linspace(1.2, 1.8, 7);
            sim = TestFDTD3D.planeWaveSim(x, y, z, d, lam, 1.5, 0.3, 1, 0.6, 5);
            sim.eps = orf.epsComponents3D(x, y, z, 1, {});
            o0 = orf.fdtd3D(sim);
            sim.eps = orf.epsComponents3D(x, y, z, 1, {{"box", [-Inf Inf -Inf Inf 3 3.5 2]}});
            o1 = orf.fdtd3D(sim);
            R = -o1.flux(1, :) ./ o0.flux(2, :); T = o1.flux(2, :) ./ o0.flux(2, :);
            tm = arrayfun(@(l) orf.tmm(l, [1 2 1], 0.5, 0, "s"), lam);
            tc.verifyEqual(R, [tm.R], 'AbsTol', 2e-3);
            tc.verifyEqual(R + T, ones(size(R)), 'AbsTol', 2e-5);
            tc.verifyLessThan(max(abs(o0.flux(1, :) ./ o0.flux(2, :))), 1e-8);   % no spurious reflection
        end

        function pillarArrayMatchesRCWA(tc)
            % 3D RCWA <-> FDTD cross-check: square pillars, period 0.6 um.
            P = 0.6; d = 0.02; x = ((0:29).' + 0.5) * d - P/2; y = x; z = (0:d:3.6).';
            lam = [1.0 1.3 1.6];
            sim = TestFDTD3D.planeWaveSim(x, y, z, d, lam, 1.25, 0.15, 0.8, 0.5, 3.0);
            sim.shutoff = 1e-8;
            sim.eps = orf.epsComponents3D(x, y, z, 1, {}, Period=[P P]);
            o0 = orf.fdtd3D(sim);
            sim.eps = orf.epsComponents3D(x, y, z, 1, {{"box", [-0.15 0.15 -0.15 0.15 1.5 1.8 2]}}, Period=[P P]);
            o1 = orf.fdtd3D(sim);
            R = -o1.flux(1, :) ./ o0.flux(2, :); T = o1.flux(2, :) ./ o0.flux(2, :);
            dev = orf.makeStructure([P P], orf.materialConst(1), orf.materialConst(1), ...
                {orf.makeLayer(0.3, orf.materialConst(1), {orf.shapeRect(0.3, 0.3, orf.materialConst(2))})});
            Rr = arrayfun(@(l) orf.rcwa2D(dev, l, 0, 0, "p", Nx=8).Rtot, lam);
            tc.verifyEqual(R, Rr, 'AbsTol', 1e-3);
            tc.verifyEqual(R + T, ones(size(R)), 'AbsTol', 2e-5);
        end

        function cylinderArrayAveragingVsRCWA(tc)
            % Curved surfaces: circular pillars (r 0.17, n 2.5) vs converged
            % rcwa2D. Directional averaging must beat the staircase by > 2x.
            P = 0.6; r = 0.17; h = 0.3; ng = 2.5; lam = [1.0 1.3 1.6]; d = 0.03;
            dev = orf.makeStructure([P P], orf.materialConst(1), orf.materialConst(1), ...
                {orf.makeLayer(h, orf.materialConst(1), {orf.shapeCircle(r, orf.materialConst(ng))})});
            Rr = arrayfun(@(l) orf.rcwa2D(dev, l, 0, 0, "p", Nx=14).Rtot, lam);
            nc = round(P / d); x = ((0:nc-1).' + 0.5) * d - P/2; y = x; z = (0:d:3.6).';
            sim = TestFDTD3D.planeWaveSim(x, y, z, d, lam, 1.25, 0.15, 0.8, 0.5, 3.0);
            sim.shutoff = 1e-8;
            sim.eps = orf.epsComponents3D(x, y, z, 1, {}, Period=[P P]);
            o0 = orf.fdtd3D(sim);
            cyl = {{"cyl", [0 0 r 1.5 1.5+h ng]}};
            sim.eps = orf.epsComponents3D(x, y, z, 1, cyl, Period=[P P]);
            Ravg = -orf.fdtd3D(sim).flux(1, :) ./ o0.flux(2, :);
            sim.eps = orf.epsComponents3D(x, y, z, 1, cyl, Period=[P P], NSub=1);
            Rst = -orf.fdtd3D(sim).flux(1, :) ./ o0.flux(2, :);
            tc.verifyEqual(Ravg, Rr, 'AbsTol', 2e-3);
            tc.verifyLessThan(max(abs(Ravg - Rr)), max(abs(Rst - Rr)) / 2);
        end

        function stripModeSourceAndDispersion(tc)
            [o, m, sim, msEps] = TestFDTD3D.stripRun();
            tc.verifyLessThan(-o.flux(1) / o.flux(2), 1e-4);            % unidirectional
            tc.verifyEqual(o.flux(3) / o.flux(2), 1, 'AbsTol', 1e-3);   % lossless guide
            % exact Yee dispersion: mode at the numerical k0, undo the x stencil
            d = sim.x(2) - sim.x(1); S = 0.99 / sqrt(3) * d;
            k0 = 2*pi / 1.55; k0n = 2 / S * sin(k0 * S / 2);
            mt = orf.wgModes2D(sim.y, sim.z, 1.444, zeros(0, 5), 2*pi / k0n, 2, Eps=msEps);
            [~, it] = max(mt.teFraction);
            nPred = 2 / d * asin(mt.neff(it) * k0n * d / 2) / k0;
            ov = @(q) sum(m.prof.Ea .* o.mon(q).Ea, 'all') + sum(m.prof.Eb .* o.mon(q).Eb, 'all');
            L = (sim.monitors(3).index - sim.monitors(2).index) * d;
            ph = angle(ov(3)) - angle(ov(2));
            q = round((nPred * k0 * L - ph) / (2*pi));
            tc.verifyEqual((ph + 2*pi*q) / (k0 * L), nPred, 'AbsTol', 1e-4);
        end

        function singlePrecisionAndGPU(tc)
            [o1, ~] = TestFDTD3D.stripRun();
            [o2, ~] = TestFDTD3D.stripRun(struct('precision', "single"));
            tc.verifyEqual(o2.flux ./ o2.flux(2), o1.flux ./ o1.flux(2), 'AbsTol', 1e-4);
            if gpuDeviceCount > 0
                [o3, ~] = TestFDTD3D.stripRun(struct('useGPU', true, 'precision', "single"));
                tc.verifyEqual(o3.flux ./ o3.flux(2), o1.flux ./ o1.flux(2), 'AbsTol', 1e-4);
            end
        end
    end
end
