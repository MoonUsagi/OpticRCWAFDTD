%CPO_BOX_SCAN Grating-coupler efficiency vs buried-oxide (BOX) thickness.
%   Light leaking down reflects at the BOX/Si-substrate interface and
%   interferes with the upward beam, so the directionality oscillates with
%   BOX thickness (period ~ lambda / (2 n_BOX) ~ 0.54 um). Fixed design:
%   the best printable apodized grating from cpo_grating_optimize
%   (ff 0.875 -> 0.435, scale 1.014, 25 periods, 15 deg, 100 nm minimum
%   feature). Log: benchmarks/results/gc_box_scan_<date>.txt.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path
logDir = fullfile(root, 'benchmarks', 'results');          % development checkout
if ~isfolder(logDir), logDir = pwd; end                     % installed toolbox: current folder
logFile = fullfile(logDir, ...
    sprintf('gc_box_scan_%s.txt', char(datetime('now', 'Format', 'yyyyMMdd_HHmm'))));
diary(logFile); cleanup = onCleanup(@() diary('off'));

base = struct('lambdas', 1.50:0.01:1.60, 'useGPU', gpuDeviceCount > 0);
[per, ff] = orf.apodizedGrating(0.875, 0.435, 15, 25, 1.014, base);
ff = min(max(ff, 0.1 ./ per), 1 - 0.1 ./ per);          % 100 nm rule, as optimised
boxes = 1.6:0.1:3.0;
fprintf('BOX [um]   eta     dB     theta  Pup    Pdown  1-dB band [nm]\n');
res = struct('box', num2cell(boxes), 'eta', 0, 'Pup', 0, 'theta', 0);
tic;
for k = 1:numel(boxes)
    q = base; q.period = per; q.ff = ff; q.nPer = 25; q.box = boxes(k);
    r = orf.gratingCouplerTE(q);
    b = orf.bestFiberCoupling(r, 5:0.5:15);
    [~, iL] = min(abs(r.lambdas - 1.55));
    fprintf('  %.1f     %.3f  %6.2f   %4.1f   %.3f  %.3f   %.0f-%.0f\n', boxes(k), b.eta, b.dB, ...
        b.theta, b.Pup, r.Pdown(iL), 1e3 * b.band1dB);
    res(k).eta = b.eta; res(k).Pup = b.Pup; res(k).theta = b.theta;
end
[~, kb] = max([res.eta]);
fprintf('\nbest BOX %.1f um: %.1f %% (%.2f dB) at %.1f deg; reference BOX 2.0 um: %.1f %% (%.0f min)\n', ...
    boxes(kb), 100 * res(kb).eta, 10 * log10(res(kb).eta), res(kb).theta, ...
    100 * res(boxes == 2.0).eta, toc / 60);
fprintf('log saved to %s\n', logFile);
