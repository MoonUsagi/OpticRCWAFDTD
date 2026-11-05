%FDTD2D 2D FDTD in the xz plane, TE (Ey, Hx, Hz) or TM (Hy, Ex, Ez).
%   out = orf.fdtd2D(sim). Real fields, H~ = eta0*H, time as c0*t [um].
%   One update loop serves both polarisations through the mapping
%     TE: P = Ey, A = Hx,  B = Hz      (eps on P)
%     TM: P = Hy, A = -Ex, B = -Ez     (eps_x on A, eps_z on B)
%   with A at (x_i, z_k+1/2), B at (x_i+1/2, z_k), P at (x_i, z_k):
%     A += cA (dP/dz),  B -= cB (dP/dx),  P += cP (dA/dz - dB/dx).
%
%   sim.pol        : "TE" (default) or "TM"
%   sim.x, sim.z   : uniform P grid vectors [um], equal spacing dx
%   sim.eps        : TE: numel(x) x numel(z) eps at Ey
%   sim.epsX, sim.epsZ : TM: eps at Ex (numel(x) x numel(z)-1, or numel(z)
%                    if periodic) and at Ez (numel(x)-1 x numel(z)); use
%                    epsComponents2D for subpixel-averaged values
%   sim.npml, sim.periodicZ, sim.monitors, sim.monitorsZ, sim.lambdas,
%   sim.maxTime, sim.shutoff, sim.courant, sim.useGPU, sim.precision:
%                    as documented in fdtd2DTE
%   sim.progress   : optional callback progress(fraction, message), called
%                    every 50 steps; throw an error in it (e.g. 'orf:cancelled')
%                    to stop the run. See orf.progressText, orf.progressDialog.
%   sim.source     : one-sided TF/SF plane at P index ix toward +x with the
%                    P profile f(z) (Ey for TE, Hy for TM) and index neff;
%                    B_inc = neff f / eps_B (eps_B = 1 for TE, eps_z for TM)
%
%   out.flux, out.fluxZ : power toward +x / +z through each monitor
%   out.P, out.B (x monitors), out.PZ, out.AZ (z monitors): DFT fields;
%   aliases TE: Ey, Hz, EyZ, HxZ;  TM: Hy, Ez, HyZ, ExZ (physical signs)
%   out.converged (false: hit maxTime, a warning is issued), out.steps,
%   out.time, out.wallTime
% (Protected file: the implementation is distributed as P-code.)
