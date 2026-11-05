%LAYOUTFROMLIBRARY Pick the library cell that best realises each target phase.
%   [idx, t] = orf.layoutFromLibrary(lib, phi) returns, for every target
%   phase in phi, the index into the library and the cell's complex
%   transmission (local periodic approximation). The choice minimises
%   |t_j - A exp(i(phi + phi0))|, A = median |t_j|, which trades phase
%   error against amplitude and so avoids low-T resonant cells. phi0 is
%   a global phase offset scanned over [0, 2pi) to minimise the total
%   error (the absolute phase of a lens is free).
%   Option Tmin drops cells with lib.T below it before choosing.
% (Protected file: the implementation is distributed as P-code.)
