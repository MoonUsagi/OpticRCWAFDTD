%CONVMATRIX2D Laurent convolution matrix for a 2D-periodic layer.
%   C = orf.convMatrix2D(f, Nx, Ny) with f an Nsx x Nsy array of cell-centred
%   samples returns the M x M matrix C(p,q) = f_{m_p - m_q, n_p - n_q},
%   M = (2Nx+1)(2Ny+1), harmonics ordered as in orf.harmonics2D (m fastest).
% (Protected file: the implementation is distributed as P-code.)
