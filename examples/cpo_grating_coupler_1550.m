%CPO_GRATING_COUPLER_1550 Uniform SOI grating coupler, 2D FDTD (TE0).
%   220 nm Si, 70 nm shallow etch, period 0.62 um, fill 0.5, 20 periods,
%   2 um BOX on Si, air cladding. Couples to SMF-28 (w0 = 5.2 um); fiber
%   angle and position are scanned in post-processing (one FDTD run).
%   Takes ~2.5 min on the dev laptop (dx = 20 nm).
%   Caveats: 2D (infinitely wide grating), scalar overlap with a Gaussian.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

tic;
r = orf.gratingCouplerTE(struct());              % defaults listed in gratingCouplerTE
fprintf('FDTD: %d steps, %.0f s; input TE0 neff %.4f; box closure %.1e\n', ...
    r.steps, toc, r.neffIn, max(abs(r.balance)));

th = deg2rad(0:0.5:20); x0 = 4:0.1:14;
eta = orf.fiberCoupling(r, th, x0, 5.2);
iL = find(abs(r.lambdas - 1.55) < 1e-9);
[best, k] = max(reshape(eta(:, :, iL), [], 1));
[i, j] = ind2sub([numel(th) numel(x0)], k);
etaL = squeeze(eta(i, j, :)).';
fprintf('best at 1550 nm: %.1f %% (%.2f dB), fiber %.1f deg, x0 = %.1f um\n', ...
    100 * best, 10*log10(best), rad2deg(th(i)), x0(j));
fprintf('directionality (up) %.2f, down %.2f, back-reflection %.3f\n', ...
    r.Pup(iL), r.Pdown(iL), r.R(iL));
band = r.lambdas(etaL >= best / 10^(1/10));
fprintf('1-dB band (sampled): %.0f-%.0f nm\n', 1e3 * min(band), 1e3 * max(band));

if usejava('desktop')
    figure;
    plot(1e3 * r.lambdas, 10*log10(etaL), 'o-'); hold on;
    plot(1e3 * r.lambdas, 10*log10(r.Pup), 's--');
    xlabel('\lambda [nm]'); ylabel('dB'); legend('fiber coupling', 'upward power');
    title(sprintf('SOI grating coupler, fiber %.1f deg', rad2deg(th(i))));
end
