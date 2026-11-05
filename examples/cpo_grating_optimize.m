%CPO_GRATING_OPTIMIZE Optimise the SOI grating coupler (2D FDTD).
%   Fixed process: 220 nm Si, 70 nm etch, 2 um BOX on Si, air cladding.
%   Fiber: SMF-28 (w0 = 5.2 um), tilt allowed 5-15 deg.
%   Stage 1: uniform grating, grid over period x fill factor (30 runs).
%   Stage 2: linearly apodized fill factor with locally phase-matched
%            periods, Nelder-Mead on [ffStart ffEnd scale] (30 runs).
%   ~45 s per FDTD run on a laptop GPU (CPU ~2.5 min): ~45 min in total.
%   The log is saved to benchmarks/results/ (development checkout) or the
%   current folder, as gc_optimize_<date>.txt.
%   Result (2026-10-14, laptop GPU, 104 min): best uniform 49.0 %, best
%   apodized 57.2 % -- but its first groove is only 30 nm wide. With a
%   100 nm minimum feature (MinFeature=0.1): 55.2 % (-2.58 dB) at 15 deg,
%   ffStart 0.875, ffEnd 0.435, scale 1.014, 25 periods.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path
logDir = fullfile(root, 'benchmarks', 'results');          % development checkout
if ~isfolder(logDir), logDir = pwd; end                     % installed toolbox: current folder
logFile = fullfile(logDir, ...
    sprintf('gc_optimize_%s.txt', char(datetime('now', 'Format', 'yyyyMMdd_HHmm'))));
diary(logFile); cleanup = onCleanup(@() diary('off'));
tic;
r = orf.optimizeGratingCoupler();
fprintf('\nSummary: original demo 48.1 %% | best uniform %.1f %% | best apodized %.1f %% (%.0f min)\n', ...
    100 * r.uniform.eta, 100 * r.apodized.eta, toc / 60);
fprintf('log saved to %s\n', logFile);
