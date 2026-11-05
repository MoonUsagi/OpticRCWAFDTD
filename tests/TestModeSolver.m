classdef TestModeSolver < matlab.unittest.TestCase
    %TESTMODESOLVER slabModes against the analytic symmetric-slab dispersion.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Static)
        function neff = analyticEven(n1, n2, d, lambda0, pol)
            % Fundamental even mode of a symmetric slab (core n1, width d).
            k0 = 2*pi / lambda0;
            % TE: kappa tan(kappa d/2) = gamma; TM: (kappa/n1^2) tan = gamma/n2^2
            if pol == "TE", r = 1; else, r = n2^2 / n1^2; end
            g = @(ne) r * sqrt(n1^2 - ne^2) .* tan(k0*d/2 * sqrt(n1^2 - ne^2)) ...
                      - sqrt(ne^2 - n2^2);
            % fundamental: kappa*d/2 in (0, pi/2)
            neMin = sqrt(max(n2^2, n1^2 - (pi/(k0*d))^2)) + 1e-9;
            neff = fzero(g, [neMin, n1 - 1e-9]);
        end
    end

    methods (Test)
        function soiSlabTE(tc)
            z = (-2:0.002:2).' + 0.001;        % interfaces mid-cell: core = 110 cells
            n = 1.444 * ones(size(z)); n(abs(z) < 0.11) = 3.476;
            m = orf.slabModes(z, n, 1.55, "TE");
            ref = TestModeSolver.analyticEven(3.476, 1.444, 0.22, 1.55, "TE");
            tc.verifyEqual(m.neff, ref, 'AbsTol', 2e-3);
        end

        function soiSlabTM(tc)
            z = (-2:0.002:2).' + 0.001;        % interfaces mid-cell: core = 110 cells
            n = 1.444 * ones(size(z)); n(abs(z) < 0.11) = 3.476;
            m = orf.slabModes(z, n, 1.55, "TM");
            ref = TestModeSolver.analyticEven(3.476, 1.444, 0.22, 1.55, "TM");
            tc.verifyEqual(m.neff, ref, 'AbsTol', 2e-3);
        end

        function secondOrderConvergence(tc)
            % Halving dz should cut the TE error by about 4.
            ref = TestModeSolver.analyticEven(2.0, 1.45, 0.6, 1.0, "TE");
            err = zeros(1, 2);
            for k = 1:2
                dz = 0.01 / 2^(k-1);
                z = (-3:dz:3).' + dz/2;            % interfaces mid-cell
                n = 1.45 * ones(size(z)); n(abs(z) < 0.3) = 2.0;
                err(k) = abs(orf.slabModes(z, n, 1.0, "TE").neff - ref);
            end
            tc.verifyGreaterThan(err(1) / err(2), 3);
        end


        function secondOrderConvergenceTM(tc)
            ref = TestModeSolver.analyticEven(2.0, 1.45, 0.6, 1.0, "TM");
            err = zeros(1, 2);
            for k = 1:2
                dz = 0.01 / 2^(k-1);
                z = (-3:dz:3).' + dz/2;            % interfaces on half points
                n = 1.45 * ones(size(z)); n(abs(z) < 0.3) = 2.0;
                err(k) = abs(orf.slabModes(z, n, 1.0, "TM").neff - ref);
            end
            tc.verifyGreaterThan(err(1) / err(2), 3);
        end
        function profileNormalisedAndEven(tc)
            z = (-2:0.01:2).';
            n = 1.45 * ones(size(z)); n(abs(z) < 0.3) = 2.0;
            m = orf.slabModes(z, n, 1.0, "TE", 2);
            tc.verifyEqual(max(abs(m.field(:, 1))), 1, 'AbsTol', 1e-12);
            tc.verifyEqual(m.field(:, 1), flipud(m.field(:, 1)), 'AbsTol', 1e-8);
            tc.verifyGreaterThan(m.neff(1), m.neff(2));
        end
    end
end
