function kz = kzBranch(kz2)
%KZBRANCH Square root with the outgoing-wave branch for e^{-iwt}.
%   kz = orf.kzBranch(kz2) returns sqrt(kz2) chosen so that Im(kz) >= 0
%   (decaying toward +z), and Re(kz) >= 0 when Im(kz) is zero.
%   Shared by TMM, RCWA and the mode solver.
kz = sqrt(kz2);
flip = imag(kz) < 0 | (imag(kz) == 0 & real(kz) < 0);
kz(flip) = -kz(flip);
end
