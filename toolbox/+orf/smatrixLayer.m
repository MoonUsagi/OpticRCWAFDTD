function S = smatrixLayer(W, V, lam, W0, V0, kL)
%SMATRIXLAYER Symmetric S-matrix of layers between zero-thickness gaps.
%   Batched over pages: W, V are 2M x 2M x B, lam is 2M x 1 x B, kL =
%   k0*thickness is scalar or 1 x 1 x B. Only exp(-lam*kL) (|.| <= 1)
%   appears, so thick and evanescent layers stay stable.
A = pagemldivide(W, W0) + pagemldivide(V, V0);
B = pagemldivide(W, W0) - pagemldivide(V, V0);
X = exp(-lam .* kL);                       % diagonal of X, as a column
XB = X .* B;
n = size(A, 1);
Ai = pagemldivide(A, [XB, X .* A, B]);     % one factorisation, three solves
AiXB = Ai(:, 1:n, :); AiXA = Ai(:, n+1:2*n, :); AiB = Ai(:, 2*n+1:end, :);
D = A - pagemtimes(XB, AiXB);
S.S11 = pagemldivide(D, [pagemtimes(XB, AiXA) - B, X .* (A - pagemtimes(B, AiB))]);
S.S12 = S.S11(:, n+1:end, :);
S.S11 = S.S11(:, 1:n, :);
S.S21 = S.S12;
S.S22 = S.S11;
end
