function [design, info] = loadDesign(file)
%LOADDESIGN Read a design saved by orf.saveDesign.
%   design = orf.loadDesign(file) rebuilds materials and shapes, so the
%   result can go straight into the solvers. [design, info] also returns
%   info.orfVersion and info.saved (the time stamp in the file).
%   Text values come back as strings, 1-D numeric arrays as row vectors.
arguments
    file (1,1) string
end
doc = jsondecode(fileread(file));
assert(isstruct(doc) && isfield(doc, 'format') && strcmp(doc.format, 'orf-design'), ...
    'orf:loadDesign:format', '%s is not an orf design file.', file);
design = decode(doc.design);
info = struct('orfVersion', string(doc.orfVersion), 'saved', string(doc.saved));
end

function v = decode(v)
if isstruct(v) && isscalar(v)
    if isfield(v, 'orfMaterial')
        v = decodeMaterial(v);
    elseif isfield(v, 'orfShape')
        v = decodeShape(v);
    elseif isfield(v, 'orfCell')
        v = decodeCell(v.orfCell, v.items);
    elseif isequal(sort(fieldnames(v)), {'im'; 're'})
        v = complex(row(v.re), row(v.im));
        if isvector(v), v = row(v); end
    else
        f = fieldnames(v);
        for k = 1:numel(f)
            v.(f{k}) = decode(v.(f{k}));
        end
    end
elseif isstruct(v)                       % struct array (same fields)
    c = arrayfun(@decode, v, 'UniformOutput', false);
    v = reshape([c{:}], size(v));
elseif iscellstr(v)                     % a string array was saved
    v = reshape(string(v), 1, []);
elseif iscell(v)
    v = cellfun(@decode, v, 'UniformOutput', false);
elseif ischar(v)
    v = string(v);
elseif isnumeric(v) || islogical(v)
    v = row(v);
end
end

function c = decodeCell(n, items)
% jsondecode merges a list of like items into a struct array or matrix
if n == 0
    c = {};
elseif n == 1
    c = {decode(items)};
elseif iscell(items)
    c = reshape(cellfun(@decode, items, 'UniformOutput', false), 1, []);
elseif isstruct(items)
    c = reshape(arrayfun(@decode, items, 'UniformOutput', false), 1, []);
else                                     % numeric: one row per item
    c = arrayfun(@(k) decode(squeeze(items(k, :, :))), 1:n, 'UniformOutput', false);
end
end

function v = row(v)
if isvector(v), v = reshape(v, 1, []); end
end

function m = decodeMaterial(s)
s.name = string(s.name);
switch string(s.orfMaterial)
    case "const"
        m = orf.materialConst(decode(s.n), s.name);
    case "library"
        m = orf.material(s.name);
    case "table"
        m = orf.materialTable(row(s.lambda), row(s.n), row(s.k), s.name);
    case "taucLorentz"
        p = s.params;
        m = orf.materialTaucLorentz(p.A, p.E0, p.C, p.Eg, p.epsInf, Name=s.name, Range=row(s.range));
    otherwise
        error('orf:loadDesign:material', 'Unknown material kind "%s".', s.orfMaterial);
end
end

function sh = decodeShape(s)
mat = decode(s.mat);
switch string(s.orfShape)
    case "rect"
        sz = row(s.size);
        sh = orf.shapeRect(sz(1), sz(2), mat, row(s.center));
    case "circle"
        sh = orf.shapeCircle(s.radius, mat, row(s.center));
    case "polygon"
        sh = orf.shapePolygon(reshape(s.vertices, [], 2), mat, row(s.center));
    otherwise
        error('orf:loadDesign:shape', 'Unknown shape "%s".', s.orfShape);
end
end
