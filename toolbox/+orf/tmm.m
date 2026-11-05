function out = tmm(lambda0, n, d, theta0, pol)
%TMM 1D transfer-matrix method (Abeles characteristic matrix).
%   out = orf.tmm(lambda0, n, d, theta0, pol)
%
%   lambda0 : Nl x 1 vacuum wavelengths [um]
%   n       : 1 x M or Nl x M complex indices, columns ordered
%             [incident, layer 1 ... layer M-2, substrate]
%   d       : 1 x (M-2) layer thicknesses [um]
%   theta0  : 1 x Nt incidence angles in the incident medium [rad]
%   pol     : "s" (TE, E_y) or "p" (TM, H_y)
%
%   out.r, out.t : amplitude coefficients (E_y ratio for s, H_y for p)
%   out.R, out.T, out.A : reflectance, transmittance, absorptance
%   All outputs are Nl x Nt. Conventions: docs/CONVENTIONS.md.
%
%   This is the validation baseline. It is not stabilised for very thick
%   absorbing layers (cos/sin of large imaginary phase overflow).
arguments
    lambda0 (:,1) double {mustBePositive}
    n (:,:) double
    d (1,:) double {mustBeNonnegative}
    theta0 (1,:) double
    pol (1,1) string {mustBeMember(pol, ["s", "p"])}
end
M = size(n, 2);
assert(M >= 2, 'tmm:layers', 'n needs at least incident and substrate columns.');
assert(numel(d) == M - 2, 'tmm:thickness', 'd must have M-2 entries.');
if size(n, 1) == 1
    n = repmat(n, numel(lambda0), 1);
end
assert(size(n, 1) == numel(lambda0), 'tmm:size', 'n must be 1xM or Nl x M.');
assert(all(abs(imag(n(:, 1))) < 1e-12), 'tmm:lossyIncident', ...
    'Incident medium must be lossless.');

k0 = 2*pi ./ lambda0;
kx = k0 .* real(n(:, 1)) .* sin(theta0);

q0 = admittance(n(:, 1), k0, kx, pol);
qs = admittance(n(:, M), k0, kx, pol);

m11 = ones(size(kx));  m12 = zeros(size(kx));
m21 = zeros(size(kx)); m22 = ones(size(kx));
for j = 2:M-1
    [q, kz] = admittance(n(:, j), k0, kx, pol);
    delta = kz * d(j-1);
    c = cos(delta);
    s = sin(delta);
    l11 = c;  l12 = -1i * s ./ q;
    l21 = -1i * q .* s;  l22 = c;
    [m11, m12, m21, m22] = deal(m11.*l11 + m12.*l21, m11.*l12 + m12.*l22, ...
                                m21.*l11 + m22.*l21, m21.*l12 + m22.*l22);
end

B = m11 + m12 .* qs;
C = m21 + m22 .* qs;
den = q0 .* B + C;
out.r = (q0 .* B - C) ./ den;
out.t = 2 * q0 ./ den;
out.R = abs(out.r).^2;
out.T = real(qs) ./ real(q0) .* abs(out.t).^2;
out.A = 1 - out.R - out.T;
end

function [q, kz] = admittance(nj, k0, kx, pol)
%ADMITTANCE Tilted admittance: kz/k0 for s, kz/(k0*eps) for p.
kz = orf.kzBranch(nj.^2 .* k0.^2 - kx.^2);
if pol == "s"
    q = kz ./ k0;
else
    q = kz ./ (k0 .* nj.^2);
end
end
