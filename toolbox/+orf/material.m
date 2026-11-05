function mat = material(name)
%MATERIAL Built-in dispersive materials (published dispersion formulas).
%   Coefficients and tables follow the refractiveindex.info database.
%   mat = orf.material(name) returns a material struct usable anywhere a
%   material is expected (orf.makeLayer, orf.makeStructure, ...), with
%   fields name, nk (function of vacuum wavelength in um, Im(n) >= 0),
%   range ([min max] um; evaluating outside it is an error) and source.
%   orf.material("list") prints the available names.
%
%     "air"      n = 1
%     "SiO2"     fused silica, Sellmeier (Malitson 1965), 0.21-6.7 um
%     "Si"       crystalline silicon, Li (1980) tabulated at 293 K, 1.2-14 um;
%                below 1.2 um silicon absorbs: use measured n,k instead
%     "Si3N4"    stoichiometric LPCVD silicon nitride (Luke et al. 2015),
%                0.31-5.5 um
%     "TiO2"     rutile, ordinary ray (DeVore 1951), 0.43-1.53 um. Thin-film
%                (ALD, sputtered) TiO2 used in metalenses is amorphous and
%                has a lower index: use measured data for real designs
%     "Al2O3"    sapphire, ordinary ray (Malitson & Dodge 1972), 0.2-5 um
%
%   Amorphous silicon depends strongly on deposition, so there is no
%   default: fit your ellipsometry with orf.materialTaucLorentz or load a
%   table with orf.materialTable.
arguments
    name (1,1) string
end
key = lower(name);
switch key
    case "list"
        fprintf('air, SiO2, Si, Si3N4, TiO2, Al2O3  (see help orf.material)\n');
        mat = [];
        return
    case "air"
        mat = make("air", @(l) ones(size(l)), [0 Inf], "n = 1");
    case "sio2"
        mat = make("SiO2", @(l) sellmeier(l, [0.6961663 0.4079426 0.8974794], ...
            [0.0684043 0.1162414 9.896161]), [0.21 6.7], ...
            "I. H. Malitson, J. Opt. Soc. Am. 55, 1205 (1965)");
    case "si"
        % Li's tabulated values at 293 K (35 points), pchip-interpolated
        t = [1.20 3.5167; 1.22 3.5133; 1.24 3.5102; 1.26 3.5072; 1.28 3.5043; ...
             1.30 3.5016; 1.32 3.4990; 1.34 3.4965; 1.36 3.4941; 1.38 3.4918; ...
             1.40 3.4896; 1.45 3.4845; 1.50 3.4799; 1.55 3.4757; 1.60 3.4719; ...
             1.65 3.4684; 1.70 3.4653; 1.80 3.4597; 1.90 3.4550; 2.00 3.4510; ...
             2.25 3.4431; 2.50 3.4375; 2.75 3.4334; 3.00 3.4302; 4.00 3.4229; ...
             5.00 3.4195; 6.00 3.4177; 7.00 3.4165; 8.00 3.4158; 9.00 3.4153; ...
             10.0 3.4150; 11.0 3.4147; 12.0 3.4145; 13.0 3.4144; 14.0 3.4142];
        mat = make("Si", @(l) interp1(t(:, 1), t(:, 2), l, 'pchip'), [1.2 14], ...
            "H. H. Li, J. Phys. Chem. Ref. Data 9, 561 (1980), 293 K, tabulated");
    case "si3n4"
        mat = make("Si3N4", @(l) sellmeier(l, [3.0249 40314], [0.1353406 1239.842]), ...
            [0.31 5.5], "K. Luke et al., Opt. Lett. 40, 4823 (2015)");
    case "tio2"
        mat = make("TiO2 (rutile, o)", @(l) sqrt(5.913 + 0.2441 ./ (l.^2 - 0.0803)), ...
            [0.43 1.53], "J. R. DeVore, J. Opt. Soc. Am. 41, 416 (1951), ordinary ray");
    case "al2o3"
        mat = make("Al2O3 (sapphire, o)", @(l) sellmeier(l, [1.4313493 0.65054713 5.3414021], ...
            [0.0726631 0.1193242 18.028251]), [0.2 5], ...
            "I. H. Malitson and M. J. Dodge, J. Opt. Soc. Am. 62, 1405 (1972), ordinary ray");
    otherwise
        error('orf:material:unknown', ['Unknown material "%s". Built-in: air, SiO2, Si, ' ...
            'Si3N4, TiO2, Al2O3. For a-Si or measured data use orf.materialTaucLorentz ' ...
            'or orf.materialTable.'], name);
end
mat.spec = struct('orfMaterial', "library", 'name', name);   % for saveDesign
end

function mat = make(name, fn, range, source)
mat.name = name;
mat.range = range;
mat.source = source;
mat.nk = @(l) checked(fn, l, range, name);
end

function n = checked(fn, l, range, name)
if any(l(:) < range(1) | l(:) > range(2))
    error('orf:material:range', '%s: wavelength outside the formula''s range [%g, %g] um.', ...
        name, range(1), range(2));
end
n = complex(fn(l));
end

function n = sellmeier(l, B, C)
%SELLMEIER n^2 = 1 + sum B_i l^2 / (l^2 - C_i^2), l and C in um.
n2 = ones(size(l));
for k = 1:numel(B)
    n2 = n2 + B(k) * l.^2 ./ (l.^2 - C(k)^2);
end
n = sqrt(n2);
end
