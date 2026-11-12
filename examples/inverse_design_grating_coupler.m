%% Inverse design of SOI grating couplers (adjoint method)
% The mask patterns of a 220 nm SOI grating coupler (2 um BOX) are
% optimised for coupling into an SMF-28 fiber tilted by 10 degrees at
% 1550 nm. Every pixel of the 12 um grating is a design variable, and so
% is the fiber position; the adjoint method gives the whole gradient from
% two frequency-domain solves (orf.fdfd2D).
%
% Two processes:
%   "shallow"  one 70 nm etch. About 57 % of the light can go up at all
%              (the rest leaks into the substrate), which caps the coupling.
%   "overlay"  70 nm etch plus a 160 nm poly-Si overlay with its own mask.
%              The overlay makes the grating emit upward (~90 %).
%
% Each final design is checked with an independent solver (the 2D FDTD
% of orf.gratingCouplerTE) and written to GDSII. Minimum feature 100 nm.
% About 10 min on a laptop with a GPU.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

thetaDeg = 10; w0 = 5.2;
lams = linspace(1.50, 1.60, 11);
gpu = gpuDeviceCount > 0;
procs = ["shallow", "overlay"];
R = struct(); F = struct(); E = struct();

%% 1. Optimise and check with the FDTD
for pr = procs
    fprintf('--- %s ---\n', pr);
    tic;
    r = orf.inverseDesignGratingCoupler(struct('process', pr, 'thetaDeg', thetaDeg, ...
        'lambdas', 1.55), MinFeature=0.10);
    fprintf('optimised in %.1f min\n', toc / 60);
    f = orf.gratingCouplerTE(struct('layout', r.layout, 'lambdas', lams, 'useGPU', gpu));
    eta = squeeze(orf.fiberCoupling(f, deg2rad(thetaDeg), 4 + r.x0, w0)).';
    i0 = find(abs(lams - 1.55) < 1e-9);
    inBand = lams(eta >= max(eta) / 10^0.1);
    fprintf(['FDTD check: %.1f %% (%.2f dB) at 1550 nm; up %.0f %%, substrate %.0f %%, ' ...
        'back-reflection %.1f %%; 1-dB band %.0f-%.0f nm\n'], 100 * eta(i0), 10 * log10(eta(i0)), ...
        100 * f.Pup(i0), 100 * f.Pdown(i0), 100 * f.R(i0), 1e3 * min(inBand), 1e3 * max(inBand));
    R.(pr) = r; F.(pr) = f; E.(pr) = eta;
end

%% 2. Reference: the uniform grating (period 0.62 um, ff 0.5)
u = orf.gratingCouplerTE(struct('lambdas', lams, 'useGPU', gpu));
bu = orf.bestFiberCoupling(u, 5:0.5:15);
fprintf('uniform grating (best fiber angle and position): %.1f %% (%.2f dB)\n', 100 * bu.eta, bu.dB);

%% 3. Plots
figure('Position', [60 60 1100 760]);
subplot(3, 2, 1); hold on
for pr = procs
    plot(R.(pr).history.iteration, 100 * R.(pr).history{:, 4}, 'LineWidth', 1.5);
end
grid on; xlabel('iteration'); ylabel('coupling [%]'); legend(procs, 'Location', 'southeast');
title('Optimisation (FDFD)');
subplot(3, 2, 2);
plot(1e3 * lams, 100 * E.overlay, 'o-', 1e3 * lams, 100 * E.shallow, 's-', ...
    1e3 * lams, 100 * bu.spectrum, '^-', 'LineWidth', 1.5); grid on
xlabel('wavelength [nm]'); ylabel('coupling [%] (FDTD)'); ylim([0 100]);
legend('inverse, poly overlay', 'inverse, 70 nm etch', 'uniform grating', 'Location', 'south');
title('Coupling into SMF-28');
k = 3;
for pr = procs
    subplot(3, 1, k - 1);
    g = F.(pr).geometry;
    imagesc(g.x, g.z, sqrt(real(g.eps)).'); axis xy; colorbar; clim([1 3.5]);
    xlim([3.5, 16.5]); ylim([-0.3 0.6]);
    xlabel('x [\mum]'); ylabel('z [\mum]'); title(sprintf('%s: optimised cross-section', pr));
    k = k + 1;
end

%% 4. Masks (GDSII): Si 1, shallow-etch openings 2, poly-Si overlay 4
for pr = procs
    r = R.(pr);
    W = 12;                                               % grating width [um]
    rect = @(a) [a(1) -W/2; a(2) -W/2; a(2) W/2; a(1) W/2] - [4 0];   % grating starts at x = 0
    polys = {rect([4 - 10, 4 + r.params.Ld + 2])};        % Si slab incl. 10 um of waveguide
    layers = 1;
    for m = r.masks
        if m.name == "poly", shapes = m.present; else, shapes = m.absent; end
        for i = 1:size(shapes, 1)
            polys{end + 1} = rect(shapes(i, :)); layers(end + 1) = m.gdsLayer; %#ok<SAGROW>
        end
    end
    file = fullfile(tempdir, sprintf('gc_inverse_%s.gds', pr));
    orf.gdsWrite(file, struct('name', "GC_" + upper(pr), 'polygons', {polys}, 'layers', layers));
    fprintf('GDS %s: %d shapes -> %s\n', pr, numel(polys), file);
end
