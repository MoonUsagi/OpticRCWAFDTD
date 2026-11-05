function n = evalMaterials(mats, lambda0)
%EVALMATERIALS Evaluate a list of materials into an index matrix.
%   n = orf.evalMaterials({m1, m2, ...}, lambda0) returns an Nlambda x M
%   complex index matrix, the format all solvers accept.
arguments
    mats cell
    lambda0 (:,1) double {mustBePositive}
end
n = complex(zeros(numel(lambda0), numel(mats)));
for j = 1:numel(mats)
    n(:, j) = mats{j}.nk(lambda0);
end
end
