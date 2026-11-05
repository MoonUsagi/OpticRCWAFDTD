function mat = materialTable(lambdaTab, nTab, kTab, name)
%MATERIALTABLE Dispersive material from tabulated n, k data.
%   mat = orf.materialTable(lambdaTab, nTab, kTab) interpolates n and k
%   (pchip) over wavelength [um]. Evaluating outside the table range is
%   an error, not an extrapolation.
arguments
    lambdaTab (:,1) double {mustBePositive}
    nTab (:,1) double
    kTab (:,1) double {mustBeNonnegative}
    name (1,1) string = "table"
end
assert(numel(nTab) == numel(lambdaTab) && numel(kTab) == numel(lambdaTab), ...
    'materialTable:size', 'lambdaTab, nTab, kTab must have the same length.');
[lambdaTab, idx] = sort(lambdaTab);
nTab = nTab(idx);
kTab = kTab(idx);
lo = lambdaTab(1);
hi = lambdaTab(end);

mat.name = name;
mat.nk = @evalNK;
mat.spec = struct('orfMaterial', "table", 'lambda', lambdaTab.', 'n', nTab.', ...
    'k', kTab.', 'name', name);                                    % for saveDesign

    function nk = evalNK(lambda0)
        if any(lambda0(:) < lo | lambda0(:) > hi)
            error('materialTable:range', ...
                '%s: wavelength outside table range [%g, %g] um.', name, lo, hi);
        end
        nk = interp1(lambdaTab, nTab, lambda0, 'pchip') ...
           + 1i * interp1(lambdaTab, kTab, lambda0, 'pchip');
    end
end
