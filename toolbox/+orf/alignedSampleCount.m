function Ns = alignedSampleCount(devs, period, dim, NsMin)
%ALIGNEDSAMPLECOUNT Sample count that puts every rectangle edge on a pixel boundary.
%   Ns = orf.alignedSampleCount(devs, period, dim, NsMin) returns the
%   smallest Ns in [NsMin, 4*NsMin] for which every rectangle edge along
%   dimension dim (1 = x, 2 = y), in every structure of the cell array
%   devs, falls on a boundary of the cell-centred grid of orf.cellGrid.
%   The sampled geometry is then exact for rectangles; otherwise each edge
%   moves by up to half a pixel, which shifts efficiencies by ~1e-4.
%   Returns NsMin when there are no rectangles or no such Ns exists.
arguments
    devs cell
    period (1,2) double
    dim (1,1) double {mustBeMember(dim, [1 2])}
    NsMin (1,1) double {mustBeInteger, mustBePositive}
end
L = period(dim);
edges = [];
for b = 1:numel(devs)
    for j = 1:numel(devs{b}.layers)
        shapes = devs{b}.layers{j}.shapes;
        for k = 1:numel(shapes)
            s = shapes{k};
            if isfield(s, 'size') && isfield(s, 'type') && s.type == "rect" && s.size(dim) < L
                edges = [edges, s.center(dim) + [-1 1] * s.size(dim) / 2]; %#ok<AGROW>
            end
        end
    end
end
Ns = NsMin;
if isempty(edges) || ~isfinite(L)
    return
end
u = mod(edges / L + 0.5, 1);                % edge positions in [0, 1) from the cell boundary
u = uniquetol(u, 1e-12);
for cand = NsMin:4*NsMin
    f = u * cand;
    if all(abs(f - round(f)) < 1e-6)
        Ns = cand;
        return
    end
end
end
