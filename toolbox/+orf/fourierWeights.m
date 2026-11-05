function F = fourierWeights(Ns, N)
%FOURIERWEIGHTS Exact Fourier weights for cell-centred staircase samples.
%   F = orf.fourierWeights(Ns, N) is a (4N+1) x Ns matrix so that F*f gives
%   the coefficients f_h, h = -2N..2N, of the piecewise-constant function
%   whose value on cell j (of Ns equal cells over one period) is f(j).
%   Each cell is integrated analytically (the sinc factor).
h = (-2*N:2*N).';
xj = ((0:Ns-1) + 0.5) / Ns - 0.5;          % x/period of cell centres
u = pi * h / Ns;
cellSinc = ones(size(u));
cellSinc(u ~= 0) = sin(u(u ~= 0)) ./ u(u ~= 0);
F = cellSinc .* exp(-2i*pi * h * xj) / Ns;
end
