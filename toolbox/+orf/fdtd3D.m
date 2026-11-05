%FDTD3D 3D FDTD on a Yee grid. Real fields, H~ = eta0*H, time c0*t [um].
%   out = orf.fdtd3D(sim). All six components are numel(x) x numel(y) x numel(z)
%   arrays at their Yee positions (integer grid point (i,j,k) plus):
%     Ex +(1/2,0,0)  Ey +(0,1/2,0)  Ez +(0,0,1/2)
%     Hx +(0,1/2,1/2) Hy +(1/2,0,1/2) Hz +(1/2,1/2,0)
%   Updates (c cyclic, c1 = c+1, c2 = c+2):
%     H_c -= S (D+_c1 E_c2 - D+_c2 E_c1),  E_c += S/eps_c (D-_c1 H_c2 - D-_c2 H_c1)
%   D+ / D- are forward / backward differences; outside the grid the
%   fields are zero (PEC) or wrap (periodic axes).
%
%   sim.x, sim.y, sim.z : uniform grids, equal spacing d [um]
%   sim.eps        : struct .x .y .z from epsComponents3D
%   sim.npml       : [nx ny nz] CPML cells per side (0 on periodic axes)
%   sim.periodic   : [px py pz] logical (default all false)
%   sim.source     : one-sided TF/SF plane normal to axis d (1..3) at integer
%                    index s, injecting toward +d. Fields: axis, index,
%                    Ea, Eb, Ha, Hb (profiles on the plane of the two
%                    tangential components a = d+1, b = d+2, cyclic, each at
%                    its own Yee position), neff, lambda0, bw.
%                    Plane wave toward +z, x-polarised: Ea = 1, Eb = 0,
%                    Ha = 0, Hb = n.
%   sim.monitors   : struct array with axis, index: planes for flux toward +axis
%   sim.lambdas, sim.maxTime, sim.shutoff, sim.useGPU, sim.precision,
%                    sim.progress as in fdtd2D; sim.courant default 0.99/sqrt(3)
%
%   out.flux       : nMon x nLambda power toward +axis (1/2 Re sum(Ea Hb* - Eb Ha*) dA)
%   out.mon(q)     : DFT fields Ea, Eb, Ha, Hb on the plane (Na x Nb x nL);
%                    H averaged onto the E plane
%   out.converged, out.steps, out.time, out.wallTime
% (Protected file: the implementation is distributed as P-code.)
