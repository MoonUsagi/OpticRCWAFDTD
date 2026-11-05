function epsGrid = layerEps(layer, period, x, y, lambda0, nSub)
%LAYEREPS Sample a layer's relative permittivity on a grid.
%   epsGrid = orf.layerEps(layer, period, x, y, lambda0) returns a
%   numel(x) x numel(y) complex array (x along dim 1, ndgrid layout).
%   Shapes wrap periodically when the period is finite.
%
%   nSub > 1 averages eps over nSub x nSub sub-samples per cell, using
%   the uniform spacing of x and y as the cell size. This is a plain
%   arithmetic average for anti-aliasing; the anisotropic subpixel
%   averaging FDTD needs comes in Phase 3.
arguments
    layer (1,1) struct
    period (1,2) double {mustBePositive}
    x (:,1) double
    y (:,1) double
    lambda0 (1,1) double {mustBePositive}
    nSub (1,1) double {mustBeInteger, mustBePositive} = 1
end
offX = subOffsets(x, nSub);
offY = subOffsets(y, nSub);
epsGrid = complex(zeros(numel(x), numel(y)));
for ox = offX
    for oy = offY
        [X, Y] = ndgrid(x + ox, y + oy);
        epsGrid = epsGrid + paint(layer, period, X, Y, lambda0);
    end
end
epsGrid = complex(epsGrid / (numel(offX) * numel(offY)));   % keep complex type
end

function e = paint(layer, period, X, Y, lambda0)
e = complex(layer.background.nk(lambda0)^2 * ones(size(X)));
for k = 1:numel(layer.shapes)
    s = layer.shapes{k};
    mask = s.inside(wrap(X - s.center(1), period(1)), wrap(Y - s.center(2), period(2)));
    e(mask) = s.mat.nk(lambda0)^2;
end
end

function d = wrap(d, L)
%WRAP Map a displacement into [-L/2, L/2) for periodic shapes.
if isfinite(L)
    d = mod(d + L/2, L) - L/2;
end
end

function off = subOffsets(v, nSub)
%SUBOFFSETS Sub-sample offsets within a cell centred on each point.
if nSub == 1 || numel(v) < 2
    off = 0;
    return
end
h = v(2) - v(1);
off = ((1:nSub) - (nSub + 1)/2) * h / nSub;
end
