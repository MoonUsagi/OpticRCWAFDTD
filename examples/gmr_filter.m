%% Guided-mode resonance filter (narrow-band reflector)
% A shallow grating on a thin Si3N4 waveguide couples normally incident
% light into the guided mode; at resonance almost all of it is reflected
% in a band of a few nm. The resonance sits near lambda = period * n_eff
% and splits with the incidence angle.
%
% Shows: 1D RCWA (orf.rcwa1D) with a waveguide layer, an adaptive
% wavelength scan of a sharp resonance, and an angle-wavelength map.
% About 30 s.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

air = orf.material("air"); glass = orf.material("SiO2"); sin3 = orf.material("Si3N4");
Lam = 0.98;            % grating period [um]
ff = 0.5;              % Si3N4 fraction of the grating teeth
tg = 0.06;             % grating depth [um]
tw = 0.20;             % waveguide below the grating [um]
N = 15;
dev = orf.makeStructure([Lam Inf], air, glass, { ...
    orf.makeLayer(tg, air, {orf.shapeRect(ff * Lam, Inf, sin3)}), ...
    orf.makeLayer(tw, sin3, {})});
R = @(lam, th, pol) orf.rcwa1D(dev, lam, th, 0, pol, N=N).Rtot;

%% 1. Find the resonance: coarse scan, then zoom in
lc = linspace(1.40, 1.70, 151);
Rc = arrayfun(@(l) R(l, 0, "s"), lc);
[~, k] = max(Rc);
lf = linspace(lc(k) - 0.01, lc(k) + 0.01, 201);
Rf = arrayfun(@(l) R(l, 0, "s"), lf);
[Rmax, k] = max(Rf);
above = lf(Rf >= Rmax / 2);
fprintf('TE resonance at %.2f nm: R = %.3f, FWHM = %.2f nm\n', ...
    1e3 * lf(k), Rmax, 1e3 * (above(end) - above(1)));
RcTM = arrayfun(@(l) R(l, 0, "p"), lc);

figure('Position', [100 100 900 360]);
subplot(1, 2, 1);
plot(1e3 * lc, Rc, 1e3 * lc, RcTM, 'LineWidth', 1.5); grid on
xlabel('wavelength [nm]'); ylabel('reflectance'); legend('TE', 'TM'); ylim([0 1]);
title('Normal incidence');
subplot(1, 2, 2);
plot(1e3 * lf, Rf, 'LineWidth', 1.5); grid on
xlabel('wavelength [nm]'); ylabel('reflectance'); ylim([0 1]);
title(sprintf('TE resonance, FWHM %.2f nm', 1e3 * (above(end) - above(1))));

%% 2. Angle dependence: the resonance splits into two branches
th = deg2rad(0:0.5:4);
lm = linspace(lf(k) - 0.04, lf(k) + 0.04, 121);
map = zeros(numel(th), numel(lm));
tic;
for i = 1:numel(th)
    map(i, :) = arrayfun(@(l) R(l, th(i), "s"), lm);
end
fprintf('angle map: %d x %d RCWA runs in %.1f s\n', numel(th), numel(lm), toc);
figure('Position', [100 100 640 420]);
imagesc(1e3 * lm, rad2deg(th), map); axis xy; colorbar; clim([0 1]);
xlabel('wavelength [nm]'); ylabel('incidence angle [deg]');
title('TE reflectance: resonance vs angle');
