%METALENS_DEMO_940NM End-to-end metalens: RCWA library -> layout -> focus.
%   a-Si pillars (n = 3.6 placeholder) on SiO2 at 940 nm, P = 0.4 um,
%   H = 0.5 um. Lens diameter 40 um, focal length 40 um (NA ~ 0.45).
%   Steps: unit-cell library (RCWA), hyperbolic target phase, layout
%   (local periodic approximation), angular-spectrum propagation, focal
%   metrics compared with an ideal phase-only lens of the same aperture.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

lambda0 = 0.94; P = 0.4; H = 0.5; Nharm = 10;
Dlens = 40; f = 40; sub = 4;                    % sub-samples per cell edge
sio2 = orf.materialConst(1.45, "SiO2");
air = orf.materialConst(1, "air");
asi = orf.materialConst(3.6, "a-Si (placeholder)");
makeCell = @(D) orf.makeStructure([P P], sio2, air, ...
    {orf.makeLayer(H, air, {orf.shapeCircle(D/2, asi)})});

% 1) Unit-cell library
tic;
lib = orf.buildPhaseLibrary(makeCell, linspace(0.08, 0.36, 57), lambda0, N=Nharm);
fprintf('library: %d cells, N=%d, %.0f s, span %.0f deg\n', ...
    numel(lib.param), Nharm, toc, rad2deg(lib.span));

% 2) Target phase at cell centres and layout
nc = round(Dlens / P);
xc = ((1:nc) - (nc + 1)/2) * P;
[Xc, Yc] = meshgrid(xc);
inside = Xc.^2 + Yc.^2 <= (Dlens/2)^2;
[idx, tCell] = orf.layoutFromLibrary(lib, orf.targetPhaseHyperbolic(Xc, Yc, f, lambda0));
tCell(~inside) = 0;                             % opaque outside the aperture
fprintf('layout: %d pillars, %d distinct diameters used\n', nnz(inside), numel(unique(idx(inside))));

% 3) Field just after the metasurface (each cell held constant), propagate
dx = P / sub;
U0 = kron(tCell, ones(sub));
Pin = 1.45 * nnz(inside) * P^2;                 % incident power in SiO2 (|E| = 1)
Uf = orf.angularSpectrum(U0, dx, lambda0, f);

% 4) Ideal phase-only lens, same aperture, same grid
x = ((1:nc*sub) - (nc*sub + 1)/2) * dx;
[X, Y] = meshgrid(x);
ap = kron(double(inside), ones(sub));
Uideal = orf.angularSpectrum(ap .* exp(1i * orf.targetPhaseHyperbolic(X, Y, f, lambda0)), dx, lambda0, f);

NA = sin(atan(Dlens / 2 / f));
m = orf.focusMetrics(Uf, dx, lambda0, NA, Pin);
mi = orf.focusMetrics(Uideal, dx, lambda0, NA, nnz(ap) * dx^2);
fprintf('NA %.3f, diffraction limit %.3f um\n', NA, m.fwhmLimit);
fprintf('metalens: FWHM %.3f um, efficiency %.1f %%\n', m.fwhm, 100 * m.efficiency);
fprintf('ideal   : FWHM %.3f um, efficiency %.1f %%\n', mi.fwhm, 100 * mi.efficiency);

% 5) Axial scan: where is the actual focus?
zs = f * linspace(0.8, 1.2, 21);
peak = arrayfun(@(z) max(abs(orf.angularSpectrum(U0, dx, lambda0, z)), [], 'all')^2, zs);
[~, k] = max(peak);
fprintf('axial peak at z = %.2f um (design f = %g um)\n', zs(k), f);

if usejava('desktop')
    figure;
    subplot(1, 3, 1); imagesc(xc, xc, lib.param(idx) .* inside); axis image; colorbar;
    title('pillar diameter [\mum]');
    subplot(1, 3, 2); imagesc(x, x, abs(Uf).^2); axis image; xlim([-3 3]); ylim([-3 3]);
    title('|E|^2 at z = f');
    subplot(1, 3, 3); plot(zs, peak / max(peak), '.-'); xlabel('z [\mum]'); title('peak |E|^2 vs z');
end
