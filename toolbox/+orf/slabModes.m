function modes = slabModes(z, n, lambda0, pol, nModes, opts)
%SLABMODES Guided modes of a 1D index profile n(z) by finite differences.
%   modes = orf.slabModes(z, n, lambda0, pol, nModes) on a uniform grid z
%   [um] (Dirichlet walls at both ends, so make the domain wide enough
%   for the tails to vanish). Returns modes.neff (nModes x 1, descending)
%   and modes.field (numel(z) x nModes, max |field| = 1, positive peak).
%
%   pol = "TE": E_y,  d2E/dz2 + k0^2 eps E = beta^2 E.
%   pol = "TM": H_y,  eps_z d/dz(1/eps_x dH/dz) + k0^2 eps_z H = beta^2 H,
%   with eps_z = n.^2 at the grid points and eps_x at the half points
%   z_k+1/2, where E_x lives. E_x is tangential to the layers, so the
%   default eps_x is the arithmetic mean of the neighbours; pass
%   EpsHalf (numel(z)-1 values) to use the FDTD's own averaged eps_x.
%   Use the FDTD grid for z so the mode matches the FDTD discretisation.
arguments
    z (:,1) double
    n (:,1) double
    lambda0 (1,1) double {mustBePositive}
    pol (1,1) string {mustBeMember(pol, ["TE", "TM"])}
    nModes (1,1) double {mustBeInteger, mustBePositive} = 1
    opts.EpsHalf (:,1) double = []
end
assert(numel(n) == numel(z), 'slabModes:size', 'n must match z.');
dz = z(2) - z(1);
N = numel(z);
k0 = 2*pi / lambda0;
epsr = n.^2;
if pol == "TE"
    e = ones(N, 1) / dz^2;
    A = spdiags([e, -2*e, e], -1:1, N, N) + k0^2 * spdiags(epsr, 0, N, N);
else
    epsH = opts.EpsHalf;
    if isempty(epsH)
        epsH = 0.5 * (epsr(1:end-1) + epsr(2:end));
    end
    assert(numel(epsH) == N - 1, 'slabModes:epsHalf', 'EpsHalf needs numel(z)-1 values.');
    % Dirichlet walls (H = 0 one cell outside), eps_x there = edge value
    up = [1 ./ epsH; 1 ./ epsr(end)] .* epsr / dz^2;  % coefficient of H_{k+1} in row k
    lo = [1 ./ epsr(1); 1 ./ epsH] .* epsr / dz^2;    % coefficient of H_{k-1} in row k
    di = -(up + lo) + k0^2 * epsr;
    % spdiags aligns the sub-diagonal by row k+1 and the super-diagonal by row k-1
    A = spdiags([[lo(2:end); 0], di, [0; up(1:end-1)]], -1:1, N, N);
end
[V, D] = eig(full(A));
[beta2, order] = sort(real(diag(D)), 'descend');
order = order(1:nModes);
modes.neff = sqrt(complex(beta2(1:nModes))) / k0;
modes.field = V(:, order);
for k = 1:nModes
    [~, ip] = max(abs(modes.field(:, k)));
    modes.field(:, k) = modes.field(:, k) / modes.field(ip, k);
end
if isreal(n) && isreal(opts.EpsHalf)
    modes.neff = real(modes.neff);
    modes.field = real(modes.field);
end
end

