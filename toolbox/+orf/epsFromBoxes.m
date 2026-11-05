function epsGrid = epsFromBoxes(x, z, nBackground, boxes, nSub)
%EPSFROMBOXES Cell-averaged permittivity of axis-aligned boxes on an xz grid.
%   epsGrid = orf.epsFromBoxes(x, z, nBg, boxes) returns numel(x) x numel(z).
%   boxes is K x 5: [x1 x2 z1 z2 n] per row (+-Inf allowed, e.g. a
%   waveguide running through the PML); later rows paint over earlier.
%   Each grid point stands for a cell of the grid spacing; eps is the
%   arithmetic average over nSub x nSub sub-samples (default 4), which is
%   exact for TE (E_y tangential to every box edge).
arguments
    x (:,1) double
    z (:,1) double
    nBackground (1,1) double
    boxes (:,5) double
    nSub (1,1) double {mustBeInteger, mustBePositive} = 4
end
dx = x(2) - x(1); dz = z(2) - z(1);
off = ((1:nSub) - (nSub + 1)/2) / nSub;
epsGrid = zeros(numel(x), numel(z));
for ox = off
    for oz = off
        [X, Z] = ndgrid(x + ox*dx, z + oz*dz);
        e = nBackground^2 * ones(size(X));
        for k = 1:size(boxes, 1)
            b = boxes(k, :);
            e(X >= b(1) & X < b(2) & Z >= b(3) & Z < b(4)) = b(5)^2;
        end
        epsGrid = epsGrid + e;
    end
end
epsGrid = epsGrid / nSub^2;
end
