function S = smatrixStar(SA, SB)
%SMATRIXSTAR Redheffer star product: SA (incident side) * SB, batched.
%   Pages broadcast: either operand may be a single 2-D S-matrix.
I = eye(size(SA.S11, 1));
D = pagemrdivide(SA.S12, I - pagemtimes(SB.S11, SA.S22));
F = pagemrdivide(SB.S21, I - pagemtimes(SA.S22, SB.S11));
S.S11 = SA.S11 + pagemtimes(pagemtimes(D, SB.S11), SA.S21);
S.S12 = pagemtimes(D, SB.S12);
S.S21 = pagemtimes(F, SA.S21);
S.S22 = SB.S22 + pagemtimes(pagemtimes(F, SA.S22), SB.S12);
end
