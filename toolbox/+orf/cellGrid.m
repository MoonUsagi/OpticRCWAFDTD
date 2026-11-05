function [x, y] = cellGrid(period, Nx, Ny)
%CELLGRID Cell-centred sample points over one unit cell.
%   [x, y] = orf.cellGrid([Lx Ly], Nx, Ny) returns Nx points in [-Lx/2, Lx/2)
%   and Ny in [-Ly/2, Ly/2). An infinite period gives the single point 0.
arguments
    period (1,2) double {mustBePositive}
    Nx (1,1) double {mustBeInteger, mustBePositive}
    Ny (1,1) double {mustBeInteger, mustBePositive} = 1
end
x = axisPoints(period(1), Nx);
y = axisPoints(period(2), Ny);
end

function v = axisPoints(L, N)
if ~isfinite(L)
    v = 0;
else
    v = (-L/2 + L/N * ((0:N-1).' + 0.5));
end
end
