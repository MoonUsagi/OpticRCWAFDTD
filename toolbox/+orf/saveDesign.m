function saveDesign(file, design)
%SAVEDESIGN Save a design (structure, materials, parameters) as a JSON file.
%   orf.saveDesign(file, design) writes any struct (or cell / value) built
%   from numbers, strings, logicals, structs and cells -- e.g. a
%   makeStructure device, a simulation parameter struct, or a struct
%   holding both -- to a human-readable JSON file. orf.loadDesign reads it
%   back into working objects.
%
%   Materials are stored as their recipe (constant index, built-in name,
%   n,k table or Tauc-Lorentz parameters) and shapes by their dimensions,
%   so loading rebuilds them exactly. Complex numbers become {"re","im"},
%   cell arrays {"orfCell": n, "items": [...]};
%   Inf and NaN are written as Infinity / NaN (read by MATLAB and Python).
%   Function handles other than material dispersion cannot be saved.
%
%   Example:
%     dev = orf.makeStructure([0.4 0.4], orf.material("SiO2"), orf.material("air"), ...
%         {orf.makeLayer(0.5, orf.material("air"), {orf.shapeCircle(0.1, orf.materialConst(3.6))})});
%     orf.saveDesign("cell.json", struct('device', dev, 'lambda0', 0.94, 'N', 8));
%     d = orf.loadDesign("cell.json");  out = orf.rcwa2D(d.device, d.lambda0, 0, 0, "s", Nx=d.N);
arguments
    file (1,1) string
    design
end
doc = struct('format', "orf-design", 'orfVersion', orf.version, ...
    'saved', string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
    'design', encode(design, "design"));
txt = jsonencode(doc, PrettyPrint=true, ConvertInfAndNaN=false);
fid = fopen(file, 'w', 'n', 'UTF-8');
assert(fid > 0, 'orf:saveDesign:open', 'Cannot write %s.', file);
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, txt, 'char');
end

function v = encode(v, where)
if isstruct(v)
    if isfield(v, 'nk')                                   % material
        assert(isfield(v, 'spec'), 'orf:saveDesign:material', ...
            '%s: material "%s" has no recipe (build it with orf.material*).', where, v.name);
        v = encode(v.spec, where);
    elseif isfield(v, 'inside')                           % shape
        v = encodeShape(v, where);
    elseif isscalar(v)
        f = fieldnames(v);
        for k = 1:numel(f)
            v.(f{k}) = encode(v.(f{k}), where + "." + f{k});
        end
    else
        v = arrayfun(@(e) encode(e, where), v, 'UniformOutput', false);
    end
elseif iscell(v)                    % JSON cannot tell a cell from a struct array
    items = cellfun(@(e) encode(e, where), v(:).', 'UniformOutput', false);
    if isscalar(items), items = items{1}; end
    v = struct('orfCell', numel(v), 'items', {items});
elseif isnumeric(v) && ~isreal(v)
    v = struct('re', real(v), 'im', imag(v));
elseif isa(v, 'function_handle')
    error('orf:saveDesign:handle', '%s: function handles cannot be saved.', where);
end
end

function s = encodeShape(v, where)
switch v.type
    case "rect"
        s = struct('orfShape', "rect", 'size', v.size, 'center', v.center);
    case "circle"
        s = struct('orfShape', "circle", 'radius', v.radius, 'center', v.center);
    case "polygon"
        s = struct('orfShape', "polygon", 'vertices', v.vertices, 'center', v.center);
    otherwise
        error('orf:saveDesign:shape', '%s: unknown shape type "%s".', where, v.type);
end
s.mat = encode(v.mat, where + ".mat");
end
