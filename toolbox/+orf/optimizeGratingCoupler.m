%OPTIMIZEGRATINGCOUPLER Uniform grid scan, then Nelder-Mead on an apodized design.
%   out = orf.optimizeGratingCoupler(Name=Value) with the fixed process of
%   orf.gratingCouplerTE (220 nm Si, 70 nm etch, 2 um BOX, air cladding).
%   Stage 1: uniform grating over Periods x FillFactors (NPer1 periods).
%   Stage 2: orf.apodizedGrating(ffStart, ffEnd, theta, NPer2, scale) with
%            fminsearch on [ffStart ffEnd scale] (MaxEvals), design angle
%            = best stage-1 angle. Fiber tilt allowed: Theta (deg).
%   Every FDTD run prints one line. out.uniform / out.apodized hold the
%   best bestFiberCoupling results (plus the design parameters).
%   MinFeature clips the per-period ff so teeth and grooves stay printable;
%   Theta0 skips stage 1. Progress: callback progress(fraction, message)
%   through every FDTD run; throw an error in it to cancel.
% (Protected file: the implementation is distributed as P-code.)
