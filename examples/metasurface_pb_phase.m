%% Geometric (Pancharatnam-Berry) phase of a rotated TiO2 nanofin
% A rectangular nanofin acts as a small wave plate. Lit with circular
% polarisation, the light converted to the opposite handedness picks up a
% phase of 2*theta when the fin is rotated by theta - the principle of
% PB-phase metalenses (Khorasaninejad et al., Science 352, 1190 (2016)).
%
% Shows: rotated polygons (orf.shapePolygon), Jones-vector input,
% batched RCWA over a rotation sweep, and the circular-polarisation
% analysis of the complex amplitudes (power = |t|^2 n_out / n_in).
% About 30 s.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

lambda0 = 0.532;
P = 0.325; H = 0.6; L = 0.25; W = 0.085;          % period, height, fin length, width [um]
tio2 = orf.material("TiO2");                      % rutile; use your film's data for real designs
glass = orf.material("SiO2"); air = orf.material("air");
N = 7;                                            % harmonics per direction (N = 9 differs by ~1 %)

%% Rotation sweep (one batched RCWA call)
thetaFin = deg2rad(0:22.5:180);
corners = [-L/2 -W/2; L/2 -W/2; L/2 W/2; -L/2 W/2];
rot = @(a) [cos(a) -sin(a); sin(a) cos(a)];
devs = arrayfun(@(a) orf.makeStructure([P P], glass, air, ...
    {orf.makeLayer(H, air, {orf.shapePolygon(corners * rot(a).', tio2)})}), ...
    thetaFin, 'UniformOutput', false);

% Normal incidence from the glass: TE = y, TM = x, so the Jones vector
% [aTE aTM] = [1i 1]/sqrt(2) is E = (x + i y)/sqrt(2).
tic;
out = orf.rcwa2D(devs, lambda0, 0, 0, [1i 1] / sqrt(2), Nx=N);
k0 = out.m == 0 & out.n == 0;
t = squeeze(out.t(1:2, k0, :));                   % [tx; ty] per rotation
cross = (t(1, :) + 1i * t(2, :)) / sqrt(2);       % opposite handedness
co    = (t(1, :) - 1i * t(2, :)) / sqrt(2);       % same handedness
nRatio = 1 / real(glass.nk(lambda0));             % power = |t|^2 n_air / n_glass
fprintf('%d rotations, N = %d: %.1f s\n', numel(thetaFin), N, toc);

phaseCross = unwrap(angle(cross));
phaseCross = phaseCross - phaseCross(1);
slope = polyfit(thetaFin, phaseCross, 1);
fprintf('cross-polarised phase / fin angle = %.3f (geometric phase: +/-2)\n', slope(1));
fprintf('conversion efficiency |t_cross|^2 = %.1f %% (spread %.1e), co-pol %.1f %%\n', ...
    100 * nRatio * mean(abs(cross).^2), nRatio * std(abs(cross).^2), 100 * nRatio * mean(abs(co).^2));

figure('Position', [100 100 900 360]);
subplot(1, 2, 1);
plot(rad2deg(thetaFin), rad2deg(phaseCross), 'o-', 'LineWidth', 1.5); hold on
plot(rad2deg(thetaFin), rad2deg(sign(slope(1)) * 2 * thetaFin), 'k--');
xlabel('fin rotation [deg]'); ylabel('cross-pol phase [deg]'); grid on
legend('RCWA', '\pm2\theta', 'Location', 'northwest'); title('Geometric phase');
subplot(1, 2, 2);
plot(rad2deg(thetaFin), 100 * nRatio * abs(cross).^2, 'o-', rad2deg(thetaFin), 100 * nRatio * abs(co).^2, 's-', ...
    'LineWidth', 1.5);
xlabel('fin rotation [deg]'); ylabel('[%]'); ylim([0 100]); grid on
legend('converted (cross)', 'unconverted (co)'); title('Efficiency does not depend on rotation');

%% Conversion efficiency vs wavelength (fin at 0 deg)
lams = linspace(0.45, 0.70, 9);
eta = zeros(size(lams));
for k = 1:numel(lams)
    o = orf.rcwa2D(devs{1}, lams(k), 0, 0, [1i 1] / sqrt(2), Nx=N);
    tk = o.t(1:2, o.m == 0 & o.n == 0);
    eta(k) = abs((tk(1) + 1i * tk(2)) / sqrt(2))^2 / real(glass.nk(lams(k)));
end
figure('Position', [100 100 640 380]);
plot(1e3 * lams, 100 * eta, 'o-', 'LineWidth', 1.5); grid on
xlabel('wavelength [nm]'); ylabel('conversion efficiency [%]');
title(sprintf('TiO2 nanofin %.0f x %.0f x %.0f nm, period %.0f nm', 1e3 * [L W H P]));
[etaMax, kMax] = max(eta);
fprintf('best conversion %.1f %% at %.0f nm\n', 100 * etaMax, 1e3 * lams(kMax));
