%RCWAFIELDS Electromagnetic field inside and around a grating (RCWA).
%   f = orf.rcwaFields(dev, lambda0, theta, phi, pol, x, y, z, Nx=5, Ny=Nx)
%   solves dev like orf.rcwa2D and evaluates the fields on the grid
%   x (nx), y (ny), z (nz) [um]. z = 0 is the top of the first layer; the
%   incident medium is z < 0 and the substrate starts at the total thickness.
%   For a 1D grating (period [Lx Inf]) pass y = 0.
%
%   f.E, f.H : nx x ny x nz x 3 complex, components [x y z]. H is given as
%              H~ = i eta0 H (same units as E; |E| = |H~| for a plane wave
%              in vacuum, see docs/CONVENTIONS.md). Incident |E| = 1.
%   f.eps    : nx x ny x nz relative permittivity on the same grid
%   f.x, f.y, f.z : the grid; f.zInterfaces: layer boundaries
%   f.flux   : 1 x nz power flux through the unit cell at each z, from the
%              Fourier coefficients, normalised to the incident flux
%              (= Ttot in the substrate; constant inside lossless layers)
%   f.out    : the rcwa2D-style result (m, n, R, T, Rtot, Ttot)
%
%   Options: Nx, Ny, Nsample, Factorization (as orf.rcwa2D). The field is
%   a truncated Fourier series: components that jump at material edges
%   (Ex across x-edges, Ez across top/bottom faces, ...) show Gibbs
%   ringing there; increase Nx, Ny for sharper edges.
% (Protected file: the implementation is distributed as P-code.)
