function mat = materialTaucLorentz(A, E0, C, Eg, epsInf, opts)
%MATERIALTAUCLORENTZ Amorphous semiconductor from Tauc-Lorentz parameters.
%   mat = orf.materialTaucLorentz(A, E0, C, Eg, epsInf) builds a material
%   from the Jellison-Modine Tauc-Lorentz model, the usual ellipsometry fit
%   for amorphous silicon, a-Si:H, SiN_x and similar films. Energies in eV:
%       eps2(E) = A E0 C (E - Eg)^2 / ((E^2 - E0^2)^2 + C^2 E^2) / E,  E > Eg
%       eps2(E) = 0,                                                  E <= Eg
%       eps1(E) = epsInf + Kramers-Kronig transform of eps2 (orf.kkEps1)
%   A: amplitude, E0: peak energy, C: broadening, Eg: optical gap,
%   epsInf: high-frequency constant. Take them from your film's
%   ellipsometry report; there is no universal a-Si.
%   Options: Name (default "Tauc-Lorentz"), Range ([min max] um, default
%   [0.2 20]). mat.nk(lambda_um) returns n + ik (k >= 0, e^{-iwt}).
%   Values are computed once per distinct wavelength and cached.
arguments
    A (1,1) double {mustBePositive}
    E0 (1,1) double {mustBePositive}
    C (1,1) double {mustBePositive}
    Eg (1,1) double {mustBeNonnegative}
    epsInf (1,1) double
    opts.Name (1,1) string = "Tauc-Lorentz"
    opts.Range (1,2) double = [0.2 20]
end
eps2 = @(E) (E > Eg) .* A * E0 * C .* (E - Eg).^2 ./ ((E.^2 - E0^2).^2 + C^2 * E.^2) ./ E;
mat.name = opts.Name;
mat.range = opts.Range;
mat.source = sprintf('Tauc-Lorentz: A = %g, E0 = %g eV, C = %g eV, Eg = %g eV, eps_inf = %g', ...
    A, E0, C, Eg, epsInf);
mat.params = struct('A', A, 'E0', E0, 'C', C, 'Eg', Eg, 'epsInf', epsInf);
mat.spec = struct('orfMaterial', "taucLorentz", 'params', mat.params, ...
    'name', opts.Name, 'range', opts.Range);                       % for saveDesign
cache = containers.Map('KeyType', 'double', 'ValueType', 'any');
mat.nk = @evalNK;

    function n = evalNK(lambda0)
        if any(lambda0(:) < opts.Range(1) | lambda0(:) > opts.Range(2))
            error('orf:materialTaucLorentz:range', '%s: wavelength outside [%g, %g] um.', ...
                opts.Name, opts.Range(1), opts.Range(2));
        end
        n = complex(zeros(size(lambda0)));
        for k = 1:numel(lambda0)
            key = lambda0(k);
            if ~isKey(cache, key)
                E = 1.23984198 / key;                          % photon energy [eV]
                epsr = epsInf + orf.kkEps1(eps2, Eg, E) + 1i * eps2(E);
                cache(key) = sqrt(epsr);                       % Im >= 0 since eps2 >= 0
            end
            n(k) = cache(key);
        end
    end
end
