%PQMATRICES P and Q of a patterned layer; Li rules pick Exx, Eyy.
%   [P, Q, EpsInv] = orf.pqMatrices(epsS, Kx, Ky, Nx, Ny, factorization, sectors)
%   with d[s]/dz' = P[u], d[u]/dz' = Q[s], s = [Ex; Ey], u = [H~x; H~y] (H~ = i eta0 H; Fourier
%   coefficients, z' = k0 z). EpsInv = [eps]^-1 gives Ez = i EpsInv (Kx Uy - Ky Ux).
%   sectors = {} for the full problem.
%   With parity sectors (mirror-symmetric layer) [eps]^-1 is assembled
%   from the inverses of its four diagonal blocks: exact, ~16x cheaper.
% (Protected file: the implementation is distributed as P-code.)
