function [eta, overlap] = fiberCoupling(res, theta, x0, w0)
%FIBERCOUPLING Grating-to-fiber efficiency from the upward DFT field.
%   [eta, overlap] = orf.fiberCoupling(res, theta, x0, w0) for a Gaussian
%   fiber mode of waist w0 [um] (SMF-28 at 1550 nm: MFD 10.4, w0 5.2)
%   centred at x0 and tilted by theta [rad] toward +x, in the cladding:
%     E_f(x) = exp(-((x - x0) cos(theta) / w0)^2) exp(i k nc sin(theta) (x - x0))
%   overlap = |int E_up E_f^*|^2 / (int |E_up|^2 int |E_f|^2)  (scalar)
%   eta     = overlap * Pup   (fractions of the incident power, 1 x nLambda)
%   theta and x0 may be vectors: outputs are numel(theta) x numel(x0) x nL.
arguments
    res (1,1) struct
    theta (:,1) double
    x0 (1,:) double
    w0 (1,1) double {mustBePositive}
end
x = res.xUp(:);
nL = numel(res.lambdas);
eta = zeros(numel(theta), numel(x0), nL);
overlap = eta;
for l = 1:nL
    E = res.EyUp(:, l);
    k = 2*pi * res.nClad / res.lambdas(l);
    for i = 1:numel(theta)
        for j = 1:numel(x0)
            u = x - x0(j);
            Ef = exp(-(u * cos(theta(i)) / w0).^2) .* exp(1i * k * sin(theta(i)) * u);
            overlap(i, j, l) = abs(Ef' * E)^2 / (real(E' * E) * real(Ef' * Ef));
        end
    end
    eta(:, :, l) = overlap(:, :, l) * res.Pup(l);
end
end
