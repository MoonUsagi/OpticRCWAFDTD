%% Waveguide modes of an SOI strip (full-vector mode solver)
% |orf.wgModes2D| finds the guided modes of any cross-section made of
% boxes. This example:
%
% # plots the TE0 and TM0 modes of a 500 x 220 nm silicon strip in oxide,
% # sweeps the width to find the single-mode range,
% # computes the group index, which sets the FSR of rings and MZIs.
%
% Indices come from the built-in dispersion of Si and SiO2. About 20 s.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

lambda0 = 1.55;
nSi = @(l) real(orf.material("Si").nk(l));
nOx = @(l) real(orf.material("SiO2").nk(l));
dx = 0.02;
x = (-1.5:dx:1.5).';                 % lateral [um]
y = (-1.0:dx:1.2).';                 % vertical [um]; Si from 0 to 0.22
strip = @(w, l) [-w/2 w/2 0 0.22 nSi(l)];

%% 1. Mode profiles at 1550 nm
m = orf.wgModes2D(x, y, nOx(lambda0), strip(0.5, lambda0), lambda0, 2);
figure('Position', [100 100 900 330]);
for k = 1:2
    subplot(1, 2, k);
    Et = sqrt(abs(m.Ex(:, :, k)).^2 + abs(m.Ey(:, :, k)).^2);
    imagesc(x, y, Et.'); axis xy image; colorbar; hold on
    rectangle('Position', [-0.25 0 0.5 0.22], 'EdgeColor', 'w', 'LineWidth', 1);
    xlim([-1 1]); ylim([-0.6 0.8]);
    label = "TM-like"; if m.teFraction(k) > 0.5, label = "TE-like"; end
    title(sprintf('%s mode %d: n_{eff} = %.4f', label, k, m.neff(k)));
    xlabel('x [\mum]'); ylabel('y [\mum]');
end
fprintf('500 x 220 nm strip at 1550 nm: neff = %.4f (TE fraction %.2f), %.4f (%.2f)\n', ...
    m.neff(1), m.teFraction(1), m.neff(2), m.teFraction(2));

%% 2. Width sweep: where does the second TE mode appear?
widths = 0.30:0.05:0.80;
neff = nan(3, numel(widths));
isTE = false(3, numel(widths));
for k = 1:numel(widths)
    mk = orf.wgModes2D(x, y, nOx(lambda0), strip(widths(k), lambda0), lambda0, 3);
    guided = mk.neff > nOx(lambda0) + 1e-3;          % above the cladding index
    neff(guided, k) = mk.neff(guided);
    isTE(:, k) = mk.teFraction > 0.5;
end
figure('Position', [100 100 640 420]); hold on
for k = 1:3
    te = isTE(k, :);
    plot(widths(te), neff(k, te), 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
    plot(widths(~te), neff(k, ~te), 's', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
end
yline(nOx(lambda0), ':', 'oxide');
xlabel('strip width [\mum]'); ylabel('n_{eff}'); grid on
title('Guided modes vs width (blue: TE-like, red: TM-like)');
nTE = sum(isTE & ~isnan(neff), 1);
kTwo = find(nTE >= 2, 1);
fprintf('TE1 appears between %.2f and %.2f um width (single-mode below)\n', ...
    widths(kTwo - 1), widths(kTwo));

%% 3. Group index from the dispersion
% n_g = n_eff - lambda dn_eff/dlambda, by a central difference that
% includes the material dispersion of Si and SiO2.
dl = 0.01;
ne = zeros(1, 3);
ls = lambda0 + [-dl 0 dl];
for k = 1:3
    mk = orf.wgModes2D(x, y, nOx(ls(k)), strip(0.5, ls(k)), ls(k), 1);
    ne(k) = mk.neff(1);
end
ng = ne(2) - lambda0 * (ne(3) - ne(1)) / (2 * dl);
fprintf('TE0 group index at 1550 nm: %.3f  (ring FSR for L = 100 um: %.2f nm)\n', ...
    ng, 1e3 * lambda0^2 / (ng * 100));
