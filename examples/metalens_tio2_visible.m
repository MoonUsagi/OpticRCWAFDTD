%% Visible metalens: TiO2 pillars at 532 nm, from parameters to GDSII
% The whole metalens flow in one call, orf.metalensDesign (the engine of
% the Metalens Designer app), with a built-in dispersive material:
%
% # phase library of TiO2 pillars on glass (RCWA),
% # pillar layout for a hyperbolic lens phase,
% # focal spot and efficiency against an ideal lens,
% # save the design and export the mask.
%
% Every step is the same as clicking through orf.MetalensDesigner with
% "TiO2" and "SiO2" typed as materials. About 5 s.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

p = struct();
p.lambda0 = 0.532;                        % [um]
p.period = 0.30;                          % < lambda / n_glass: only the zero order
p.height = 0.60;
p.pillar = orf.material("TiO2");          % rutile; amorphous ALD TiO2 has a lower index
p.substrate = orf.material("SiO2");
p.dMin = 0.08; p.dMax = 0.24;             % keep >= 60 nm gaps between pillars
p.nLib = 33; p.N = 7;
p.D = 20; p.f = 20;                       % lens diameter and focal length [um], NA 0.45

%% Run (with a text progress bar)
tic;
r = orf.metalensDesign(p, Progress=orf.progressText());
m = r.metrics;
fprintf('library phase span %.0f deg, mean T %.2f\n', rad2deg(r.lib.span), mean(r.lib.T));
fprintf('NA %.2f: FWHM %.3f um (limit %.3f), efficiency %.1f %% (ideal lens %.1f %%), %.0f s\n', ...
    r.NA, m.fwhm, m.fwhmLimit, 100 * m.efficiency, 100 * r.ideal.efficiency, toc);

%% Plots
figure('Position', [100 100 1100 330]);
subplot(1, 3, 1);
yyaxis left;  plot(r.lib.param, rad2deg(r.lib.phase), 'o-'); ylabel('phase [deg]');
yyaxis right; plot(r.lib.param, r.lib.T, 's-'); ylabel('T'); ylim([0 1]);
xlabel('diameter [\mum]'); title('TiO2 pillar library, 532 nm');
subplot(1, 3, 2);
imagesc(r.xc, r.xc, r.diameters); axis image; colorbar;
xlabel('x [\mum]'); ylabel('y [\mum]'); title('Pillar diameters [\mum]');
subplot(1, 3, 3);
imagesc(r.x, r.x, r.focal); axis image; colorbar; xlim(3 * [-1 1]); ylim(3 * [-1 1]);
xlabel('x [\mum]'); ylabel('y [\mum]');
title(sprintf('Focal spot: FWHM %.2f \\mum', m.fwhm));

%% Save the design and export the mask
out = tempdir;
orf.saveDesign(fullfile(out, 'tio2_metalens.json'), struct('app', "MetalensDesigner", 'params', r.params));
info = orf.metalensToGDS(fullfile(out, 'tio2_metalens.gds'), r.diameters, p.period);
fprintf('saved %s and %s (%d pillars)\n', fullfile(out, 'tio2_metalens.json'), ...
    fullfile(out, 'tio2_metalens.gds'), info.nPillars);
% Open the same design in the app:
%   app = orf.MetalensDesigner; app.setParams(orf.loadDesign(fullfile(tempdir, 'tio2_metalens.json')).params);
