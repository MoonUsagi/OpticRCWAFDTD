%SYMMETRYBASIS Mirror-symmetry adapted basis for normal incidence.
%   [UE, UH, sectors] = orf.symmetryBasis(m, n, pol) for harmonic indices
%   m, n (as from harmonics2D) of a structure symmetric under x -> -x and
%   y -> -y, lit at normal incidence. The solution keeps the parity of
%   the source:
%     pol "p" (E_x): E_x, H_y even-even;  E_y, H_x odd-odd
%     pol "s" (E_y): E_y, H_x even-even;  E_x, H_y odd-odd
%   ("even-even": c(m,n) = c(-m,n) = c(m,-n); "odd-odd": c(m,n) =
%   -c(-m,n) = -c(m,-n)). UE (2M x Mr) and UH are sparse with
%   orthonormal columns spanning the allowed [E_x; E_y] and [H_x; H_y]
%   coefficient vectors; reduced RCWA matrices are P_r = UE' P UH and
%   Q_r = UH' Q UE (about 4x fewer unknowns). sectors = {ee, eo, oe, oo}
%   are the four parity sectors of a single scalar field (M x ~M/4 each,
%   together a complete orthonormal basis): any symmetric convolution
%   matrix is block diagonal in them, so it can be inverted per sector.
% (Protected file: the implementation is distributed as P-code.)
