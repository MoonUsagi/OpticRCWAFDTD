classdef (TestTags = {'Slow'}) TestCrossValidation < matlab.unittest.TestCase
    %TESTCROSSVALIDATION RCWA and FDTD on the same periodic structure.
    %   A lamellar grating (period 0.8 um, thickness 0.4 um, n = 2 lines,
    %   fill 0.5, air) at normal incidence. FDTD sees the period along z
    %   and propagates along x; RCWA sees it as rcwa1D. TE (E along the
    %   lines) = RCWA "s", TM (H along the lines) = RCWA "p". The tooth is
    %   shifted by dx/4 so its edges cut cells and subpixel averaging matters.

    properties (Constant)
        P = 0.8
        H = 0.4
        F = 0.5
        Ng = 2.0
    end

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods
        function [R, T, Rr, Tr] = compare(tc, pol, lam, lambda0, bw, nSub)
            g = orf.makeStructure([tc.P Inf], orf.materialConst(1), orf.materialConst(1), ...
                {orf.makeLayer(tc.H, orf.materialConst(1), {orf.shapeRect(tc.F*tc.P, Inf, orf.materialConst(tc.Ng))})});
            rp = "s"; if pol == "TM", rp = "p"; end
            Rr = zeros(size(lam)); Tr = Rr;
            for k = 1:numel(lam)
                o = orf.rcwa1D(g, lam(k), 0, 0, rp, N=40);
                Rr(k) = o.Rtot; Tr(k) = o.Ttot;
            end
            dx = 0.01; x = (0:dx:5).'; z = ((0:round(tc.P/dx)-1).' + 0.5) * dx - tc.P/2;
            ixOf = @(xx) round(xx / dx) + 1;
            s = struct('pol', pol, 'x', x, 'z', z, 'npml', [30 0], 'periodicZ', true, ...
                'lambdas', lam, 'monitors', [ixOf(0.6) ixOf(4.2)], 'shutoff', 1e-8, ...
                'maxTime', 600);                   % NSub = 1 rings slowly (staircase)
            s.source = struct('ix', ixOf(1), 'profile', ones(numel(z), 1), 'neff', 1, ...
                'lambda0', lambda0, 'bw', bw);
            box = [2.5, 2.5 + tc.H, -tc.F*tc.P/2 + dx/4, tc.F*tc.P/2 + dx/4, tc.Ng];
            e0 = orf.epsComponents2D(x, z, 1, zeros(0, 5), PeriodicZ=true);
            e1 = orf.epsComponents2D(x, z, 1, box, PeriodicZ=true, NSub=nSub);
            o0 = orf.fdtd2D(withEps(s, e0, pol));
            o1 = orf.fdtd2D(withEps(s, e1, pol));
            R = -o1.flux(1, :) ./ o0.flux(2, :);
            T = o1.flux(2, :) ./ o0.flux(2, :);
        end
    end

    methods (Test)
        function teZeroOrderBand(tc)
            [R, T, Rr, Tr] = tc.compare("TE", [1.0 1.2 1.4 1.6], 1.25, 0.15, 4);
            tc.verifyEqual(R, Rr, 'AbsTol', 1.5e-3);
            tc.verifyEqual(T, Tr, 'AbsTol', 1.5e-3);
        end

        function teWithDiffractedOrders(tc)
            % lambda < period: the +-1 orders propagate in air.
            [R, T, Rr, Tr] = tc.compare("TE", [0.62 0.65 0.68], 0.65, 0.05, 4);
            tc.verifyEqual(R, Rr, 'AbsTol', 1.5e-3);
            tc.verifyEqual(T, Tr, 'AbsTol', 1.5e-3);
        end

        function tmSubpixelAveragingHelps(tc)
            lam = [1.0 1.2 1.4 1.6];
            [R4, ~, Rr] = tc.compare("TM", lam, 1.25, 0.15, 4);
            w = warning('off', 'fdtd2D:notConverged'); restore = onCleanup(@() warning(w));
            [R1, ~] = tc.compare("TM", lam, 1.25, 0.15, 1);
            tc.verifyEqual(R4, Rr, 'AbsTol', 2e-3);
            tc.verifyLessThan(max(abs(R4 - Rr)), max(abs(R1 - Rr)) / 2);
        end
    end
end

function s = withEps(s, e, pol)
if pol == "TE"
    s.eps = e.y;
else
    s.epsX = e.x; s.epsZ = e.z;
end
end
