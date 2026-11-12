classdef TestInverseDesign < matlab.unittest.TestCase
    %TESTINVERSEDESIGN FDFD solver, its adjoint gradient, and the
    %   grating-coupler inverse design.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function straightWaveguideIsExact(tc)
            % SOI slab: the guided wave travels with the Yee-grid dispersion
            % of the slab mode, keeps its power and splits evenly both ways
            d = 0.02; lam = 1.55;
            x = (0:d:10).'; z = ((-2.6):d:1.8).' + d/2;
            epsr = orf.epsFromBoxes(x, z, 1.0, [-Inf Inf -Inf -2 3.476; ...
                -Inf Inf -2 0 1.444; -Inf Inf 0 0.22 3.476]);
            win = z > -1.5 & z < z(end) - 30 * d;
            i0 = round(2 / d) + 1;
            m = orf.slabModes(z(win), sqrt(epsr(i0, win)).', lam, "TE");
            J = zeros(numel(x), numel(z)); J(i0, win) = m.field(:, 1).';
            o = orf.fdfd2D(x, z, epsr, lam, J);
            iz = 1:numel(z);
            P4 = o.fluxX(round(4 / d) + 1, iz); P8 = o.fluxX(round(8 / d) + 1, iz);
            tc.verifyEqual(P8 / P4, 1, 'AbsTol', 1e-5);
            tc.verifyEqual(o.fluxX(round(1 / d) + 1, iz) / P4, -1, 'AbsTol', 1e-4);
            [~, k] = max(abs(m.field(:, 1))); k = find(win, 1) - 1 + k;
            xr = round(4 / d) + 1:round(8 / d) + 1;
            ph = polyfit(x(xr), unwrap(angle(o.E(xr, k))), 1);
            nYee = (2 / d) * asin(m.neff(1) * o.k0 * d / 2) / o.k0;
            tc.verifyEqual(ph(1) / o.k0, nYee, 'AbsTol', 1e-5);
        end

        function adjointGradientIsExact(tc)
            % filter -> projection -> mask products -> FDFD -> fiber overlap
            % (and the fiber position), vs central differences, every process
            for pr = ["shallow", "dual", "overlay"]
                q = struct('dx', 0.04, 'Ld', 4, 'lambdas', [1.53 1.57], 'x0', 2, 'w0', 2.5, ...
                    'process', pr);
                r = orf.inverseDesignGratingCoupler(q, CheckGradient=2);
                tc.verifyEqual(r.adjoint, r.finiteDifference, 'RelTol', 1e-5, ...
                    'AbsTol', 1e-8, char(pr));
            end
        end

        function optimisationImprovesAndRespectsFeatures(tc)
            q = struct('dx', 0.04, 'Ld', 6, 'lambdas', 1.55, 'w0', 2.5);
            r = orf.inverseDesignGratingCoupler(q, Betas=[4 16], Iterations=8, ...
                MinFeature=0.12, Verbose=false);
            tc.verifyGreaterThan(r.eta, r.etaStart + 0.03);
            tc.verifyGreaterThanOrEqual(r.minFeature, 0.12 - 1e-12);
            % period / ff and grooves describe the same pattern
            edges = 4 + [0, cumsum(r.period)];
            g = [edges(1:end-1).' + r.ff.' .* r.period.', edges(2:end).'];
            tc.verifyEqual(g, r.grooves, 'AbsTol', 1e-9);
        end
    end

    methods (Test, TestTags = {'Slow'})
        function overlayDesignChecksOutInFdtd(tc)
            % a short overlay optimisation: its final layout, run by the FDTD
            % (orf.gratingCouplerTE with res.layout), couples like the FDFD says
            q = struct('dx', 0.04, 'Ld', 8, 'lambdas', 1.55, 'process', "overlay");
            r = orf.inverseDesignGratingCoupler(q, Betas=[4 16], Iterations=8, Polish=0, ...
                MinFeature=0.12, Verbose=false);
            tc.verifyGreaterThan(r.eta, 0.6);                   % the overlay sends light up
            f = orf.gratingCouplerTE(struct('dx', 0.04, 'layout', r.layout, 'lambdas', 1.55));
            eta = orf.fiberCoupling(f, deg2rad(r.params.thetaDeg), 4 + r.x0, r.params.w0);
            tc.verifyEqual(eta, r.eta, 'AbsTol', 0.03);
        end

        function fdfdAgreesWithFdtd(tc)
            % the same uniform grating (FDTD's own eps array) in both solvers
            p = struct('dx', 0.04, 'nPer', 10, 'lambdas', 1.55, 'lambda0', 1.55);
            f = orf.gratingCouplerTE(p);
            g = f.geometry; x = g.x; z = g.z; d = 0.04;
            i0 = round(2.0 / d) + 1;
            win = z > -1.5 & z < z(end) - 15 * d;
            m = orf.slabModes(z(win), sqrt(g.eps(i0, win)).', 1.55, "TE");
            J = zeros(numel(x), numel(z)); J(i0, win) = m.field(:, 1).';
            ref = orf.fdfd2D(x, z, repmat(g.eps(i0, :), numel(x), 1), 1.55, J, Npml=[15 15]);
            o = orf.fdfd2D(x, z, g.eps, 1.55, J, Npml=[15 15]);
            Pin = ref.fluxX(round(3.0 / d) + 1, 1:numel(z));
            iUp = round((0.22 + 1.0 - z(1)) / d) + 1;
            xr = find(x >= f.xUp(1) - 1e-9 & x <= f.xUp(end) + 1e-9);
            Pup = o.fluxZ(iUp, xr) / Pin;
            tc.verifyEqual(Pup, f.Pup, 'AbsTol', 2e-3);          % measured: 1e-4
        end
    end
end
