classdef TestGDS < matlab.unittest.TestCase
    %TESTGDS GDSII writer: spec byte patterns, read-back and layout geometry.
    %   The reader below is written from the GDSII stream format spec,
    %   independently of orf.gdsWrite.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function real8MatchesSpecBytes(tc)
            % UNITS of nearly every GDS file (1 nm grid): 1e-3 user units
            % per db unit, 1e-9 m per db unit. Bytes as seen in files.
            b = orf.gdsReal8(1e-3);
            tc.verifyEqual(b(1:7), uint8([0x3E 0x41 0x89 0x37 0x4B 0xC6 0xA7]));
            b = orf.gdsReal8(1e-9);
            tc.verifyEqual(b(1:7), uint8([0x39 0x44 0xB8 0x2F 0xA0 0x9B 0x5A]));
            for v = [1e-3, 1e-9, 1, 0.5, 16, -2.75, 123.456, 1e-12]
                tc.verifyEqual(decodeReal8(orf.gdsReal8(v)), v, 'RelTol', 1e-15);
            end
            tc.verifyEqual(orf.gdsReal8(0), zeros(1, 8, 'uint8'));
        end

        function roundTripPolygonsAndReferences(tc)
            f = [tempname '.gds'];
            cleanup = onCleanup(@() delete(f));
            tri = [0 0; 1.5 0; 0.75 1.234];
            cells = struct('name', {'A', 'TOP'}, ...
                'polygons', {{tri}, {[0 0; 2 0; 2 1; 0 1]}}, ...
                'layers', {7, 3}, 'datatype', {2, 0}, ...
                'refs', {[], struct('cell', 'A', 'xy', [10 20; -5.5 0.001])});
            orf.gdsWrite(f, cells, DbUnit=1e-3);
            g = readGDS(f);
            tc.verifyEqual(g.units, [1e-3 1e-9], 'RelTol', 1e-15);
            tc.verifyEqual({g.cells.name}, {'A', 'TOP'});
            a = g.cells(1);
            tc.verifyEqual(a.boundaries(1).layer, 7);
            tc.verifyEqual(a.boundaries(1).datatype, 2);
            tc.verifyEqual(a.boundaries(1).xy, [tri; tri(1, :)] * 1e3);   % closed, in db units
            t = g.cells(2);
            tc.verifyEqual({t.srefs.name}, {'A', 'A'});
            tc.verifyEqual(vertcat(t.srefs.xy), [10000 20000; -5500 1]);
        end

        function metalensLayoutGeometry(tc)
            f = [tempname '.gds'];
            cleanup = onCleanup(@() delete(f));
            D = [0.1 0.2 0; 0.2 0.25 0.1; 0 0.1 0.2];      % 3 x 3 sites, 7 pillars
            info = orf.metalensToGDS(f, D, 0.4, Vertices=64);
            tc.verifyEqual(info.nPillars, 7);
            tc.verifyEqual(info.nCells, 3);
            g = readGDS(f);
            top = g.cells(end);
            tc.verifyEqual(numel(top.srefs), 7);
            % a 0.2 um pillar at site (2,1) -> x = 0, y = -0.4
            names = {top.srefs.name}.'; xy = vertcat(top.srefs.xy);
            k = strcmp(names, 'PILLAR_200NM') & xy(:, 1) == 0 & xy(:, 2) == -400;
            tc.verifyEqual(nnz(k), 1);
            % equal-area polygons: area within 1e-4 of pi r^2 on a fine
            % grid (on the usual 1 nm grid, vertex rounding alone moves the
            % area of a 100 nm pillar by ~0.5 %)
            orf.metalensToGDS(f, D, 0.4, Vertices=64, DbUnit=1e-5);
            g = readGDS(f);
            for c = g.cells(1:end-1)
                d = sscanf(c.name, 'PILLAR_%dNM') * 1e-3;
                xyc = c.boundaries(1).xy * 1e-5;
                A = polyarea(xyc(:, 1), xyc(:, 2));
                tc.verifyEqual(A, pi * d^2 / 4, 'RelTol', 1e-4, c.name);
            end
        end

        function gratingLayoutGrooves(tc)
            f = [tempname '.gds'];
            cleanup = onCleanup(@() delete(f));
            [per, ff] = deal(linspace(0.59, 0.62, 25), linspace(0.875, 0.435, 25));
            info = orf.gratingToGDS(f, per, ff, Width=12);
            g = readGDS(f);
            b = g.cells(1).boundaries;
            etch = b([b.layer] == 2);
            tc.verifyEqual(numel(etch), 25);
            tc.verifyEqual(nnz([b.layer] == 1), 3);          % waveguide, taper, slab
            w = arrayfun(@(e) (max(e.xy(:, 1)) - min(e.xy(:, 1))) * 1e-3, etch);
            tc.verifyEqual(w, (1 - ff) .* per, 'AbsTol', 1e-3);   % within the 1 nm grid
            tc.verifyEqual(info.grooves(1, 1), ff(1) * per(1), 'AbsTol', 1e-12);
        end

        function rejectsBadInput(tc)
            f = [tempname '.gds'];
            cleanup = onCleanup(@() deleteIfExists(f));
            bad = struct('name', 'BAD NAME', 'polygons', {{[0 0; 1 0; 1 1]}}, 'layers', 1);
            tc.verifyError(@() orf.gdsWrite(f, bad), 'orf:gdsWrite:name');
            line = struct('name', 'L', 'polygons', {{[0 0; 1 0]}}, 'layers', 1);
            tc.verifyError(@() orf.gdsWrite(f, line), 'orf:gdsWrite:vertices');
        end
    end
