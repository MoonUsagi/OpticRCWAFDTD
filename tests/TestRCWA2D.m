classdef TestRCWA2D < matlab.unittest.TestCase
    %TESTRCWA2D Validate orf.rcwa2D (crossed gratings, batching, GPU).

    properties (Constant)
        Th = deg2rad(30)
        Ph = deg2rad(40)
    end

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Static)
        function devs = pillarSweep(Ds)
            % Si pillars on SiO2 (light from the substrate), period 0.4 um
            devs = arrayfun(@(D) orf.makeStructure([0.4 0.4], orf.materialConst(1.45), ...
                orf.materialConst(1), {orf.makeLayer(0.6, orf.materialConst(1), ...
                {orf.shapeCircle(D/2, orf.materialConst(3.48))})}), Ds, 'UniformOutput', false);
        end
    end

    methods (Test)
        function homogeneousConicalEqualsTMM(tc)
            dev = orf.makeStructure([0.5 0.4], orf.materialConst(1), orf.materialConst(3.48), ...
                {orf.makeLayer(0.2, orf.materialConst(1.45)), orf.makeLayer(0.11, orf.materialConst(2 + 0.1i))});
            for pol = ["s", "p"]
                o = orf.rcwa2D(dev, 1.3, tc.Th, tc.Ph, pol, Nx=3);
                t = orf.tmm(1.3, [1 1.45 2+0.1i 3.48], [0.2 0.11], tc.Th, pol);
                tc.verifyEqual([o.Rtot o.Ttot], [t.R t.T], 'AbsTol', 1e-12, pol);
            end
        end

        function yInvariantEqualsRcwa1D(tc)
            % A line (wy = Inf) in a finite-Ly lattice must reproduce the
            % 1D result, conical incidence included: checks the 2D Li rule
            % and the harmonic bookkeeping.
            air = orf.materialConst(1); si = orf.materialConst(3.48);
            g1 = orf.makeStructure([0.7 Inf], air, orf.materialConst(1.45), ...
                {orf.makeLayer(0.5, air, {orf.shapeRect(0.35, Inf, si)})});
            g2 = orf.makeStructure([0.7 0.5], air, orf.materialConst(1.45), ...
                {orf.makeLayer(0.5, air, {orf.shapeRect(0.35, Inf, si)})});
            a = orf.rcwa1D(g1, 1.0, tc.Th, tc.Ph, [1 1i], N=10, Nsample=256);
            b = orf.rcwa2D(g2, 1.0, tc.Th, tc.Ph, [1 1i], Nx=10, Ny=3, Nsample=[256 64]);
            tc.verifyEqual([b.Rtot b.Ttot], [a.Rtot a.Ttot], 'AbsTol', 1e-12);
        end

        function rotationSwapsPolarization(tc)
            % Rotating a rect by 90 deg maps TE (E_y) onto TM (E_x).
            sio2 = orf.materialConst(1.45); air = orf.materialConst(1); si = orf.materialConst(3.48);
            r1 = orf.makeStructure([0.5 0.5], sio2, air, {orf.makeLayer(0.6, air, {orf.shapeRect(0.3, 0.15, si)})});
            r2 = orf.makeStructure([0.5 0.5], sio2, air, {orf.makeLayer(0.6, air, {orf.shapeRect(0.15, 0.3, si)})});
            a = orf.rcwa2D(r1, 1.0, 0, 0, "s", Nx=6);
            b = orf.rcwa2D(r2, 1.0, 0, 0, "p", Nx=6);
            tc.verifyEqual(a.Ttot, b.Ttot, 'AbsTol', 1e-12);
            tc.verifyEqual(a.Rtot, b.Rtot, 'AbsTol', 1e-12);
        end

        function circleIsPolarizationIndependent(tc)
            devs = TestRCWA2D.pillarSweep(0.24);
            a = orf.rcwa2D(devs, 0.94, 0, 0, "s", Nx=6);
            b = orf.rcwa2D(devs, 0.94, 0, 0, "p", Nx=6);
            tc.verifyEqual(a.Ttot, b.Ttot, 'AbsTol', 1e-12);
            % co-polarised zero-order phase must match too
            tc.verifyEqual(abs(a.t(2, a.m == 0 & a.n == 0)), ...
                           abs(b.t(1, b.m == 0 & b.n == 0)), 'AbsTol', 1e-12);
        end

        function energyConservationConical(tc)
            c = orf.makeStructure([0.6 0.6], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.5, orf.materialConst(1), {orf.shapeCircle(0.18, orf.materialConst(3.48))})});
            o = orf.rcwa2D(c, 1.0, tc.Th, tc.Ph, [1 1i], Nx=6);
            tc.verifyEqual(o.Rtot + o.Ttot, 1, 'AbsTol', 1e-12);
        end

        function batchEqualsLoop(tc)
            Ds = [0.1 0.2 0.3];
            devs = TestRCWA2D.pillarSweep(Ds);
            ob = orf.rcwa2D(devs, 0.94, 0, 0, "s", Nx=4);
            for k = 1:numel(Ds)
                ol = orf.rcwa2D(devs{k}, 0.94, 0, 0, "s", Nx=4);
                tc.verifyEqual(ob.t(:, :, k), ol.t, 'AbsTol', 1e-12);
            end
        end

        function symmetryReductionMatchesFull(tc)
            % Mirror-symmetric pillars at normal incidence: the reduced
            % solve must reproduce every order of the full solve, s and p,
            % with a homogeneous layer in the stack as well.
            devs = arrayfun(@(D) orf.makeStructure([0.4 0.4], orf.materialConst(1.45), orf.materialConst(1), ...
                {orf.makeLayer(0.1, orf.materialConst(2.0)), ...
                 orf.makeLayer(0.6, orf.materialConst(1), {orf.shapeCircle(D/2, orf.materialConst(3.48))})}), ...
                [0.15 0.3], 'UniformOutput', false);
            for pol = ["s", "p"]
                a = orf.rcwa2D(devs, 0.94, 0, 0, pol, Nx=5);
                b = orf.rcwa2D(devs, 0.94, 0, 0, pol, Nx=5, Symmetry="none");
                tc.verifyEqual(a.t, b.t, 'AbsTol', 1e-11, pol);
                tc.verifyEqual(a.r, b.r, 'AbsTol', 1e-11, pol);
                tc.verifyEqual(a.T, b.T, 'AbsTol', 1e-11, pol);
            end
        end

        function asymmetricFallsBackToFull(tc)
            % Off-centre pillar or oblique incidence: no reduction, same answer.
            dev = orf.makeStructure([0.5 0.5], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.4, orf.materialConst(1), {orf.shapeCircle(0.1, orf.materialConst(2.5), [0.07 0])})});
            a = orf.rcwa2D(dev, 1.0, 0, 0, "p", Nx=4);
            b = orf.rcwa2D(dev, 1.0, 0, 0, "p", Nx=4, Symmetry="none");
            tc.verifyEqual(a.t, b.t, 'AbsTol', 1e-12);
            tc.verifyEqual(a.Rtot + a.Ttot, 1, 'AbsTol', 1e-12);
        end

        function chunkedBatchEqualsSingleBatch(tc)
            devs = TestRCWA2D.pillarSweep([0.1 0.15 0.2 0.25 0.3]);
            a = orf.rcwa2D(devs, 0.94, 0, 0, "s", Nx=3);
            b = orf.rcwa2D(devs, 0.94, 0, 0, "s", Nx=3, BatchSize=2);   % chunks 2+2+1
            tc.verifyEqual(b.t, a.t, 'AbsTol', 1e-12);
            tc.verifyEqual(b.T, a.T, 'AbsTol', 1e-12);
            tc.verifyEqual(b.Ttot, a.Ttot, 'AbsTol', 1e-12);
        end

        function gpuMatchesCpu(tc)
            tc.assumeGreaterThan(gpuDeviceCount, 0, 'No GPU available.');
            devs = TestRCWA2D.pillarSweep([0.15 0.25]);
            oc = orf.rcwa2D(devs, 0.94, 0, 0, "s", Nx=3);
            og = orf.rcwa2D(devs, 0.94, 0, 0, "s", Nx=3, UseGPU=true);
            tc.verifyEqual(og.t, oc.t, 'AbsTol', 1e-10);
        end
    end
end
