%EPSCOMPONENTS2D Permittivity at each Yee field location, with subpixel averaging.
%   e = orf.epsComponents2D(x, z, nBg, boxes) for the Ey/Hy grid x, z and
%   boxes [x1 x2 z1 z2 n] (see epsFromBoxes). Returns
%     e.y : at (x_i, z_k)       arithmetic cell mean (E_y tangential to all edges)
%     e.x : at (x_i, z_k+1/2)   E_x: harmonic mean along x, then arithmetic along z
%     e.z : at (x_i+1/2, z_k)   E_z: harmonic mean along z, then arithmetic along x
%   The directional means are the anisotropic (Farjadpour/Kottke) averages
%   for axis-aligned interfaces: the normal component averages 1/eps.
%   Options: NSub (sub-samples per cell edge, default 4); PeriodicZ (true:
%   e.x has numel(z) rows, the last at z_end + dz/2, and z wraps).
% (Protected file: the implementation is distributed as P-code.)
