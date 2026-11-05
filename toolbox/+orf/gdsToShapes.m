function shapes = gdsToShapes(polys, mat, origin)
%GDSTOSHAPES Turn imported GDSII polygons into RCWA layer shapes.
%   shapes = orf.gdsToShapes(polys, mat) makes one orf.shapePolygon per
%   polygon (e.g. from orf.gdsFlatten), centred on its vertex mean so it
%   wraps correctly in a periodic cell. origin [x y] (default [0 0]) is
%   subtracted first: pass the unit-cell centre of the layout.
%   Example (one unit cell of an imported layout, pillar layer 1):
%     lib = orf.gdsRead("cell.gds");
%     polys = orf.gdsFlatten(lib, Layer=1);
%     layer = orf.makeLayer(0.6, orf.material("air"), orf.gdsToShapes(polys, aSi));
arguments
    polys cell
    mat (1,1) struct
    origin (1,2) double = [0 0]
end
shapes = cell(1, numel(polys));
for k = 1:numel(polys)
    xy = polys{k} - origin;
    c = mean(xy, 1);
    shapes{k} = orf.shapePolygon(xy - c, mat, c);
end
end
