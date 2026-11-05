classdef TestRCWA1D < matlab.unittest.TestCase
    %TESTRCWA1D Validate rcwa1D against TMM, energy, symmetry and EMT.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Static)
        function g = siGrating()
            % Si lines in air on SiO2: period 0.7, fill 0.5, height 0.5 um
            g = orf.makeStructure([0.7 Inf], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.5, orf.materialConst(1), {orf.shapeRect(0.35, Inf, orf.materialConst(3.48))})});
        end
    end

    methods (Test)
        function convMatrixExactForAlignedRect(tc)
            % Centred rect, width f*period, edges on cell boundaries:
            % eps_h = (e1 - e2) f sinc(pi h f) + e2 delta_h0.
            Nx = 64; f = 0.25; e1 = 4; e2 = 1; N = 5;
            epsS = e2 * ones(Nx, 1);
            epsS(Nx/2 - Nx*f/2 + 1 : Nx/2 + Nx*f/2) = e1;
            C = orf.convMatrix1D(epsS, N);
            h = (0:2*N).';
            ref = (e1 - e2) * f * sinc(h * f) + e2 * (h == 0);   % sinc(x) = sin(pi x)/(pi x)
            tc.verifyEqual(C(:, 1), complex(ref), 'AbsTol', 1e-14);
        end

        function homogeneousEqualsTMM(tc)
            % Lossy stack, oblique: amplitudes (s) and R, T (p) must match TMM.
            air = orf.materialConst(1); sio2 = orf.materialConst(1.45);
            lossy = orf.materialConst(2 + 0.1i);
            dev = orf.makeStructure([0.6 Inf], air, orf.materialConst(3.48), ...
                {orf.makeLayer(0.2, sio2), orf.makeLayer(0.11, lossy)});
            n = [1 1.45 2+0.1i 3.48]; d = [0.2 0.11];
            for th = deg2rad([0 25 60])
                o = orf.rcwa1D(dev, 1.3, th, 0, "s", N=5);
                t = orf.tmm(1.3, n, d, th, "s");
                tc.verifyEqual(o.r(2, 6), t.r, 'AbsTol', 1e-12);
                tc.verifyEqual(o.t(2, 6), t.t, 'AbsTol', 1e-12);
                o = orf.rcwa1D(dev, 1.3, th, 0, "p", N=5);
                t = orf.tmm(1.3, n, d, th, "p");
                tc.verifyEqual([o.Rtot o.Ttot], [t.R t.T], 'AbsTol', 1e-12);
            end
        end

        function eigPathEqualsTMM(tc)
            % A "patterned" layer whose shape has the background material
            % goes through convMatrix + eig and must still equal TMM.
            sio2 = orf.materialConst(1.45);
            dev = orf.makeStructure([0.6 Inf], orf.materialConst(1), orf.materialConst(3.48), ...
                {orf.makeLayer(0.2, sio2, {orf.shapeRect(0.3, Inf, sio2)})});
            t = orf.tmm(1.3, [1 1.45 3.48], 0.2, deg2rad(25), "p");
            o = orf.rcwa1D(dev, 1.3, deg2rad(25), 0, "p", N=5);
            tc.verifyEqual([o.Rtot o.Ttot], [t.R t.T], 'AbsTol', 1e-12);
        end

        function energyConservationLossless(tc)
            g = TestRCWA1D.siGrating();
            cases = {{0, 0, "s"}, {deg2rad(20), 0, "s"}, {deg2rad(20), 0, "p"}, ...
                     {deg2rad(20), deg2rad(30), [1 1i]}};   % last one conical
            for k = 1:numel(cases)
                c = cases{k};
                o = orf.rcwa1D(g, 1.0, c{1}, c{2}, c{3}, N=15);
                tc.verifyEqual(o.Rtot + o.Ttot, 1, 'AbsTol', 1e-12, "case " + k);
            end
        end

        function gapMediumIndependence(tc)
            g = TestRCWA1D.siGrating();
            a = orf.rcwa1D(g, 1.0, deg2rad(20), 0, "p", N=10);
            b = orf.rcwa1D(g, 1.0, deg2rad(20), 0, "p", N=10, GapEps=2.3);
            tc.verifyEqual(a.r, b.r, 'AbsTol', 1e-12);
            tc.verifyEqual(a.t, b.t, 'AbsTol', 1e-12);
        end

        function mirrorSymmetry(tc)
            % Symmetric grating: R_m(+theta) = R_{-m}(-theta).
            g = TestRCWA1D.siGrating();
            a = orf.rcwa1D(g, 1.0, deg2rad(20), 0, "s", N=10);
            b = orf.rcwa1D(g, 1.0, deg2rad(-20), 0, "s", N=10);
            tc.verifyEqual(a.R, flipud(b.R), 'AbsTol', 1e-12);
            tc.verifyEqual(a.T, flipud(b.T), 'AbsTol', 1e-12);
        end

        function effectiveMediumLimit(tc)
            % Period << lambda: TE sees eps_par = f e1 + (1-f) e2,
            % TM sees eps_perp = 1/(f/e1 + (1-f)/e2). Tests the Li rule.
            P = 0.01; e1 = 4; f = 0.5;
            g = orf.makeStructure([P Inf], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.3, orf.materialConst(1), {orf.shapeRect(f*P, Inf, orf.materialConst(sqrt(e1)))})});
            epsPar = f*e1 + (1 - f);
            epsPerp = 1 / (f/e1 + (1 - f));
            s = orf.rcwa1D(g, 1.0, 0, 0, "s", N=10);
            p = orf.rcwa1D(g, 1.0, 0, 0, "p", N=10);
            ts = orf.tmm(1.0, [1 sqrt(epsPar) 1.45], 0.3, 0, "s");
            tp = orf.tmm(1.0, [1 sqrt(epsPerp) 1.45], 0.3, 0, "p");
            tc.verifyEqual(s.Rtot, ts.R, 'AbsTol', 1e-4);
            tc.verifyEqual(p.Rtot, tp.R, 'AbsTol', 1e-3);
        end

        function liConvergesFasterThanLaurent(tc)
            % TM, high-contrast Si grating: Li error must be far smaller.
            g = TestRCWA1D.siGrating();
            ref = orf.rcwa1D(g, 1.55, 0, 0, "p", N=100, Nsample=4096).T(101);
            li = orf.rcwa1D(g, 1.55, 0, 0, "p", N=20, Nsample=4096).T(21);
            la = orf.rcwa1D(g, 1.55, 0, 0, "p", N=20, Nsample=4096, Factorization="laurent").T(21);
            tc.verifyLessThan(abs(li - ref), 1e-4);
            tc.verifyLessThan(abs(li - ref), abs(la - ref) / 10);
        end

        function rayleighAnomalyStaysFinite(tc)
            % lambda = period * n_substrate: one order is exactly grazing
            % (kz = 0). The solve must stay finite, conserve energy and be
            % continuous with its neighbours (this used to return NaN).
            g = TestRCWA1D.siGrating();
            lamRA = 0.7 * 1.45;
            for pol = ["s", "p"]
                o = orf.rcwa1D(g, lamRA, 0, 0, pol, N=15);
                tc.verifyTrue(all(isfinite([o.R; o.T])), pol);
                tc.verifyEqual(o.Rtot + o.Ttot, 1, 'AbsTol', 1e-6, pol);
                oL = orf.rcwa1D(g, lamRA - 1e-5, 0, 0, pol, N=15);
                oR = orf.rcwa1D(g, lamRA + 1e-5, 0, 0, pol, N=15);
                % the anomaly is a branch point, so allow a modest jump
                tc.verifyLessThan(abs(o.Ttot - (oL.Ttot + oR.Ttot)/2), 1e-2, pol);
            end
        end

        function subwavelengthHasOnlyZeroOrder(tc)
            % Period < lambda / n_sub at normal incidence: no diffraction.
            g = TestRCWA1D.siGrating();
            o = orf.rcwa1D(g, 1.55, 0, 0, "s", N=10);
            nonzero = o.m ~= 0;
            tc.verifyEqual(o.R(nonzero), zeros(nnz(nonzero), 1), 'AbsTol', 1e-14);
            tc.verifyEqual(o.T(nonzero), zeros(nnz(nonzero), 1), 'AbsTol', 1e-14);
        end
    end
end
