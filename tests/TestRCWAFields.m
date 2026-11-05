classdef TestRCWAFields < matlab.unittest.TestCase
    %TESTRCWAFIELDS Field reconstruction: analytic slab, energy flux,
    %   continuity, and consistency with orf.rcwa2D.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function slabMatchesAnalyticField(tc)
            % air / n = 2, 0.3 um / n = 1.45 at normal incidence (s: E along y).
            % Build E_y(z) from the substrate upward; the incident wave must
            % come out with unit amplitude and zero phase at z = 0.
            n = [1 2 1.45]; d = 0.3; k = 2*pi;
            slab = orf.makeStructure([0.37 0.37], orf.materialConst(n(1)), orf.materialConst(n(3)), ...
                {orf.makeLayer(d, orf.materialConst(n(2)))});
            z = linspace(-0.4, 0.7, 23).';
            f = orf.rcwaFields(slab, 1, 0, 0, "s", 0, 0, z, Nx=1);
            Ey = squeeze(f.E(1, 1, :, 2));
            t = Ey(end) / exp(1i*k*n(3)*(z(end) - d));
            q = k * n(2);
            inSlab = @(zz) t * cos(q*(zz - d)) + 1i*k*n(3)*t/q * sin(q*(zz - d));
            E0 = inSlab(0); dE0 = -q*t*sin(-q*d) + 1i*k*n(3)*t*cos(-q*d);
            a = (E0 + dE0/(1i*k*n(1))) / 2; b = (E0 - dE0/(1i*k*n(1))) / 2;
            ref = (z < 0) .* (a*exp(1i*k*n(1)*z) + b*exp(-1i*k*n(1)*z)) + ...
                  (z >= 0 & z < d) .* inSlab(z) + (z >= d) .* t .* exp(1i*k*n(3)*(z - d));
            tc.verifyEqual(Ey, ref, 'AbsTol', 1e-12);
            tc.verifyEqual(a, 1, 'AbsTol', 1e-12);                 % incident wave
            tc.verifyEqual(n(3) * abs(t)^2, orf.tmm(1, n, d, 0, "s").T, 'AbsTol', 1e-12);
        end

        function fluxIsConservedAndEqualsT(tc)
            % lossless pillar + uniform layer, oblique: the flux through the
            % cell is Ttot at every depth; efficiencies equal rcwa2D's
            dev = TestRCWAFields.pillars();
            z = [-0.3 0 0.1 0.25 0.499 0.5 0.6 0.69 0.7 1.5].';
            for pol = ["s", "p"]
                o = orf.rcwa2D(dev, 0.94, 0.3, 0.4, pol, Nx=5, Symmetry="none");
                f = orf.rcwaFields(dev, 0.94, 0.3, 0.4, pol, 0, 0, z, Nx=5);
                tc.verifyEqual(f.out.T, o.T, 'AbsTol', 1e-12);
                tc.verifyEqual(f.out.R, o.R, 'AbsTol', 1e-12);
                tc.verifyEqual(f.flux, o.Ttot * ones(1, numel(z)), 'AbsTol', 1e-10);
            end
        end

        function tangentialFieldsAreContinuous(tc)
            dev = TestRCWAFields.pillars();
            x = (-0.2:0.04:0.2).'; y = (-0.2:0.1:0.2).';
            dz = 1e-12;
            f = orf.rcwaFields(dev, 0.94, 0.3, 0.4, "p", x, y, [-dz; dz; 0.5 - dz; 0.5 + dz], Nx=5);
            for c = 1:2
                tc.verifyEqual(f.E(:, :, 2, c), f.E(:, :, 1, c), 'AbsTol', 1e-9);
                tc.verifyEqual(f.H(:, :, 2, c), f.H(:, :, 1, c), 'AbsTol', 1e-9);
                tc.verifyEqual(f.E(:, :, 4, c), f.E(:, :, 3, c), 'AbsTol', 1e-9);
                tc.verifyEqual(f.H(:, :, 4, c), f.H(:, :, 3, c), 'AbsTol', 1e-9);
            end
        end

        function lossyLayerAbsorbs(tc)
            % 1D metal grating: flux drops inside the metal layer only, and
            % 1 - R at the top equals the flux just above the metal
            met = orf.materialConst(0.2 + 3i);
            g = orf.makeStructure([0.5 Inf], orf.materialConst(1), orf.materialConst(1.45), ...
                {orf.makeLayer(0.05, orf.materialConst(1), {orf.shapeRect(0.25, Inf, met)})});
            f = orf.rcwaFields(g, 0.8, 0.2, 0, "p", 0, 0, [-0.1 0 0.025 0.05 0.3].', Nx=15);
            tc.verifyEqual(f.flux(1), 1 - f.out.Rtot, 'AbsTol', 1e-10);
            tc.verifyEqual(f.flux(end), f.out.Ttot, 'AbsTol', 1e-10);
            tc.verifyTrue(all(diff(f.flux(2:4)) < 0));
        end
    end

    methods (Static)
        function dev = pillars()
            dev = orf.makeStructure([0.4 0.4], orf.materialConst(1.45), orf.materialConst(1), ...
                {orf.makeLayer(0.5, orf.materialConst(1), {orf.shapeCircle(0.1, orf.materialConst(3.6))}), ...
                 orf.makeLayer(0.2, orf.materialConst(2))});
        end
    end
end
