function lib = gdsRead(file)
%GDSREAD Read a GDSII stream file.
%   lib = orf.gdsRead(file) returns
%     lib.name, lib.dbUnit (database unit [um]), lib.cells (struct array):
%       name, polygons (cell of K x 2 [um], not closed), layers, datatypes,
%       refs  (struct array: cell, xy [1 x 2], angle [deg], mag, reflect)
%       arefs (struct array: cell, cols, rows, xy [3 x 2] = origin, column
%              end, row end), angle, mag, reflect)
%   BOUNDARY and BOX elements become polygons. PATH, TEXT and NODE
%   elements are skipped (a warning counts skipped paths). Use
%   orf.gdsFlatten to get every polygon of a cell in absolute coordinates.
arguments
    file (1,1) string
end
fid = fopen(file, 'r', 'ieee-be');
assert(fid > 0, 'orf:gdsRead:open', 'Cannot open %s.', file);
raw = fread(fid, Inf, '*uint8').';
fclose(fid);

lib = struct('name', "", 'dbUnit', 1e-3, 'cells', struct('name', {}, 'polygons', {}, ...
    'layers', {}, 'datatypes', {}, 'refs', {}, 'arefs', {}));
cellNow = []; el = []; nPath = 0; scale = 1e-3;
pos = 1;
while pos + 3 <= numel(raw)
    len = double(raw(pos)) * 256 + double(raw(pos + 1));
    assert(len >= 4 && pos + len - 1 <= numel(raw), 'orf:gdsRead:corrupt', ...
        'Corrupt record at byte %d.', pos);
    typ = raw(pos + 2);                                 % other record types are ignored
    data = raw(pos + 4 : pos + len - 1);
    pos = pos + len;
    switch typ
        case 0x02                                       % LIBNAME
            lib.name = ascii(data);
        case 0x03                                       % UNITS: user/db, db in m
            u = real8(data);
            scale = u(2) * 1e6;                         % database unit in um
            lib.dbUnit = scale;
        case 0x05                                       % BGNSTR
            cellNow = struct('name', "", 'polygons', {{}}, 'layers', [], 'datatypes', [], ...
                'refs', struct('cell', {}, 'xy', {}, 'angle', {}, 'mag', {}, 'reflect', {}), ...
                'arefs', struct('cell', {}, 'cols', {}, 'rows', {}, 'xy', {}, 'angle', {}, ...
                'mag', {}, 'reflect', {}));
        case 0x06                                       % STRNAME
            cellNow.name = ascii(data);
        case 0x07                                       % ENDSTR
            lib.cells(end + 1) = cellNow;
        case {0x08, 0x2D}                               % BOUNDARY, BOX
            el = struct('kind', "poly", 'layer', 0, 'dt', 0, 'xy', [], 'name', "", ...
                'angle', 0, 'mag', 1, 'reflect', false, 'colrow', [1 1]);
        case 0x09                                       % PATH
            el = struct('kind', "path"); nPath = nPath + 1;
        case {0x0C, 0x15}                               % TEXT, NODE
            el = struct('kind', "skip");
        case 0x0A                                       % SREF
            el = struct('kind', "sref", 'layer', 0, 'dt', 0, 'xy', [], 'name', "", ...
                'angle', 0, 'mag', 1, 'reflect', false, 'colrow', [1 1]);
        case 0x0B                                       % AREF
            el = struct('kind', "aref", 'layer', 0, 'dt', 0, 'xy', [], 'name', "", ...
                'angle', 0, 'mag', 1, 'reflect', false, 'colrow', [1 1]);
        case 0x0D                                       % LAYER
            if isfield(el, 'layer'), el.layer = double(int16s(data)); end
        case {0x0E, 0x2E}                               % DATATYPE, BOXTYPE
            if isfield(el, 'dt'), el.dt = double(int16s(data)); end
        case 0x10                                       % XY
            if isfield(el, 'xy')
                v = double(int32s(data)) * scale;
                el.xy = reshape(v, 2, []).';
            end
        case 0x12                                       % SNAME
            if isfield(el, 'name'), el.name = ascii(data); end
        case 0x13                                       % COLROW
            if isfield(el, 'colrow'), el.colrow = double(int16s(data)); end
        case 0x1A                                       % STRANS
            if isfield(el, 'reflect'), el.reflect = bitand(data(1), 0x80) > 0; end
        case 0x1B                                       % MAG
            if isfield(el, 'mag'), el.mag = real8(data); end
        case 0x1C                                       % ANGLE
            if isfield(el, 'angle'), el.angle = real8(data); end
        case 0x11                                       % ENDEL
            if ~isempty(el), cellNow = addElement(cellNow, el); end
            el = [];
        case 0x04                                       % ENDLIB
            break
    end
end
if nPath > 0
    warning('orf:gdsRead:path', '%d PATH element(s) skipped; convert paths to polygons.', nPath);
end
end

function c = addElement(c, el)
switch el.kind
    case "poly"
        xy = el.xy;
        if size(xy, 1) > 1 && isequal(xy(1, :), xy(end, :)), xy(end, :) = []; end
        c.polygons{end + 1} = xy;
        c.layers(end + 1) = el.layer;
        c.datatypes(end + 1) = el.dt;
    case "sref"
        c.refs(end + 1) = struct('cell', el.name, 'xy', el.xy(1, :), 'angle', el.angle, ...
            'mag', el.mag, 'reflect', el.reflect);
    case "aref"
        c.arefs(end + 1) = struct('cell', el.name, 'cols', el.colrow(1), 'rows', el.colrow(2), ...
            'xy', el.xy(1:3, :), 'angle', el.angle, 'mag', el.mag, 'reflect', el.reflect);
end
end

function s = ascii(d)
s = string(char(d(d ~= 0)));
end

function v = int16s(d)
v = swapbytes(typecast(d, 'int16'));
end

function v = int32s(d)
v = swapbytes(typecast(d, 'int32'));
end

function v = real8(d)
% GDSII 8-byte real: sign, excess-64 base-16 exponent, 56-bit mantissa
d = double(reshape(d, 8, []));
sgn = 1 - 2 * (d(1, :) >= 128);
ex = mod(d(1, :), 128) - 64;
mant = (256.^(6:-1:0)) * d(2:8, :) / 2^56;
v = sgn .* mant .* 16.^ex;
end
