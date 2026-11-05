function [n, d] = structureToTMM(dev, lambda0)
%STRUCTURETOTMM Convert a homogeneous-layer structure to tmm inputs.
%   [n, d] = orf.structureToTMM(dev, lambda0) returns the Nl x M index
%   matrix and 1 x (M-2) thickness vector. Errors if any layer has
%   shapes, since TMM only handles laterally uniform layers.
arguments
    dev (1,1) struct
    lambda0 (:,1) double {mustBePositive}
end
L = numel(dev.layers);
mats = cell(1, L + 2);
mats{1} = dev.incident;
mats{end} = dev.substrate;
d = zeros(1, L);
for j = 1:L
    layer = dev.layers{j};
    if ~isempty(layer.shapes)
        error('structureToTMM:patterned', ...
            'Layer %d has shapes; TMM needs homogeneous layers.', j);
    end
    mats{j + 1} = layer.background;
    d(j) = layer.thickness;
end
n = orf.evalMaterials(mats, lambda0);
end
