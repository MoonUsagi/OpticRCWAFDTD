function s = shapeRect(wx, wy, mat, center)
%SHAPERECT Axis-aligned rectangle inside a layer's unit cell.
%   s = orf.shapeRect(wx, wy, mat) is centred at the origin; pass center
%   [cx cy] to move it. Use wy = Inf for a 1D grating line along y.
arguments
    wx (1,1) double {mustBePositive}
    wy (1,1) double {mustBePositive}
    mat (1,1) struct
    center (1,2) double = [0 0]
end
s.type = "rect";
s.mat = mat;
s.center = center;
s.size = [wx wy];                          % lets RCWA align its sample grid to the edges
s.inside = @(dx, dy) abs(dx) < wx/2 & abs(dy) < wy/2;
end
