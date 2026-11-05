%APODIZEDGRATING Linearly apodized fill factor with phase-matched periods.
%   [period, ff] = orf.apodizedGrating(ffStart, ffEnd, thetaDeg, nPer, scale, p)
%   ramps the unetched fraction ff from ffStart to ffEnd over nPer periods
%   (a weak start and stronger end shape the emitted beam toward the
%   fiber's Gaussian). Each period satisfies the local Bragg condition
%       period_k = scale * lambda0 / (neff_k - nClad sin(theta)),
%   neff_k = ff_k n_full + (1 - ff_k) n_etched  (TE0 slab indices of the
%   unetched and etched cross-sections). scale (~1) absorbs the error of
%   this effective-index estimate. p: the gratingCouplerTE parameters.
% (Protected file: the implementation is distributed as P-code.)
