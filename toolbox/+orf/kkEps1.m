function e1 = kkEps1(eps2fn, Emin, E)
%KKEPS1 Real part of a permittivity from its imaginary part (Kramers-Kronig).
%   e1 = orf.kkEps1(eps2fn, Emin, E) returns
%       (2/pi) P int_{Emin}^{Inf} xi eps2(xi) / (xi^2 - E^2) dxi
%   at photon energies E (eV), for eps2fn(xi) = 0 below Emin. The
%   principal value is handled by subtracting the singular part,
%       int [xi eps2(xi) - E eps2(E)] / (xi^2 - E^2) dxi
%     + E eps2(E) * ln|(Emin + E) / (Emin - E)| / (2E),
%   so the remaining integrand is smooth and integral() converges.
%   Add the high-frequency constant (eps_inf) yourself.
arguments
    eps2fn (1,1) function_handle
    Emin (1,1) double {mustBeNonnegative}
    E double {mustBePositive}
end
e1 = zeros(size(E));
for k = 1:numel(E)
    Ek = E(k);
    s = Ek * eps2fn(Ek);                           % singular-part weight
    h = 1e-6 * max(Ek, 1);
    slope = ((Ek + h) * eps2fn(Ek + h) - (Ek - h) * eps2fn(Ek - h)) / (2*h);
    g = @(xi) smoothPart(xi, Ek, s, slope, eps2fn);
    if Ek > Emin
        I = integral(g, Emin, Ek, 'RelTol', 1e-10, 'AbsTol', 1e-12) + ...
            integral(g, Ek, Inf, 'RelTol', 1e-10, 'AbsTol', 1e-12);
    else
        I = integral(g, Emin, Inf, 'RelTol', 1e-10, 'AbsTol', 1e-12);
    end
    if s ~= 0 && Emin ~= Ek
        I = I + s * log(abs((Emin + Ek) / (Emin - Ek))) / (2 * Ek);
    end
    e1(k) = 2/pi * I;
end
end

function v = smoothPart(xi, E, s, slope, eps2fn)
v = (xi .* eps2fn(xi) - s) ./ (xi.^2 - E^2);
near = abs(xi - E) < 1e-9 * max(E, 1);
v(near) = slope / (2 * E);                         % removable singularity
end
