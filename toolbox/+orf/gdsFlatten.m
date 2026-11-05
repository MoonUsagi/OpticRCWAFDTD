function [polys, layers, datatypes] = gdsFlatten(lib, cellName, opts)
%GDSFLATTEN All polygons of a GDSII cell in absolute coordinates.
%   [polys, layers, datatypes] = orf.gdsFlatten(lib, cellName) expands the
%   cell's references (SREF, AREF; reflection, magnification and rotation
%   applied in the GDSII order) recursively. lib comes from orf.gdsRead;
%   cellName defaults to the top cell (the one nobody references).
%   polys is a cell array of K x 2 vertex lists [um].
%   Options: Layer, Datatype (keep only these numbers; [] = all).
arguments
    lib (1,1) struct
    cellName (1,1) string = ""
    opts.Layer double = []
    opts.Datatype double = []
end
names = [lib.cells.name];
if cellName == ""
    used = [arrayfun(@(c) [c.refs.cell], lib.cells, 'UniformOutput', false), ...
            arrayfun(@(c) [c.arefs.cell], lib.cells, 'UniformOutput', false)];
    used = [strings(1, 0), used{:}];
    top = names(~ismember(names, used));
    assert(isscalar(top), 'orf:gdsFlatten:top', ...
        'The file has %d top cells (%s); name one.', numel(top), strjoin(top, ', '));
    cellName = top;
end
[polys, layers, datatypes] = expand(lib, names, cellName, eye(2), [0 0], 0);
keep = true(size(layers));
if ~isempty(opts.Layer), keep = keep & ismember(layers, opts.Layer); end
if ~isempty(opts.Datatype), keep = keep & ismember(datatypes, opts.Datatype); end
polys = polys(keep); layers = layers(keep); datatypes = datatypes(keep);
end

function [P, L, D] = expand(lib, names, name, A, t, depth)
% A, t: affine map x -> x * A.' + t (row vectors) accumulated from the top
assert(depth < 64, 'orf:gdsFlatten:recursion', 'Reference depth > 64 (recursive cells?).');
k = find(names == name, 1);
assert(~isempty(k), 'orf:gdsFlatten:missing', 'Cell "%s" not found.', name);
c = lib.cells(k);
P = cellfun(@(xy) xy * A.' + t, c.polygons, 'UniformOutput', false);
L = c.layers; D = c.datatypes;
for r = c.refs
    [A2, t2] = compose(A, t, r, r.xy);
    [p, l, d] = expand(lib, names, r.cell, A2, t2, depth + 1);
    P = [P, p]; L = [L, l]; D = [D, d]; %#ok<AGROW>
end
for r = c.arefs
    colStep = (r.xy(2, :) - r.xy(1, :)) / r.cols;
    rowStep = (r.xy(3, :) - r.xy(1, :)) / r.rows;
    for i = 0:r.cols - 1
        for j = 0:r.rows - 1
            [A2, t2] = compose(A, t, r, r.xy(1, :) + i * colStep + j * rowStep);
            [p, l, d] = expand(lib, names, r.cell, A2, t2, depth + 1);
            P = [P, p]; L = [L, l]; D = [D, d]; %#ok<AGROW>
        end
    end
end
end

function [A2, t2] = compose(A, t, r, origin)
% GDSII: reflect about x, then magnify, then rotate, then translate
F = diag([1, 1 - 2 * r.reflect]);
R = [cosd(r.angle), -sind(r.angle); sind(r.angle), cosd(r.angle)];
Aloc = r.mag * R * F;
A2 = A * Aloc;
t2 = origin * A.' + t;
end
