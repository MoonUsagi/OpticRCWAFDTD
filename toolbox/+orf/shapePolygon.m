function s = shapePolygon(xy, mat, center)
%SHAPEPOLYGON Polygonal cross-section inside a layer's unit cell.
%   s = orf.shapePolygon(xy, mat) with vertices xy (K x 2, [um], either
%   orientation, not closed) relative to center (default [0 0]). The
%   polygon must fit in one unit cell around its centre. Use it for
%   rotated, L-shaped or imported (orf.gdsRead) cross-sections.
arguments
    xy (:,2) double
    mat (1,1) struct
    center (1,2) double = [0 0]
end
assert(size(xy, 1) >= 3, 'orf:shapePolygon:vertices', 'A polygon needs at least 3 vertices.');
s.type = "polygon";
s.mat = mat;
s.center = center;
s.vertices = xy;
s.inside = @(dx, dy) reshape(inpolygon(dx(:), dy(:), xy(:, 1), xy(:, 2)), size(dx));
end