end

function g = readGDS(file)
%READGDS Minimal GDSII reader (spec-based): units, cells, boundaries, SREFs.
fid = fopen(file, 'r', 'ieee-be'); raw = fread(fid, Inf, 'uint8=>uint8').'; fclose(fid);
g = struct('units', [], 'cells', struct('name', {}, 'boundaries', {}, 'srefs', {}));
p = 1; cur = []; el = [];
while p < numel(raw)
    len = double(raw(p)) * 256 + double(raw(p+1));
    typ = raw(p+2); data = raw(p+4 : p+len-1);
    switch typ
        case 0x03, g.units = [decodeReal8(data(1:8)), decodeReal8(data(9:16))];
        case 0x05, cur = struct('name', '', 'boundaries', struct('layer', {}, 'datatype', {}, 'xy', {}), ...
                                'srefs', struct('name', {}, 'xy', {}));
        case 0x06, cur.name = deblank(char(data(data > 0)));
        case 0x08, el = struct('kind', 'b', 'layer', [], 'datatype', [], 'xy', [], 'name', '');
        case 0x0A, el = struct('kind', 's', 'layer', [], 'datatype', [], 'xy', [], 'name', '');
        case 0x0D, el.layer = double(swapbytes(typecast(data, 'int16')));
        case 0x0E, el.datatype = double(swapbytes(typecast(data, 'int16')));
        case 0x12, el.name = deblank(char(data(data > 0)));
        case 0x10, el.xy = reshape(double(swapbytes(typecast(data, 'int32'))), 2, []).';
        case 0x11
            if el.kind == 'b'
                cur.boundaries(end+1) = struct('layer', el.layer, 'datatype', el.datatype, 'xy', el.xy);
            else
                cur.srefs(end+1) = struct('name', el.name, 'xy', el.xy);
            end
        case 0x07, g.cells(end+1) = cur;
        case 0x04, break
    end
    p = p + len;
end
end

function v = decodeReal8(b)
b = double(b);
s = 1 - 2 * (b(1) >= 128);
e = mod(b(1), 128) - 64;
m = 0;
for k = 2:8, m = m * 256 + b(k); end
v = s * m / 2^56 * 16^e;
end

function deleteIfExists(f)
if isfile(f), delete(f); end
end
