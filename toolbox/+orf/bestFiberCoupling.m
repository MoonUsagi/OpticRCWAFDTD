%BESTFIBERCOUPLING Best fiber position/angle for a grating-coupler run.
%   b = orf.bestFiberCoupling(res, thetaDeg, w0) scans the fiber tilt over
%   thetaDeg (e.g. 5:0.5:15, the range allowed by the package) and its
%   centre over the grating, maximising the coupling at the design
%   wavelength res.params.lambda0. w0 defaults to 5.2 um (SMF-28, 1550 nm).
%   b.eta, b.dB : coupling at lambda0;  b.theta [deg], b.x0 [um]
%   b.spectrum  : coupling vs res.lambdas at that fiber position
%   b.band1dB   : [min max] sampled wavelengths within 1 dB of the peak
% (Protected file: the implementation is distributed as P-code.)
