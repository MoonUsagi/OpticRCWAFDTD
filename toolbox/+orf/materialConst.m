function mat = materialConst(n, name)
%MATERIALCONST Non-dispersive material with constant complex index.
%   mat = orf.materialConst(n) returns a material struct whose index is n at
%   every wavelength. Loss follows the e^{-iwt} convention: Im(n) >= 0.
arguments
    n (1,1) double
    name (1,1) string = "const"
end
mat.name = name;
mat.nk = @(lambda0) n * ones(size(lambda0));
mat.spec = struct('orfMaterial', "const", 'n', n, 'name', name);   % for saveDesign
end
