%METALENSFULLWAVE3D Full 3D FDTD of a small metalens vs the RCWA+LPA prediction.
%   res = orf.metalensFullWave3D(cfg) builds an a-Si pillar metalens on SiO2
%   from the RCWA phase library (same pipeline as metalens_demo_940nm),
%   simulates it with fdtd3D, propagates the transmitted near field to the
%   focal plane, and compares focal spot and efficiency with the local
%   periodic approximation (LPA) of the same lens.
%
%   cfg fields (defaults):
%     preset    "laptop" (D = 3 um, d = 25 nm, ~3e6 cells) or "3090"
%               (D = 10 um, d = 20 nm, ~4.6e7 cells, ~3 GB on the GPU) or
%               "3090-large" (D = 20 um, ~1.5e8 cells, ~10 GB)
%     lambda0 0.94, P 0.4, H 0.5, nPillar 3.6 (placeholder a-Si), nSub 1.45
%     D, f (= D, NA ~ 0.45), d, margin (bare substrate around the lens)
%     useGPU (default: true if a GPU is present), precision "single"
%     libDiameters (default linspace(0.08, 0.36, 41)), libN (10)
%     progress (callback for the FDTD run, see orf.fdtd2D)
%
%   res: fwhm / efficiency / zPeak for "fdtd" and "lpa", fwhmLimit, NA,
%        cells, steps, wallTime, gbEstimate, converged
% (Protected file: the implementation is distributed as P-code.)
