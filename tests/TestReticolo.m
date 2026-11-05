classdef TestReticolo < matlab.unittest.TestCase
    %TESTRETICOLO RCWA against reference values from RETICOLO V10.
    %   J.-P. Hugonin and P. Lalanne, RETICOLO software for grating analysis,
    %   arXiv:2101.00901; code doi:10.5281/zenodo.14631951 (CC BY 4.0).
    %   Values were computed with RETICOLO (parm.res1.li = 0, the same Li
    %   factorization choice as orf.rcwa2D) and the same harmonics, so the
    %   two independent codes must agree to round-off.
    %   benchmarks/compare_reticolo.m regenerates them and covers more cases.

    properties (Constant)
        Tol = 1e-10
    end

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function siliconLines1D(tc)
            % Si lines (n 3.48, 350 nm) in air, period 700 nm, 500 nm thick,
            % on glass; 1 um at 30 deg; N = 20. Rows: orders -1, 0.
            ref.s = [0.09914609541871 0.42326574346153; 0.285224101220668 0.192364059899092];
            ref.p = [0.192732318033944 0.108317884651981; 0.20988384514138 0.489065952172691];
            g = orf.makeStructure([0.7 Inf], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.5, orf.materialConst(1), {orf.shapeRect(0.35, Inf, orf.materialConst(3.48))})});
            for pol = ["s", "p"]
                o = orf.rcwa1D(g, 1.0, pi/6, 0, pol, N=20);
                k = [find(o.m == -1), find(o.m == 0)];
                tc.verifyEqual([o.R(k).'; o.T(k).'], ref.(pol), 'AbsTol', tc.Tol, pol);
            end
        end

        function metalLines1D(tc)
            % eps = -40 + 3i lines (250 nm, 100 nm thick), period 500 nm,
            % 0.8 um, 10 deg, TM, N = 10: large contrast, inverse rule.
            nAg = sqrt(-40 + 3i);
            g = orf.makeStructure([0.5 Inf], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.1, orf.materialConst(1), {orf.shapeRect(0.25, Inf, orf.materialConst(nAg))})});
            o = orf.rcwa1D(g, 0.8, 10*pi/180, 0, "p", N=10);
            tc.verifyEqual(o.R(o.m == 0), 0.332007456102883, 'AbsTol', tc.Tol);
            tc.verifyEqual([o.T(o.m == -1) o.T(o.m == 0)], ...
                [0.443408164777492 0.167385959027564], 'AbsTol', tc.Tol);
        end

        function asymmetricCell2D(tc)
            % Two off-centre n = 2 rectangles, period 0.6 x 0.5 um, 0.3 um
            % thick, air over glass; 0.55 um, theta 25, phi 60 deg, TM, N = 7.
            m2 = orf.materialConst(2);
            dev = orf.makeStructure([0.6 0.5], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.3, orf.materialConst(1), {orf.shapeRect(0.2, 0.3, m2, [-0.15 0.05]), ...
                orf.shapeRect(0.1, 0.15, m2, [0.15 -0.1])})});
            o = orf.rcwa2D(dev, 0.55, 25*pi/180, 60*pi/180, "p", Nx=7, Symmetry="none");
            R = [-1 0 0.00437916400896857; 0 -1 0.00486628693612895; 0 0 0.0242383282290468];
            T = [-1 -1 0.0861618229939547; -1 0 0.207662448963002; 0 -1 0.115854760808926; ...
                 0 0 0.328120039118731; 1 -1 0.0640782055177045; 1 0 0.164638943423548];
            tc.verifyEqual(arrayfun(@(k) o.R(o.m == R(k, 1) & o.n == R(k, 2)), (1:3).'), R(:, 3), 'AbsTol', tc.Tol);
            tc.verifyEqual(arrayfun(@(k) o.T(o.m == T(k, 1) & o.n == T(k, 2)), (1:6).'), T(:, 3), 'AbsTol', tc.Tol);
            tc.verifyEqual(o.Rtot + o.Ttot, sum(R(:, 3)) + sum(T(:, 3)), 'AbsTol', tc.Tol);
        end

        function phaseLibrary(tc)
            % Square a-Si pillars (n 3.6, 0.5 um) on glass, period 0.4 um,
            % 940 nm, normal incidence from the glass, N = 6. The absolute
            % phase depends on the reference plane, so compare relative phase.
            w = [0.1 0.2 0.3];
            T0 = [0.972991318599262 0.956242560200507 0.825018164419487];
            ph = [-2.6526305208075 1.55142095438699 -2.40700982436707];
            devs = arrayfun(@(a) orf.makeStructure([0.4 0.4], orf.materialConst(1.45), orf.materialConst(1), ...
                {orf.makeLayer(0.5, orf.materialConst(1), {orf.shapeRect(a, a, orf.materialConst(3.6))})}), ...
                w, 'UniformOutput', false);
            o = orf.rcwa2D(devs, 0.94, 0, 0, "s", Nx=6);
            k0 = o.m == 0 & o.n == 0;
            t = squeeze(sum(o.t(1:2, k0, :), 1)).';
            tc.verifyEqual(o.T(k0, :), T0, 'AbsTol', tc.Tol);
            tc.verifyEqual(angle(t ./ t(1)), angle(exp(1i * (ph - ph(1)))), 'AbsTol', 1e-9);
        end
    end
end
