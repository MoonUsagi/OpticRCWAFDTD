%EXPORT_GDS From simulation to mask layout: metalens and grating coupler GDSII.
%   1) a 40 um a-Si metalens (940 nm, P = 0.4 um, f = 40 um): RCWA phase
%      library -> layout -> GDS (one cell per diameter, placed by reference)
%   2) the best printable apodized SOI grating coupler from
%      cpo_grating_optimize (ff 0.875 -> 0.435, 25 periods, 15 deg,
%      100 nm minimum feature) -> GDS with Si and shallow-etch layers
%   Files are written to the current folder. Open them in KLayout (free)
%   to inspect. Layer numbers are placeholders: set them to your PDK.
%   ~1 min on a laptop.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

%% 1. Metalens
lambda0 = 0.94; P = 0.4; H = 0.5; Dlens = 40; f = 40;
sio2 = orf.materialConst(1.45); air = orf.materialConst(1);
asi = orf.materialConst(3.6, "a-Si (placeholder)");
makeCell = @(D) orf.makeStructure([P P], sio2, air, ...
    {orf.makeLayer(H, air, {orf.shapeCircle(D/2, asi)})});
lib = orf.buildPhaseLibrary(makeCell, linspace(0.08, 0.36, 29), lambda0, N=8);
nc = round(Dlens / P);
xc = ((1:nc) - (nc + 1)/2) * P;
[Xc, Yc] = ndgrid(xc, xc);
inside = Xc.^2 + Yc.^2 <= (Dlens/2)^2;
idx = orf.layoutFromLibrary(lib, orf.targetPhaseHyperbolic(Xc, Yc, f, lambda0));
diameters = lib.param(idx) .* inside;
m = orf.metalensToGDS("metalens_940nm_D40um.gds", diameters, P, Layer=1);
d = dir(m.file);
fprintf('metalens: %d pillars, %d distinct diameters (%.0f-%.0f nm), %s (%.0f kB)\n', ...
    m.nPillars, m.nCells, 1e3 * min(m.diameters), 1e3 * max(m.diameters), m.file, d.bytes / 1e3);

%% 2. Grating coupler
[per, ff] = orf.apodizedGrating(0.875, 0.435, 15, 25, 1.014);
ff = min(max(ff, 0.1 ./ per), 1 - 0.1 ./ per);             % 100 nm rule, as optimised
g = orf.gratingToGDS("grating_coupler_apodized.gds", per, ff, Width=12, ...
    SiLayer=1, EtchLayer=2);
widths = [g.grooves(:, 2) - g.grooves(:, 1); ff(:) .* per(:)];
fprintf('grating: %d grooves, smallest feature %.0f nm, length %.2f um, %s\n', ...
    g.nGrooves, 1e3 * min(widths), g.grooves(end, 2), g.file);
