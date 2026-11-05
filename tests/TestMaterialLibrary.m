classdef TestMaterialLibrary < matlab.unittest.TestCase
    %TESTMATERIALLIBRARY Built-in dispersion formulas against handbook values,
    %   and the Kramers-Kronig / Tauc-Lorentz implementation.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function handbookIndices(tc)
            % Reference values: n_d of fused silica and sapphire (handbooks),
            % Li's Si table, and the published formulas evaluated independently
            % (coefficients checked against the refractiveindex.info database).
            cases = { ...
                "SiO2",  0.5876, 1.4585, 1e-4;    % fused silica n_d
                "SiO2",  1.55,   1.4440, 1e-4;
                "Si",    1.55,   3.4757, 1e-4;    % Li 1980, 293 K table
                "Si",    2.0,    3.4510, 1e-4;
                "Si",    1.425,  3.4870, 5e-4;    % between table nodes (pchip)
                "Si3N4", 1.55,   1.9963, 5e-4;    % Luke 2015
                "TiO2",  0.6328, 2.5837, 5e-4;    % rutile n_o at HeNe
                "Al2O3", 0.5876, 1.7682, 2e-4};   % sapphire n_o (n_d)
            for k = 1:size(cases, 1)
                [name, lam, ref, tol] = cases{k, :};
                n = orf.material(name).nk(lam);
                tc.verifyEqual(real(n), ref, 'AbsTol', tol, name + " @ " + lam);
                tc.verifyEqual(imag(n), 0, name);
            end
        end

        function normalDispersionAndRange(tc)
            m = orf.material("SiO2");
            n = real(m.nk([0.4 0.6 1.0 1.5]));
            tc.verifyTrue(all(diff(n) < 0));                       % normal dispersion
            tc.verifyError(@() orf.material("Si").nk(0.94), 'orf:material:range');
            tc.verifyError(@() orf.material("aSi"), 'orf:material:unknown');
        end

        function worksInsideSolvers(tc)
            % A dispersive library material must drop into TMM via a structure.
            dev = orf.makeStructure([Inf Inf], orf.material("air"), orf.material("Si"), ...
                {orf.makeLayer(0.2, orf.material("Si3N4"))});
            lam = [1.3; 1.55];
            [n, d] = orf.structureToTMM(dev, lam);
            o = orf.tmm(lam, n, d, 0, "s");
            tc.verifyEqual(o.R + o.T, [1; 1], 'AbsTol', 1e-12);
            tc.verifyGreaterThan(real(n(1, 2)), real(n(2, 2)));   % Si3N4 index falls with lambda
        end

        function kramersKronigOnLorentzOscillator(tc)
            % Lorentz oscillator: eps = 1 + f / (E0^2 - E^2 - i g E) (e^{-iwt}),
            % an exact KK pair, so kkEps1 must reproduce eps1 - 1.
            f = 5; E0 = 3; g = 0.4;
            eps2 = @(E) f * g * E ./ ((E0^2 - E.^2).^2 + g^2 * E.^2);
            E = [0.5 1.5 2.9 3.0 3.1 5 8];
            ref = f * (E0^2 - E.^2) ./ ((E0^2 - E.^2).^2 + g^2 * E.^2);
            tc.verifyEqual(orf.kkEps1(eps2, 0, E), ref, 'AbsTol', 1e-6);
        end

        function taucLorentzPhysics(tc)
            % Representative a-Si parameters (not a reference film).
            m = orf.materialTaucLorentz(120, 3.6, 2.4, 1.6, 1.0, Name="a-Si test");
            % gap 1.6 eV = 0.775 um: 1.0 and 1.55 um are below it, 0.4 and 0.6 above
            nBelow = m.nk([1.0 1.55]);                  % photon energy below the gap
            nAbove = m.nk([0.4 0.6]);
            tc.verifyEqual(imag(nBelow), [0 0]);        % transparent below Eg
            tc.verifyTrue(all(imag(nAbove) > 0));       % absorbing above Eg
            tc.verifyTrue(all(real(nBelow) > 2.5 & real(nBelow) < 5));
            tc.verifyGreaterThan(real(m.nk(1.0)), real(m.nk(1.55)));   % normal dispersion below gap
            % cached: the same wavelength returns the identical value
            tc.verifyEqual(m.nk(1.0), nBelow(1));
        end
    end
end
