function [W, V, lam] = modesHomogeneous(Kx, Ky, epsr)
%MODESHOMOGENEOUS Analytic eigenmodes of a uniform medium (no eig).
%   Kx, Ky are diagonal (normalised by k0). Returns W = I, V = Q*lam^-1
%   and lam = -i*kz/k0 as a column vector, kz on the outgoing branch, so
%   the forward mode exp(-lam z') equals exp(+i kz z) (e^{-iwt}).
M = size(Kx, 1);
kz = orf.kzNonzero(orf.kzBranch(epsr - diag(Kx).^2 - diag(Ky).^2));   % grazing orders
lam = -1i * [kz; kz];
kx = diag(Kx); ky = diag(Ky);                 % diagonal K: no O(M^3) products
Q = [diag(kx .* ky), diag(epsr - kx.^2); diag(ky.^2 - epsr), -diag(ky .* kx)];
W = eye(2*M);
V = Q ./ lam.';
end
