%FDFD2D Frequency-domain 2D TE solver (E_y in the x-z plane) with adjoint.
%   out = orf.fdfd2D(x, z, epsr, lambda0, J) solves, at one wavelength,
%       (1/s_x) d/dx((1/s_x) dE/dx) + (1/s_z) d/dz((1/s_z) dE/dz) + k0^2 eps E = -J
%   for E = E_y on the grid x (nx), z (nz), uniform and equal spacing, with
%   stretched-coordinate PML (s = 1 + i a (d/L)^3, e^{-iwt}: outgoing waves
%   decay) and E = 0 outside. epsr and J are nx x nz (eps may be complex).
%   The same Yee points and eps as orf.fdtd2DTE, so results agree with the
%   FDTD up to its time-stepping error.
%
%   Options: Npml ([nx nz] cells, default [30 30]), PmlReflection (1e-8).
%   out.E      : nx x nz field
%   out.k0     : 2 pi / lambda0
%   out.adjoint(g) : solves A.' lam = g (g nx x nz or nx*nz x 1) with the
%                stored LU factors. For a figure of merit c = sum(g .* E),
%                dc/deps = -k0^2 lam .* E  (one extra solve for all pixels).
%   out.solve(J2)  : another right-hand side with the same factors.
%   out.fluxX(ix, iz) / out.fluxZ(iz, ix): power through a vertical /
%                horizontal line (relative units, the same for both; > 0
%                toward +x / +z), from centred differences of E.
% (Protected file: the implementation is distributed as P-code.)
