function layers = slantedLayers(thickness, background, shape, sidewallDeg, opts)
%SLANTEDLAYERS Staircase of layers for a structure with sloped sidewalls.
%   layers = orf.slantedLayers(h, background, shape, sidewallDeg) splits a
%   layer of height h into NSlices sublayers whose cross-section grows or
%   shrinks with height: every edge moves inward by h' cot(sidewallDeg)
%   at a height h' above the base, so 90 deg is vertical and e.g. 85 deg
%   narrows the top of a pillar (or widens the top of a hole, if shape is
%   a hole's background-coloured cut-out). shape (circle, rect or polygon)
%   is the cross-section at the base; each slice uses its mid-height.
%   Returns a cell array of layers ordered like makeStructure (incident
%   side first): splice it in with {layersAbove{:}, layers{:}, ...}.
%
%   Options:
%     NSlices (default 8): RCWA converges as 1/NSlices^2 in the staircase
%     Base "bottom" (default, substrate side = the last layer) or "top"
%       (incident side), e.g. "top" for pillars on a glass substrate lit
%       from the glass
arguments
    thickness (1,1) double {mustBePositive}
    background (1,1) struct
    shape (1,1) struct
    sidewallDeg (1,1) double {mustBeInRange(sidewallDeg, 1, 179)}
    opts.NSlices (1,1) double {mustBeInteger, mustBePositive} = 8
    opts.Base (1,1) string {mustBeMember(opts.Base, ["bottom", "top"])} = "bottom"
end
N = opts.NSlices;
dh = thickness / N;
zMid = ((1:N) - 0.5) * dh;                    % from the incident side
if opts.Base == "bottom"
    above = thickness - zMid;                 % height above the base
else
    above = zMid;
end
inset = above * cotd(sidewallDeg);
layers = cell(1, N);
for k = 1:N
    s = shrink(shape, inset(k));
    layers{k} = orf.makeLayer(dh, background, s);
end
end

function c = shrink(s, d)
% cross-section with every edge moved inward by d (outward if d < 0);
% returns {} when nothing is left
c = {};
switch s.type
    case "circle"
        if s.radius - d > 0, c = {orf.shapeCircle(s.radius - d, s.mat, s.center)}; end
    case "rect"
        sz = s.size - 2 * d;
        if all(sz > 0), c = {orf.shapeRect(sz(1), sz(2), s.mat, s.center)}; end
    case "polygon"
        p = polybuffer(polyshape(s.vertices, 'Simplify', false), -d, 'JointType', 'miter');
        if p.NumRegions == 1 && area(p) > 0
            c = {orf.shapePolygon(p.Vertices, s.mat, s.center)};
        elseif p.NumRegions > 1
            error('orf:slantedLayers:split', 'The polygon splits into pieces at this sidewall angle.');
        end
    otherwise
        error('orf:slantedLayers:shape', 'Unsupported shape "%s".', s.type);
end
end
