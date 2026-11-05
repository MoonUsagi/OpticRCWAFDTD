%METALENSTOGDS Write a metalens pillar layout to GDSII.
%   info = orf.metalensToGDS(file, diameters, period) writes one circular
%   pillar per lattice site. diameters is nx x ny [um] (0 = no pillar),
%   e.g. lib.param(idx) .* inside from orf.layoutFromLibrary; site (i,j)
%   is at ((i - (nx+1)/2) * period, (j - (ny+1)/2) * period), so the lens
%   is centred on the origin. Each distinct diameter becomes one cell
%   (PILLAR_<nm>) placed by references, which keeps files small.
%
%   Options: Layer (default 1), Datatype (0), Vertices per circle (64),
%   DbUnit (um, 1e-3), TopCell ("METALENS"), RoundTo (diameter grid in
%   um before grouping, default 1e-3).
%   Circles are polygons whose area equals the circle's (vertex radius
%   r * sqrt(2 pi / (n sin(2 pi / n)))), so the fill factor is preserved.
%   info: nPillars, nCells, diameters (unique, um), file.
% (Protected file: the implementation is distributed as P-code.)
