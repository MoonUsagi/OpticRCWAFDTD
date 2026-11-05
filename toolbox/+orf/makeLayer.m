function layer = makeLayer(thickness, background, shapes)
%MAKELAYER One z-uniform layer: a background material plus shapes.
%   Shapes are painted in order, so later shapes cover earlier ones.
%   A layer with no shapes is homogeneous (handled analytically by
%   TMM and RCWA).
arguments
    thickness (1,1) double {mustBeNonnegative}
    background (1,1) struct
    shapes cell = {}
end
layer.thickness = thickness;
layer.background = background;
layer.shapes = shapes;
end
