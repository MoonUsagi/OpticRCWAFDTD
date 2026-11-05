function m = focusMetrics(U, dx, lambda0, NA, Pin)
%FOCUSMETRICS Spot size and focusing efficiency in the focal plane.
%   m = orf.focusMetrics(U, dx, lambda0, NA, Pin) for a focal-plane field U
%   (square grid, spacing dx, lens axis at the array centre) returns:
%   m.fwhm        : FWHM of |U|^2 along x through the peak [um]
%   m.fwhmLimit   : diffraction limit lambda0 / (2 NA) [um]
%   m.efficiency  : power inside radius 1.5 x FWHM (a 3 x FWHM disk)
%                   divided by Pin, the incident power on the aperture
%   m.peak        : peak |U|^2
%   Powers are integrals of n |U|^2 dA in the medium of U (n = 1 here).
I = abs(U).^2;
[ny, nx] = size(I);
[m.peak, k] = max(I(:));
[iy, ix] = ind2sub(size(I), k);
line = I(iy, :);
half = m.peak / 2;
left = find(line(1:ix) < half, 1, 'last');
right = ix - 1 + find(line(ix:end) < half, 1, 'first');
xl = left + (half - line(left)) / (line(left+1) - line(left));     % linear interp
xr = right - 1 + (half - line(right-1)) / (line(right) - line(right-1));
m.fwhm = (xr - xl) * dx;
m.fwhmLimit = lambda0 / (2 * NA);
[X, Y] = meshgrid(((1:nx) - ix) * dx, ((1:ny) - iy) * dx);
m.efficiency = sum(I(X.^2 + Y.^2 <= (1.5 * m.fwhm)^2)) * dx^2 / Pin;
end
