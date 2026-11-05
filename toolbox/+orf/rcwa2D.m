%RCWA2D RCWA for crossed gratings, batched over a set of structures.
%   out = orf.rcwa2D(devs, lambda0, theta, phi, pol, Nx=5, Ny=Nx)
%
%   devs    : one makeStructure, or a cell array of B of them sharing the
%             period, incident and substrate materials and layer count
%             (e.g. a unit-cell sweep). Period [Lx Ly]; Ly = Inf gives a
%             y-invariant (1D) grating and forces Ny = 0.
%   lambda0 : vacuum wavelength [um] (scalar)
%   theta   : polar angle in the incident medium [rad]
%   phi     : azimuth from +x [rad]
%   pol     : "s" (TE), "p" (TM) or a Jones vector [aTE aTM]
%
%   Options (name-value):
%   Nx, Ny        : harmonics m = -Nx..Nx, n = -Ny..Ny
%   Nsample       : [Nsx Nsy] eps samples per period (0 = automatic, with
%                   rectangle edges on pixel boundaries when possible)
%   Factorization : "li" (default, Li 1997) or "laurent"
%   GapEps        : gap-medium permittivity (default: every gap harmonic
%                   propagates; results do not depend on it)
%   UseGPU        : run the batched linear algebra on the GPU
%   GPUEig        : with UseGPU, also do eig on the GPU (page by page);
%                   false = hybrid: pageeig on the CPU, S-matrices on the GPU
%   BatchSize     : structures per page stack (0 = auto, ~200 MB each)
%   Symmetry      : "auto" (default) reduces to the mirror-symmetric subspace
%                   (symmetryBasis, ~4x fewer unknowns) when theta = 0, pol is
%                   "s" or "p" and every patterned layer is x- and y-symmetric
%                   about the cell centre; "none" always solves the full problem
%   Progress      : callback progress(fraction, message) after each layer
%                   (and batch chunk); throw an error in it to cancel
%
%   out.m, out.n : diffraction orders, M x 1
%   out.R, out.T : efficiency per order, M x B; out.Rtot, out.Ttot: 1 x B
%   out.r, out.t : 3 x M x B complex amplitudes [x; y; z], referenced to
%                  the top (r) and bottom (t) interfaces
%   Conventions: docs/CONVENTIONS.md.
% (Protected file: the implementation is distributed as P-code.)
