%WGMODES2D Full-vector modes of a waveguide cross-section (Yee-grid FD).
%   modes = orf.wgModes2D(x, y, nBg, boxes, lambda0, nModes) for a uniform
%   grid of cell centres x, y [um] (the E_z points), cross-section boxes
%   [x1 x2 y1 y2 n] and propagation exp(i(beta z - w t)).
%   Yee layout in the xy plane: E_z at (i, j); E_x, h_y at (i+1/2, j);
%   E_y, h_x at (i, j+1/2); h_z at (i+1/2, j+1/2), with h = eta0 H.
%   Eliminating E_z and h_z leaves the same form as RCWA:
%       beta E_t = P h_t,  beta h_t = Q E_t,  beta^2 E_t = P Q E_t,
%     P = (1/k0)[-Ux ez^-1 Vy,  Ux ez^-1 Vx; -Uy ez^-1 Vy,  Uy ez^-1 Vx] + k0[0 I; -I 0]
%     Q = (1/k0)[ Vx Uy, -Vx Ux; Vy Uy, -Vy Ux] + k0[0 -ey; ex 0]
%   U = forward differences, V = -U.' (PEC walls; option PeriodicX).
%   eps_x / eps_y are harmonic means along x / y (normal components),
%   eps_z the arithmetic mean (subpixel averaging, epsCellMean).
%
%   Options: NGuess (shift for eigs, default the largest index),
%   PeriodicX (default false), NSub (default 4), Eps (struct with fields
%   x, y, z of size numel(x) x numel(y) at the E_x, E_y, E_z points: use
%   these instead of averaging the boxes, e.g. a plane of an FDTD grid).
%   modes.neff  : nModes x 1, descending
%   modes.Ex, Ey, Ez, Hx, Hy, Hz : numel(x) x numel(y) x nModes, on their
%                 Yee points, normalised so max |E_t| = 1 (H is eta0*H)
%   modes.teFraction : int |Ex|^2 / int (|Ex|^2 + |Ey|^2) per mode
%   modes.grid  : coordinates of each component
% (Protected file: the implementation is distributed as P-code.)
