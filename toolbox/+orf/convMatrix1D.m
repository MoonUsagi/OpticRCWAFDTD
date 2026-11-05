function C = convMatrix1D(f, N)
%CONVMATRIX1D Toeplitz convolution matrix from cell-centred samples.
%   C = orf.convMatrix1D(f, N) returns the (2N+1) x (2N+1) matrix
%   C(m,n) = f_{m-n}, where f_h are the Fourier coefficients of the
%   piecewise-constant function whose value on cell j is f(j). Cells are
%   the cellGrid cells over one period. Coefficients are exact for that
%   staircase, so a structure whose edges sit on cell boundaries has
%   exact coefficients.
arguments
    f (:,1) double
    N (1,1) double {mustBeInteger, mustBeNonnegative}
end
Nx = numel(f);
assert(Nx >= 4*N + 1, 'convMatrix1D:sampling', ...
    'Need at least 4N+1 = %d samples, got %d.', 4*N + 1, Nx);
fh = orf.fourierWeights(Nx, N) * f;                  % f_h for h = -2N..2N
mid = 2*N + 1;                                   % index of h = 0
C = toeplitz(fh(mid:end), fh(mid:-1:1));
end
