%EPSCOMPONENTS3D Permittivity at the 3D Yee E locations, subpixel averaged.
%   e = orf.epsComponents3D(x, y, z, nBg, shapes) on the integer grid x, y, z
%   (uniform, equal spacing d). shapes is a cell array painted in order:
%     {"box", [x1 x2 y1 y2 z1 z2 n]}           (+-Inf allowed)
%     {"cyl", [cx cy r z1 z2 n]}               (z-axis cylinder, e.g. a pillar)
%     {"cone", [cx cy r1 r2 z1 z2 n]}          (radius r1 at z1 to r2 at z2:
%                                              a pillar with sloped sidewalls)
%     {"polygon", struct(xy, z1, z2, n)}       (prism along z; xy is K x 2)
%     {"lattice", struct(x0, y0, period, R, z1, z2, n)}  pillar array with
%                                              radius R(ix, iy) per cell (metalens);
%                                              optional field dRdz tapers every
%                                              pillar: r(z) = R + dRdz (z - z1)
%   Returns numel(x) x numel(y) x numel(z) arrays
%     e.x at (x+d/2, y, z),  e.y at (x, y+d/2, z),  e.z at (x, y, z+d/2)
%
%   Method "directional" (default): harmonic mean along the component's own
%   axis, arithmetic mean over the other two -- the normal component of an
%   axis-aligned face sees <1/eps>^-1, the tangential ones <eps>.
%   Method "kottke": diagonal of the Kottke/Farjadpour tensor with the local
%   normal n from the first moment of eps, 1/eps_cc = n_c^2 <1/eps> +
%   (1 - n_c^2)/<eps>. Measured on a cylinder array vs converged RCWA it was
%   NOT more accurate than "directional" (2.2e-3 vs 1.3e-3 at d = 30 nm):
%   without the off-diagonal terms the tensor average loses its advantage.
%   Kept for comparison; the full tensor needs an anisotropic FDTD update.
%   Either way only cells an interface crosses are sub-sampled.
%   Options: NSub (sub-samples per cell edge, default 4), Period ([Lx Ly],
%   Inf = not periodic) folds x, y into the unit cell [-L/2, L/2), Method.
% (Protected file: the implementation is distributed as P-code.)
