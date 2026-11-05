function [m, n] = harmonics2D(Nx, Ny)
%HARMONICS2D Diffraction-order indices, m varying fastest.
%   Column vectors of length (2Nx+1)(2Ny+1); m = -Nx..Nx, n = -Ny..Ny.
[mm, nn] = ndgrid(-Nx:Nx, -Ny:Ny);
m = mm(:);
n = nn(:);
end
