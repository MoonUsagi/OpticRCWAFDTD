function out = fdtd2DTE(sim)
%FDTD2DTE 2D FDTD in the xz plane, TE polarisation (Ey, Hx, Hz).
%   out = orf.fdtd2DTE(sim) is fdtd2D with sim.pol = "TE". Real fields,
%   H~ = eta0*H, time as c0*t [um].
%   Yee grid: Ey at (x_i, z_k), Hx at (x_i, z_k+1/2), Hz at (x_i+1/2, z_k).
%
%   sim.x, sim.z   : uniform Ey grid vectors [um], equal spacing dx
%   sim.eps        : numel(x) x numel(z) relative permittivity (real)
%   sim.npml       : [nx nz] CPML cells at each end (nz ignored if periodic)
%   sim.periodicZ  : true for a periodic z boundary (default false)
%   sim.source     : one-sided TF/SF plane at Ey index ix, injecting toward
%                    +x the profile f(z) (numel(z) x 1) with index neff:
%                    Ey_inc = f(z) g(t - neff (x - x_s)), Hz_inc = neff Ey_inc.
%                    Fields: ix, profile, neff, lambda0 (centre), bw
%                    (relative 1/e spectral half-width, default 0.2)
%   sim.monitors   : Ey indices of x = const line monitors
%   sim.monitorsZ  : Ey indices of z = const line monitors (optional)
%   sim.lambdas    : wavelengths [um] for the running DFT (kernel e^{+iwt})
%   sim.maxTime    : stop time c0*t [um] (default 1e4)
%   sim.shutoff    : stop when field energy < shutoff * peak (default 1e-10;
%                    1e-6 truncates slow ring-down and costs ~1e-4 in R+T)
%   sim.courant    : c0 dt / dx (default 0.99/sqrt(2))
%   sim.useGPU     : time-step on the GPU (default false)
%   sim.precision  : "double" (default) or "single" for the field update;
%                    the DFT accumulators always stay double
%
%   out.flux  : nMon x nLambda power through each monitor toward +x
%               (1/2 Re int Ey Hz* dz, consistent units for ratios)
%   out.Ey, out.Hz : numel(z) x nLambda x nMon DFT fields at the monitors
%   out.fluxZ : nMonZ x nLambda power through each z monitor toward +z
%               (-1/2 Re int Ey Hx* dx); out.EyZ, out.HxZ: numel(x) x nL x nMonZ
%   out.steps, out.time, out.wallTime
sim.pol = "TE";
out = orf.fdtd2D(sim);
end
