%MODESLAYER Eigenmodes of patterned layers from P and Q (batched pages).
%   P, Q are 2M x 2M x B. Solves Omega^2 = P*Q = W diag(lam.^2) W^-1 per
%   page, choosing lam = -i*orf.kzBranch(-eig) so exp(-lam z') is the forward
%   mode. lam is 2M x 1 x B. pageeig has no gpuArray support, so GPU
%   input falls back to eig page by page on the GPU.
% (Protected file: the implementation is distributed as P-code.)
