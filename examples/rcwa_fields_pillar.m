%RCWA_FIELDS_PILLAR Field inside a metalens unit cell (RCWA field reconstruction).
%   A circular a-Si pillar (n = 3.6, placeholder) on glass at 940 nm, lit
%   from the glass side, polarised along y. Shows |E| and Re(E_y) in the
%   x-z plane through the pillar centre (wave travels upward on the plot,
%   from the glass into air) and checks that the power flux is the same at
%   every height. Runs in a few seconds.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

glass = orf.materialConst(1.45); air = orf.materialConst(1); asi = orf.materialConst(3.6);
L = 0.4; h = 0.6; D = 0.24;
dev = orf.makeStructure([L L], glass, air, ...
    {orf.makeLayer(h, air, {orf.shapeCircle(D/2, asi)})});
x = linspace(-L/2, L/2, 81).';
z = linspace(-0.5, h + 0.8, 161).';
tic;
f = orf.rcwaFields(dev, 0.94, 0, 0, "s", x, 0, z, Nx=8);
fprintf('T = %.4f, R = %.4f, flux through the cell: %.4f to %.4f (%.1f s)\n', ...
    f.out.Ttot, f.out.Rtot, min(f.flux), max(f.flux), toc);

Eabs = squeeze(sqrt(sum(abs(f.E(:, 1, :, :)).^2, 4))).';      % nz x nx
Ey = squeeze(real(f.E(:, 1, :, 2))).';
outline = squeeze(real(f.eps(:, 1, :))).' > 2;
figure('Position', [100 100 900 420]);
subplot(1, 2, 1);
imagesc(x, z, Eabs); axis xy image; colorbar; hold on;
contour(x, z, outline, [0.5 0.5], 'w', 'LineWidth', 1);
yline(0, 'w:'); xlabel('x [\mum]'); ylabel('z [\mum] (glass below 0)'); title('|E|');
subplot(1, 2, 2);
imagesc(x, z, Ey); axis xy image; colorbar; hold on;
contour(x, z, outline, [0.5 0.5], 'k', 'LineWidth', 1);
yline(0, 'k:'); xlabel('x [\mum]'); title('Re E_y');
t = linspace(0, 1, 128).';                                % blue - white - red
colormap(gca, [min(1, 2*t), 1 - abs(2*t - 1), min(1, 2 - 2*t)]); clim(max(abs(Ey(:))) * [-1 1]);
