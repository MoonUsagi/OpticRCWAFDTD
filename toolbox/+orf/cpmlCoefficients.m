%CPMLCOEFFICIENTS Convolutional PML (Roden & Gedney 2000) update coefficients.
%   [b, a, kappa] = orf.cpmlCoefficients(u, uLo, uHi, d, S) for positions u
%   [um]; the PML occupies u < uLo and u > uHi, each of thickness d. S is
%   the normalised time step c0*dt [um]. Inside the PML a derivative
%   becomes du/kappa + psi with psi <- b.*psi + a.*du.
%   Grading: sigma' = sigmaMax (depth/d)^m with sigmaMax = 0.8(m+1)/dx
%   (sigma' = sigma*eta0, 1/um), kappa = 1 + (kappaMax-1)(depth/d)^m,
%   alpha' = alphaMax (1 - depth/d). Stretching s = kappa + sigma'/(alpha' - i k).
% (Protected file: the implementation is distributed as P-code.)
