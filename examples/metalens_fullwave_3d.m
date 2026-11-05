%METALENS_FULLWAVE_3D Full 3D FDTD of a metalens vs the RCWA+LPA prediction.
%   preset "laptop": D = f = 3 um, ~3.5e6 cells, ~5 min on a T550 laptop GPU.
%   preset "3090"  : D = f = 10 um, ~4.6e7 cells (~3 GB); chosen when > 10 GB free.
%   preset "3090-large": D = f = 20 um, ~1.5e8 cells (~10 GB); set it by hand.
%   Laptop result (2026-10-13): FDTD vs LPA FWHM 1.155 vs 1.161 um and
%   efficiency 82 vs 78 % at f; both peak at ~0.44 f (Fresnel number ~0.8,
%   strong focal shift). See metalensFullWave3D for the method.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

preset = "laptop";
if gpuDeviceCount > 0
    g = gpuDevice;
    if g.AvailableMemory > 10e9, preset = "3090"; end
end
tic;
r = orf.metalensFullWave3D(struct('preset', preset));
fprintf('preset %s: %.2e cells, %d steps, FDTD %.0f s, total %.0f s\n', ...
    preset, r.cells, r.steps, r.wallTime, toc);
fprintf('NA %.3f, diffraction limit %.3f um\n', r.NA, r.fwhmLimit);
for name = ["fdtd", "lpa"]
    m = r.(name);
    fprintf('%-4s: at f FWHM %.3f um, eff %5.1f %% | peak at %.2f f: FWHM %.3f um, eff %5.1f %%\n', ...
        upper(name), m.fwhm, 100 * m.efficiency, m.zPeakRel, m.fwhmAtPeak, 100 * m.efficiencyAtPeak);
end
