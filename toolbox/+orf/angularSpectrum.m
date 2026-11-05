function U = angularSpectrum(U0, dx, lambda0, z, opts)
%ANGULARSPECTRUM Exact scalar propagation of a sampled field by distance z.
%   U = orf.angularSpectrum(U0, dx, lambda0, z) propagates U0 (Ny x Nx,
%   spacing dx [um]) through a uniform medium of index n (option N,
%   default 1) and returns the field on the same grid. e^{-iwt}:
%   U(z) = IFFT{ FFT{U0} exp(i kz z) }, kz on the kzBranch branch, so
%   evanescent components decay. Option Pad (default 2) zero-pads each
%   dimension by that factor to suppress wrap-around.
arguments
    U0 (:,:) double
    dx (1,1) double {mustBePositive}
    lambda0 (1,1) double {mustBePositive}
    z (1,1) double
    opts.N (1,1) double = 1
    opts.Pad (1,1) double {mustBeGreaterThanOrEqual(opts.Pad, 1)} = 2
end
[ny, nx] = size(U0);
Ny = ceil(opts.Pad * ny); Nx = ceil(opts.Pad * nx);
k = 2*pi * opts.N / lambda0;
kx = 2*pi * fftFreq(Nx, dx);
ky = 2*pi * fftFreq(Ny, dx);
kz = orf.kzBranch(k^2 - kx.^2 - ky.'.^2);       % Ny x Nx, FFT order
U = ifft2(fft2(U0, Ny, Nx) .* exp(1i * kz * z));
U = U(1:ny, 1:nx);                           % zero padding sits after the data
end

function f = fftFreq(N, dx)
%FFTFREQ Spatial frequencies [1/um] in FFT order.
f = [0:ceil(N/2)-1, -floor(N/2):-1] / (N * dx);
end
