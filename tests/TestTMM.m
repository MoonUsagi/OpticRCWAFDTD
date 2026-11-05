classdef TestTMM < matlab.unittest.TestCase
    %TESTTMM Validate tmm against closed-form thin-film results.

    properties (Constant)
        Tol = 1e-12
    end

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function singleInterfaceFresnel(tc)
            n1 = 1.0; n2 = 1.5;
            th1 = deg2rad(0:5:85);
            th2 = asin(n1 * sin(th1) / n2);
            rsRef = (n1*cos(th1) - n2*cos(th2)) ./ (n1*cos(th1) + n2*cos(th2));
            rpRef = (n2*cos(th1) - n1*cos(th2)) ./ (n2*cos(th1) + n1*cos(th2)); % H_y ratio
            s = orf.tmm(0.633, [n1 n2], [], th1, "s");
            p = orf.tmm(0.633, [n1 n2], [], th1, "p");
            tc.verifyEqual(s.r, rsRef, 'AbsTol', tc.Tol);
            tc.verifyEqual(p.r, rpRef, 'AbsTol', tc.Tol);
            tc.verifyEqual(s.R + s.T, ones(size(th1)), 'AbsTol', tc.Tol);
            tc.verifyEqual(p.R + p.T, ones(size(th1)), 'AbsTol', tc.Tol);
        end

        function brewsterAngle(tc)
            n2 = 1.5;
            p = orf.tmm(0.633, [1 n2], [], atan(n2), "p");
            tc.verifyLessThan(p.R, 1e-28);
        end

        function normalIncidenceSEqualsP(tc)
            n = [1, 2.0, 1.45, 3.5];
            lam = linspace(0.4, 1.6, 50).';
            s = orf.tmm(lam, n, [0.1 0.25], 0, "s");
            p = orf.tmm(lam, n, [0.1 0.25], 0, "p");
            tc.verifyEqual(s.R, p.R, 'AbsTol', tc.Tol);
            tc.verifyEqual(s.T, p.T, 'AbsTol', tc.Tol);
        end

        function energyConservationLossless(tc)
            rng(1);
            n = [1.0, 1 + 2*rand(1, 8), 1.52];
            d = 0.05 + 0.3*rand(1, 8);
            lam = linspace(0.4, 1.6, 101).';
            th = deg2rad(0:10:80);
            for pol = ["s", "p"]
                o = orf.tmm(lam, n, d, th, pol);
                tc.verifyEqual(o.R + o.T, ones(size(o.R)), 'AbsTol', 1e-10, ...
                    "pol " + pol);
            end
        end

        function quarterWaveAntireflection(tc)
            lam = 0.55; n0 = 1.0; ns = 1.52; nc = sqrt(n0 * ns);
            o = orf.tmm(lam, [n0 nc ns], lam / (4*nc), 0, "s");
            tc.verifyLessThan(o.R, 1e-28);
        end

        function halfWaveAbsentee(tc)
            lam = 1.31; nL = 2.1;
            bare = orf.tmm(lam, [1 3.48], [], 0, "s");
            coated = orf.tmm(lam, [1 nL 3.48], lam / (2*nL), 0, "s");
            tc.verifyEqual(coated.R, bare.R, 'AbsTol', tc.Tol);
        end

        function airySlabWithLoss(tc)
            % Free-standing slab, normal incidence, complex index (k > 0).
            lam = linspace(0.5, 1.5, 41).';
            n = 3.5 + 0.05i; d = 0.4;
            delta = 2*pi ./ lam * n * d;
            r12 = (1 - n) / (1 + n);
            rRef = r12 * (1 - exp(2i*delta)) ./ (1 - r12^2 * exp(2i*delta));
            o = orf.tmm(lam, [1 n 1], d, 0, "s");
            tc.verifyEqual(o.r, rRef, 'AbsTol', tc.Tol);
            tc.verifyGreaterThan(o.A, 0);   % e^{-iwt}: Im(n) > 0 must absorb
        end

        function braggMirrorPeak(tc)
            lam = 1.55; nH = 3.48; nL = 1.45; n0 = 1; ns = 1.45; N = 6;
            n = [n0, repmat([nH nL], 1, N), ns];
            d = repmat(lam ./ (4*[nH nL]), 1, N);
            o = orf.tmm(lam, n, d, 0, "s");
            x = n0 * nL^(2*N); y = ns * nH^(2*N);
            tc.verifyEqual(o.R, ((x - y) / (x + y))^2, 'AbsTol', 1e-12);
        end

        function totalInternalReflection(tc)
            th = deg2rad([45 60 80]);       % critical angle ~41.8 deg
            for pol = ["s", "p"]
                o = orf.tmm(0.633, [1.5 1.0], [], th, pol);
                tc.verifyEqual(o.R, ones(size(th)), 'AbsTol', tc.Tol);
                tc.verifyEqual(o.T, zeros(size(th)), 'AbsTol', tc.Tol);
            end
        end

        function dispersiveInputShape(tc)
            lam = linspace(0.5, 0.9, 7).';
            nl = 1.45 + 0.01 ./ lam.^2;      % Cauchy-like column
            n = [ones(7,1), nl, 1.52*ones(7,1)];
            o = orf.tmm(lam, n, 0.2, deg2rad([0 30]), "p");
            tc.verifySize(o.R, [7 2]);
        end
    end
end
