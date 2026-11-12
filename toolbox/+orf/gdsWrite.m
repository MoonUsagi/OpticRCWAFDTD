function gdsWrite(file, cells, opts)
%GDSWRITE Write a GDSII stream file (polygons and cell references).
%   orf.gdsWrite(file, cells) writes a GDSII library. cells is a struct
%   array, one element per cell (structure), with fields
%     name     : cell name (letters, digits, _ ; at most 32 characters)
%     polygons : cell array of N x 2 vertex lists [x y] in um (open or
%                closed; closed automatically; at most 8190 vertices)
%     layers   : layer number per polygon (scalar or vector), 0-255
%     datatype : datatype per polygon (default 0)
%     paths    : optional struct array of PATH elements (waveguides, wires)
%                with fields xy (K x 2 centre line, um), width (um) and
%                optionally layer, datatype, pathtype (0 flush ends,
%                1 round, 2 square ends extended by width/2)
%     refs     : optional struct array with fields cell (name of another
%                cell) and xy (K x 2 placements in um) -> SREF records
%   The last cell is usually the top cell that references the others.
%
%   Options: DbUnit (database unit in um, default 1e-3 = 1 nm), LibName,
%   Date (datetime written to the header, default now).
%   Coordinates are rounded to the database grid. No external tools or
%   toolboxes are needed; the format follows the GDSII stream format 6.
arguments
    file (1,1) string
    cells struct
    opts.DbUnit (1,1) double {mustBePositive} = 1e-3
    opts.LibName (1,1) string = "ORF"
    opts.Date (1,1) datetime = datetime('now')
end
fid = fopen(file, 'w', 'ieee-be');
assert(fid > 0, 'orf:gdsWrite:open', 'Cannot open %s for writing.', file);
closer = onCleanup(@() fclose(fid));
dt = opts.Date;
stamp = int16([year(dt) month(dt) day(dt) hour(dt) minute(dt) floor(second(dt))]);

rec(fid, 0x0002, int16(600));                                   % HEADER, version 600
rec(fid, 0x0102, [stamp stamp]);                                % BGNLIB
rec(fid, 0x0206, opts.LibName);                                 % LIBNAME
rec(fid, 0x0305, [orf.gdsReal8(opts.DbUnit), orf.gdsReal8(opts.DbUnit * 1e-6)]);  % UNITS
toDb = @(xy) int32(round(xy / opts.DbUnit));
for c = 1:numel(cells)
    cl = cells(c);
    assert(~isempty(regexp(cl.name, '^[A-Za-z0-9_]{1,32}$', 'once')), 'orf:gdsWrite:name', ...
        'Cell name "%s" must be 1-32 letters, digits or _.', cl.name);
    rec(fid, 0x0502, [stamp stamp]);                            % BGNSTR
    rec(fid, 0x0606, string(cl.name));                          % STRNAME
    polys = getf(cl, 'polygons', {});
    nP = numel(polys);
    layers = expand(getf(cl, 'layers', 0), nP);
    dtypes = expand(getf(cl, 'datatype', 0), nP);
    for p = 1:nP
        xy = toDb(polys{p});
        if any(xy(1, :) ~= xy(end, :)), xy(end+1, :) = xy(1, :); end   %#ok<AGROW> close
        assert(size(xy, 1) >= 4 && size(xy, 1) <= 8191, 'orf:gdsWrite:vertices', ...
            'Polygon %d of cell %s has %d vertices (3 to 8190 allowed).', p, cl.name, size(xy, 1) - 1);
        rec(fid, 0x0800, []);                                   % BOUNDARY
        rec(fid, 0x0D02, int16(layers(p)));                     % LAYER
        rec(fid, 0x0E02, int16(dtypes(p)));                     % DATATYPE
        rec(fid, 0x1003, reshape(xy.', 1, []));                 % XY
        rec(fid, 0x1100, []);                                   % ENDEL
    end
    paths = getf(cl, 'paths', struct('xy', {}, 'width', {}));
    for p = 1:numel(paths)
        pa = paths(p);
        rec(fid, 0x0900, []);                                   % PATH
        rec(fid, 0x0D02, int16(getf(pa, 'layer', 0)));          % LAYER
        rec(fid, 0x0E02, int16(getf(pa, 'datatype', 0)));       % DATATYPE
        rec(fid, 0x2102, int16(getf(pa, 'pathtype', 0)));       % PATHTYPE
        rec(fid, 0x0F03, toDb(pa.width));                       % WIDTH
        rec(fid, 0x1003, reshape(toDb(pa.xy).', 1, []));        % XY
        rec(fid, 0x1100, []);                                   % ENDEL
    end
    refs = getf(cl, 'refs', struct('cell', {}, 'xy', {}));
    for r = 1:numel(refs)
        pts = toDb(refs(r).xy);
        for k = 1:size(pts, 1)
            rec(fid, 0x0A00, []);                               % SREF
            rec(fid, 0x1206, string(refs(r).cell));             % SNAME
            rec(fid, 0x1003, pts(k, :));                        % XY
            rec(fid, 0x1100, []);                               % ENDEL
        end
    end
    rec(fid, 0x0700, []);                                       % ENDSTR
end
rec(fid, 0x0400, []);                                           % ENDLIB
end

function rec(fid, typ, data)
%REC One record: 2-byte length, 1-byte record type, 1-byte data type, data.
if isstring(data) || ischar(data)
    bytes = uint8(char(data));
    if mod(numel(bytes), 2), bytes(end+1) = 0; end              % pad strings to even length
    payload = bytes;
elseif isa(data, 'uint8')
    payload = data;                                             % already big-endian bytes
elseif isempty(data)
    payload = uint8([]);
else
    payload = typecast(swapbytes(data(:).'), 'uint8');         % int16 / int32, big-endian
end
fwrite(fid, uint16(4 + numel(payload)), 'uint16');
fwrite(fid, uint16(typ), 'uint16');
fwrite(fid, payload, 'uint8');
end

function v = getf(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
end

function v = expand(v, n)
if isscalar(v), v = repmat(v, 1, n); end
assert(numel(v) == n, 'orf:gdsWrite:layers', 'Need one layer/datatype per polygon.');
end
