function phi = targetPhaseHyperbolic(x, y, f, lambda0, n)
%TARGETPHASEHYPERBOLIC Phase that focuses a normal plane wave to (0,0,f).
%   phi = 2*pi*n/lambda0 * (f - sqrt(x.^2 + y.^2 + f^2)), for e^{-iwt}
%   (a converging spherical wave exp(-i k R)). n is the index of the
%   medium between lens and focus (default 1). x, y broadcast.
arguments
    x double
    y double
    f (1,1) double {mustBePositive}
    lambda0 (1,1) double {mustBePositive}
    n (1,1) double = 1
end
phi = 2*pi*n/lambda0 * (f - sqrt(x.^2 + y.^2 + f^2));
end
