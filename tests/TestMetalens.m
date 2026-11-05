classdef TestMetalens < matlab.unittest.TestCase
    %TESTMETALENS Propagation, ideal-lens focusing and library layout.

    methods (TestClassSetup)
        function addPaths(~)
            root = fileparts(fileparts(mfilename('fullpath')));
            run(fullfile(root, 'setupPaths.m'));
        end
    end

    methods (Test)
        function gaussianBeamWaist(tc)
            % w(z) = w0 sqrt(1 + (z/zR)^2) for a Gaussian with w0 = 4 lambda.
            lam = 1; w0 = 4; dx = 0.25; L = 80;
            x = (-L/2:dx:L/2-dx);
            [X, Y] = meshgrid(x);
            U0 = exp(-(X.^2 + Y.^2) / w0^2);
            zR = pi * w0^2 / lam;
            z = 2 * zR;
            U = orf.angularSpectrum(U0, dx, lam, z);
            I = abs(U).^2;
            w = 2 * sqrt(sum(I(:) .* X(:).^2) / sum(I(:)));   % 1/e^2 radius
            % exact propagation vs the paraxial formula: ~(lam/(pi w0))^2 apart
            tc.verifyEqual(w, w0 * sqrt(1 + (z/zR)^2), 'RelTol', 1e-2);
            tc.verifyEqual(sum(I(:)), sum(abs(U0(:)).^2), 'RelTol', 1e-9);   % power
        end

        function forwardPhaseConvention(tc)
            % A plane wave with kx gains phase exp(i kz z), kz = sqrt(k^2-kx^2).
            lam = 1; dx = 0.1; N = 64; kx = 2*pi * 4 / (N * dx);    % on-grid kx
            x = (0:N-1) * dx;
            U0 = repmat(exp(1i * kx * x), N, 1);
            U = orf.angularSpectrum(U0, dx, lam, 3, Pad=1);
            kz = sqrt((2*pi/lam)^2 - kx^2);
            tc.verifyEqual(U, U0 * exp(1i * kz * 3), 'AbsTol', 1e-10);
        end

        function idealLensFocuses(tc)
            % Pure phase lens, D = 30 um, f = 30 um, lambda = 0.94 um.
            lam = 0.94; f = 30; R = 15; dx = 0.1;
            x = -R:dx:R;
            [X, Y] = meshgrid(x);
            ap = X.^2 + Y.^2 <= R^2;
            U0 = ap .* exp(1i * orf.targetPhaseHyperbolic(X, Y, f, lam));
            U = orf.angularSpectrum(U0, dx, lam, f);
            NA = sin(atan(R / f));
            mt = orf.focusMetrics(U, dx, lam, NA, sum(ap(:)) * dx^2);
            tc.verifyEqual(mt.fwhm, 1.03 * mt.fwhmLimit, 'RelTol', 0.1);   % Airy FWHM ~ 1.03 lambda/(2NA)
            tc.verifyGreaterThan(mt.efficiency, 0.8);
            % focus on axis at the array centre
            [~, k] = max(abs(U(:)));
            [iy, ix] = ind2sub(size(U), k);
            tc.verifyEqual([x(ix) x(iy)], [0 0], 'AbsTol', dx);
        end

        function layoutPicksNearestPhase(tc)
            ph = linspace(0, 2*pi, 13); ph(end) = [];
            lib.t = exp(1i * ph); lib.T = ones(size(ph));
            lib.t(4) = 0.1 * lib.t(4); lib.T(4) = 0.01;      % a resonant cell
            target = ph([2 4 7]) + 0.05;
            idx = orf.layoutFromLibrary(lib, target, NOffsets=1);
            tc.verifyEqual(idx([1 3]), [2 7]);
            tc.verifyNotEqual(idx(2), 4);                     % low-T cell avoided
        end
    end
end
