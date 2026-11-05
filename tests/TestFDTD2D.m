classdef TestFDTD2D < matlab.unittest.TestCase
    %TESTFDTD2D Validate fdtd2DTE: TMM, CPML, TF/SF and guided-mode dispersion.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Static)
        function [R, T, Rempty] = slabRun(dx, extra)
            % Plane wave (periodic z) on a 0.5 um n = 2 slab in air.
            % extra: optional struct of sim fields (e.g. useGPU, precision).
            if nargin < 2, extra = struct(); end
            x = (0:dx:6).'; z = (0:3).' * dx;
            lam = linspace(1.2, 1.8, 7);
            ixOf = @(xx) round(xx / dx) + 1;
            s = struct('x', x, 'z', z, 'npml', [round(0.2/dx) 0], 'periodicZ', true, ...
                'lambdas', lam, 'monitors', [ixOf(0.6) ixOf(5)]);
            s.source = struct('ix', ixOf(1), 'profile', ones(numel(z), 1), ...
                'neff', 1, 'lambda0', 1.5, 'bw', 0.3);
            for fn = string(fieldnames(extra)).'
                s.(fn) = extra.(fn);
            end
            s.eps = ones(numel(x), numel(z));
            o0 = orf.fdtd2DTE(s);
            s.eps = orf.epsFromBoxes(x, z, 1, [3.0 3.5 -Inf Inf 2.0]);
            o1 = orf.fdtd2DTE(s);
            R = -o1.flux(1, :) ./ o0.flux(2, :);
            T = o1.flux(2, :) ./ o0.flux(2, :);
            Rempty = abs(o0.flux(1, :) ./ o0.flux(2, :));
        end

        function tm = slabTMM()
            tm = arrayfun(@(l) orf.tmm(l, [1 2 1], 0.5, 0, "s"), linspace(1.2, 1.8, 7));
        end

        function [o, m, sim] = waveguideRun()
            % Si slab (0.22 um) in SiO2 along x, TE0 mode source.
            dx = 0.02; x = (0:dx:8).'; z = (-1.5:dx:1.5).' + dx/2;
            epsw = orf.epsFromBoxes(x, z, 1.444, [-Inf Inf -0.11 0.11 3.476]);
            m = orf.slabModes(z, sqrt(epsw(1, :)).', 1.55, "TE");
            sim = struct('x', x, 'z', z, 'eps', epsw, 'npml', [15 15], ...
                'lambdas', linspace(1.5, 1.6, 5), 'monitors', [51 151 301]);
            sim.source = struct('ix', 101, 'profile', m.field, 'neff', m.neff, ...
                'lambda0', 1.55, 'bw', 0.1);
            o = orf.fdtd2DTE(sim);
        end
    end

    methods (Test)
        function slabMatchesTMM(tc)
            [R, T] = TestFDTD2D.slabRun(0.01);
            tm = TestFDTD2D.slabTMM();
            tc.verifyEqual(R, [tm.R], 'AbsTol', 3e-3);
            tc.verifyEqual(T, [tm.T], 'AbsTol', 3e-3);
            tc.verifyEqual(R + T, ones(size(R)), 'AbsTol', 2e-5);   % lossless
        end

        function slabErrorIsSecondOrder(tc)
            tm = TestFDTD2D.slabTMM();
            [R1, ~] = TestFDTD2D.slabRun(0.01);
            [R2, ~] = TestFDTD2D.slabRun(0.005);
            ratio = max(abs(R1 - [tm.R])) / max(abs(R2 - [tm.R]));
            tc.verifyGreaterThan(ratio, 3);
        end

        function singlePrecisionMatchesDouble(tc)
            % Single-precision update with double DFT accumulation (CPU).
            [R1, T1] = TestFDTD2D.slabRun(0.01);
            [R2, T2] = TestFDTD2D.slabRun(0.01, struct('precision', "single"));
            tc.verifyEqual(R2, R1, 'AbsTol', 1e-4);
            tc.verifyEqual(T2, T1, 'AbsTol', 1e-4);
        end

        function gpuMatchesCpu(tc)
            tc.assumeGreaterThan(gpuDeviceCount, 0, 'No GPU available.');
            [R1, T1] = TestFDTD2D.slabRun(0.01);
            [R2, T2] = TestFDTD2D.slabRun(0.01, struct('useGPU', true));
            tc.verifyEqual(R2, R1, 'AbsTol', 1e-10);
            tc.verifyEqual(T2, T1, 'AbsTol', 1e-10);
            [R3, ~] = TestFDTD2D.slabRun(0.01, struct('useGPU', true, 'precision', "single"));
            tc.verifyEqual(R3, R1, 'AbsTol', 1e-4);
        end

        function directionalEpsAveraging(tc)
            % Vertical edge through the middle of the cell at x = 1.0:
            % tangential components see the arithmetic mean (2.5), the
            % normal E_x the harmonic mean 2/(1/4 + 1) = 1.6.
            x = (0:0.1:2).'; z = (0:0.1:1).';
            e = orf.epsComponents2D(x, z, 1, [1.0 Inf -Inf Inf 2]);
            i = find(abs(x - 1.0) < 1e-12);
            tc.verifyEqual(e.y(i, 5), 2.5, 'AbsTol', 1e-12);
            tc.verifyEqual(e.x(i, 5), 1.6, 'AbsTol', 1e-12);
            tc.verifyEqual(e.z(i, 5), 4, 'AbsTol', 1e-12);      % x_i+1/2 lies inside
            tc.verifyEqual(e.z(i-1, 5), 1, 'AbsTol', 1e-12);    % x_i-1/2 lies outside
        end

        function tmSlabMatchesTMM(tc)
            dx = 0.01; x = (0:dx:6).'; z = (0:3).' * dx; lam = linspace(1.2, 1.8, 7);
            ixOf = @(xx) round(xx / dx) + 1;
            s = struct('pol', "TM", 'x', x, 'z', z, 'npml', [20 0], 'periodicZ', true, ...
                'lambdas', lam, 'monitors', [ixOf(0.6) ixOf(5)]);
            s.source = struct('ix', ixOf(1), 'profile', ones(4, 1), 'neff', 1, 'lambda0', 1.5, 'bw', 0.3);
            e0 = orf.epsComponents2D(x, z, 1, zeros(0, 5), PeriodicZ=true);
            s.epsX = e0.x; s.epsZ = e0.z; o0 = orf.fdtd2D(s);
            e1 = orf.epsComponents2D(x, z, 1, [3 3.5 -Inf Inf 2], PeriodicZ=true);
            s.epsX = e1.x; s.epsZ = e1.z; o1 = orf.fdtd2D(s);
            R = -o1.flux(1, :) ./ o0.flux(2, :); T = o1.flux(2, :) ./ o0.flux(2, :);
            tm = arrayfun(@(l) orf.tmm(l, [1 2 1], 0.5, 0, "p"), lam);
            tc.verifyEqual(R, [tm.R], 'AbsTol', 2e-3);
            tc.verifyEqual(R + T, ones(size(R)), 'AbsTol', 2e-5);
        end

        function tmGuidedModeMatchesDiscreteDispersion(tc)
            % TM0 of the Si slab: unidirectional source and exact Yee dispersion
            % (slab solver fed the FDTD's own eps_x and eps_z).
            dx = 0.02; x = (0:dx:8).'; z = (-1.5:dx:1.5).' + dx/2;
            e = orf.epsComponents2D(x, z, 1.444, [-Inf Inf -0.11 0.11 3.476]);
            m = orf.slabModes(z, sqrt(e.z(1, :)).', 1.55, "TM", EpsHalf=e.x(1, :).');
            sim = struct('pol', "TM", 'x', x, 'z', z, 'epsX', e.x, 'epsZ', e.z, ...
                'npml', [15 15], 'lambdas', 1.55, 'monitors', [51 151 301]);
            sim.source = struct('ix', 101, 'profile', m.field, 'neff', m.neff, 'lambda0', 1.55, 'bw', 0.1);
            o = orf.fdtd2D(sim);
            tc.verifyLessThan(-o.flux(1) / o.flux(2), 1e-6);
            tc.verifyEqual(o.flux(3) / o.flux(2), 1, 'AbsTol', 1e-5);
            S = 0.99 / sqrt(2) * dx; k0 = 2*pi / 1.55; k0n = 2 / S * sin(k0 * S / 2);
            mt = orf.slabModes(z, sqrt(e.z(1, :)).', 2*pi / k0n, "TM", EpsHalf=e.x(1, :).');
            nPred = 2 / dx * asin(mt.neff * k0n * dx / 2) / k0;
            L = 3;
            ph = angle(m.field.' * o.Hy(:, 1, 3)) - angle(m.field.' * o.Hy(:, 1, 2));
            q = round((nPred * k0 * L - ph) / (2*pi));
            tc.verifyEqual((ph + 2*pi*q) / (k0 * L), nPred, 'AbsTol', 2e-5);
        end

        function emptyDomainHasNoReflection(tc)
            % CPML + TF/SF leakage seen by the scattered-field monitor.
            [~, ~, Rempty] = TestFDTD2D.slabRun(0.01);
            tc.verifyLessThan(max(Rempty), 1e-8);
        end

        function modeSourceIsUnidirectionalAndLossless(tc)
            o = TestFDTD2D.waveguideRun();
            back = -o.flux(1, :) ./ o.flux(2, :);
            tc.verifyLessThan(max(abs(back)), 1e-4);
            tc.verifyEqual(o.flux(3, :) ./ o.flux(2, :), ones(1, 5), 'AbsTol', 1e-4);
        end

        function guidedModeMatchesDiscreteDispersion(tc)
            % Exact Yee prediction: solve the slab mode at the numerical k0
            % (time discretisation), then undo the x-difference stencil.
            [o, m, sim] = TestFDTD2D.waveguideRun();
            dx = sim.x(2) - sim.x(1); S = 0.99 / sqrt(2) * dx;
            k0 = 2*pi / 1.55;
            k0num = 2 / S * sin(k0 * S / 2);
            mt = orf.slabModes(sim.z, sqrt(sim.eps(1, :)).', 2*pi / k0num, "TE");
            betaT = mt.neff * k0num;                 % (2/dx) sin(beta dx/2)
            nPred = 2 / dx * asin(betaT * dx / 2) / k0;
            % FDTD neff from the modal phase between monitors 2 and 3
            L = (sim.monitors(3) - sim.monitors(2)) * dx;
            ph = angle(m.field.' * o.Ey(:, 3, 3)) - angle(m.field.' * o.Ey(:, 3, 2));
            q = round((nPred * k0 * L - ph) / (2*pi));
            nFDTD = (ph + 2*pi*q) / (k0 * L);
            tc.verifyEqual(nFDTD, nPred, 'AbsTol', 2e-5);
        end
    end
end
