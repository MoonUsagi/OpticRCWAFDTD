function S = smatrixRegion(W, V, W0, V0, side)
%SMATRIXREGION S-matrix of the semi-infinite reflection or transmission region.
%   side = "ref" (incident side) or "trn" (substrate side).
arguments
    W, V, W0, V0
    side (1,1) string {mustBeMember(side, ["ref", "trn"])}
end
A = W0 \ W + V0 \ V;
B = W0 \ W - V0 \ V;
I = eye(size(A));
if side == "ref"
    S.S11 = -(A \ B);
    S.S12 = 2 * (A \ I);
    S.S21 = 0.5 * (A - B * (A \ B));
    S.S22 = B / A;
else
    S.S11 = B / A;
    S.S12 = 0.5 * (A - B * (A \ B));
    S.S21 = 2 * (A \ I);
    S.S22 = -(A \ B);
end
end
