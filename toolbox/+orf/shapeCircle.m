function s = shapeCircle(r, mat, center)
%SHAPECIRCLE Circular pillar cross-section inside a layer's unit cell.
arguments
    r (1,1) double {mustBePositive}
    mat (1,1) struct
    center (1,2) double = [0 0]
end
s.type = "circle";
s.mat = mat;
s.center = center;
s.radius = r;
s.inside = @(dx, dy) dx.^2 + dy.^2 < r^2;
end
