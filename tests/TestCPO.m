classdef TestCPO < matlab.unittest.TestCase
    %TESTCPO Grating-coupler power budget and the fiber-overlap integral.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function fiberOverlapOfItselfIsOne(tc)
            % A field equal to the tilted Gaussian must overlap perfectly,
            % and eta must then equal Pup.
            x = (0:0.02:20).'; th = deg2rad(8); w0 = 5.2; lam = 1.55;
            u = x - 10;
            E = exp(-(u * cos(th) / w0).^2) .* exp(1i * 2*pi/lam * sin(th) * u);
            res = struct('xUp', x, 'EyUp', 3 * E, 'lambdas', lam, 'nClad', 1, 'Pup', 0.6);
            [eta, ov] = orf.fiberCoupling(res, th, 10, w0);
            tc.verifyEqual(ov, 1, 'AbsTol', 1e-12);
            tc.verifyEqual(eta, 0.6, 'AbsTol', 1e-12);
            % wrong tilt sign must reduce the overlap
            tc.verifyLessThan(orf.fiberCoupling(res, -th, 10, w0) / 0.6, 0.5);
        end

        function shortGratingPowerBalance(tc)
            % Closed monitor box: R + Pup + Pdown + Ptrans = 1.
            p = struct('nPer', 6, 'lambdas', [1.53 1.55 1.57]);
            r = orf.gratingCouplerTE(p);
            tc.verifyEqual(r.neffIn, 2.835, 'AbsTol', 0.01);      % TE0, not a substrate mode
            tc.verifyLessThan(max(abs(r.balance)), 1e-3);
            tc.verifyGreaterThan(min(r.Pup), 0);
            tc.verifyGreaterThan(min(r.Pdown), 0);
        end
    end
end
