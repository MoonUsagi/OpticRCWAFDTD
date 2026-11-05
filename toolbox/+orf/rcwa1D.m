function out = rcwa1D(dev, lambda0, theta, phi, pol, opts)
%RCWA1D RCWA for gratings periodic in x (invariant in y), incl. conical.
%   out = orf.rcwa1D(dev, lambda0, theta, phi, pol, N=10)
%
%   Thin wrapper over rcwa2D with Ny = 0; dev needs period [Lx Inf].
%   Options: N, Nsample (samples per period, 0 = max(1024, 8(4N+1))),
%   Factorization ("li" | "laurent"), GapEps. Outputs as rcwa2D, with
%   out.r, out.t as 3 x (2N+1) and out.R, out.T as columns.
arguments
    dev (1,1) struct
    lambda0 (1,1) double {mustBePositive}
    theta (1,1) double
    phi (1,1) double
    pol
    opts.N (1,1) double {mustBeInteger, mustBeNonnegative} = 10
    opts.Nsample (1,1) double {mustBeInteger, mustBeNonnegative} = 0
    opts.Factorization (1,1) string {mustBeMember(opts.Factorization, ["li", "laurent"])} = "li"
    opts.GapEps (1,1) double = NaN
end
assert(isfinite(dev.period(1)) && ~isfinite(dev.period(2)), 'rcwa1D:period', ...
    'rcwa1D needs period [Lx Inf].');
Ns = opts.Nsample;
if Ns == 0
    Ns = orf.alignedSampleCount({dev}, dev.period, 1, max(1024, 8*(4*opts.N + 1)));
end
out = orf.rcwa2D(dev, lambda0, theta, phi, pol, Nx=opts.N, Nsample=[Ns 1], ...
    Factorization=opts.Factorization, GapEps=opts.GapEps);
end
