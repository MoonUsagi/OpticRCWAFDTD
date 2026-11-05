%BUILDPHASELIBRARY Zero-order transmission of a unit-cell sweep (RCWA).
%   lib = orf.buildPhaseLibrary(makeCell, params, lambda0) evaluates
%   makeCell(p) for every p in params (one batched rcwa2D call) at normal
%   incidence and returns the co-polarised zero-order transmission.
%
%   Options: N (harmonics, default 10, see
%   benchmarks/convergence_phaseLibrary.m), Pol ("s" = E_y, default; or
%   "p"), CheckN (if > 0, recompute at this N and store the per-cell
%   difference in lib.meta.phaseDiff), UseGPU, Progress (callback, see
%   orf.rcwa2D).
%
%   lib.param   : swept parameter, 1 x B
%   lib.t       : complex co-pol zero-order amplitude, 1 x B
%   lib.T       : zero-order transmittance (all polarisations), 1 x B
%   lib.phase   : unwrapped phase of t relative to the first cell [rad]
%   lib.span    : phase coverage [rad]
%   lib.meta    : lambda0, N, pol, period, and convergence check results
% (Protected file: the implementation is distributed as P-code.)
