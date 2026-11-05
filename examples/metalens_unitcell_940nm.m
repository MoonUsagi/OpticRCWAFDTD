%METALENS_UNITCELL_940NM Phase library for a-Si pillars at 940 nm.
%   Circular a-Si pillars on SiO2, light incident from the substrate,
%   period 0.4 um (< lambda/n_SiO2 = 0.648 um, so only the zero order
%   propagates), height 0.5 um, diameter swept 0.08-0.36 um.
%
%   a-Si is a constant n = 3.6 placeholder; replace it with a measured
%   n,k table (materialTable) before using the library for a real design.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

lambda0 = 0.94; P = 0.4; H = 0.5;
sio2 = orf.materialConst(1.45, "SiO2");
air = orf.materialConst(1, "air");
asi = orf.materialConst(3.6, "a-Si (placeholder)");
makeCell = @(D) orf.makeStructure([P P], sio2, air, ...
    {orf.makeLayer(H, air, {orf.shapeCircle(D/2, asi)})});

Ds = linspace(0.08, 0.36, 57);
tic;
lib = orf.buildPhaseLibrary(makeCell, Ds, lambda0, N=10, CheckN=13);
fprintf('%d cells in %.1f s\n', numel(Ds), toc);
fprintf('phase span %.0f deg, T00 mean %.2f, min %.2f\n', ...
    rad2deg(lib.span), mean(lib.T), min(lib.T));
fprintf('convergence N=10 vs 13: median dphase %.2f deg, max %.2f deg (narrow resonances), max dT %.3f\n', ...
    rad2deg(median(lib.meta.phaseDiff)), rad2deg(lib.meta.maxPhaseDiff), lib.meta.maxTDiff);
[~, k] = min(lib.T);
fprintf('lowest T00 at D = %.3f um (resonance; avoid in layout)\n', Ds(k));

if usejava('desktop')
    figure;
    yyaxis left;  plot(Ds, rad2deg(lib.phase), '.-'); ylabel('phase [deg]');
    yyaxis right; plot(Ds, lib.T, '.-'); ylabel('T_{00}'); ylim([0 1]);
    xlabel('pillar diameter D [\mum]');
    title(sprintf('a-Si pillars, \\lambda = %g \\mum, P = %g, H = %g \\mum', lambda0, P, H));
end
