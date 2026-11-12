%% Getting Started with OpticRCWAFDTD
% A five-minute tour of the toolbox: thin films (TMM), gratings (RCWA),
% time-domain simulation (FDTD) and a metalens unit-cell library.
% Every function lives in the |orf| namespace, e.g. |orf.rcwa2D|.
%
% *Conventions* (identical in every solver): time dependence exp(-i*w*t),
% lengths in micrometres, z is the stacking / propagation direction,
% lossy materials have Im(n) > 0. Run |orf.checkEnvironment| to see
% whether a GPU can be used.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path
orf.checkEnvironment

%% 1. Thin-film stack with the transfer-matrix method
% Quarter-wave anti-reflection coating on glass at 550 nm: reflection
% vanishes at the design wavelength.
lam = linspace(0.4, 0.8, 201).';
nc = sqrt(1.52);                                   % ideal coating index
film = orf.tmm(lam, [1 nc 1.52], 0.55 / (4*nc), 0, "s");
bare = orf.tmm(lam, [1 1.52], [], 0, "s");
figure; plot(1e3*lam, 100*bare.R, 1e3*lam, 100*film.R, 'LineWidth', 1.5);
xlabel('wavelength [nm]'); ylabel('reflectance [%]'); legend('bare glass', 'with AR coating');
title('TMM: quarter-wave anti-reflection coating');

%% 2. Materials
% Built-in materials carry their source and valid range; amorphous films
% (e.g. a-Si) come from your ellipsometry's Tauc-Lorentz parameters.
lamM = linspace(1.25, 1.65, 81);
figure; plot(lamM, real(orf.material("Si").nk(lamM)), lamM, real(orf.material("Si3N4").nk(lamM)) + 1.5, ...
    lamM, real(orf.material("SiO2").nk(lamM)) + 2, 'LineWidth', 1.5);
xlabel('wavelength [\mum]'); ylabel('n'); legend('Si', 'Si_3N_4 + 1.5', 'SiO_2 + 2');
title('Built-in dispersion'); disp(orf.material("Si").source)

%% 3. Diffraction grating with RCWA
% Silicon lines in air on glass. A structure is built from materials,
% layers and shapes; rcwa1D returns every diffraction order.
air = orf.materialConst(1); glass = orf.materialConst(1.45); si = orf.materialConst(3.48);
grating = orf.makeStructure([0.7 Inf], air, glass, ...
    {orf.makeLayer(0.5, air, {orf.shapeRect(0.35, Inf, si)})});
lams = linspace(1.0, 1.7, 141);
T = zeros(size(lams)); R = T;
for k = 1:numel(lams)
    o = orf.rcwa1D(grating, lams(k), 0, 0, "p", N=15);
    T(k) = o.Ttot; R(k) = o.Rtot;
end
figure; plot(lams, T, lams, R, lams, R + T, '--', 'LineWidth', 1.5);
xlabel('wavelength [\mum]'); legend('T', 'R', 'R + T (lossless: 1)'); ylim([0 1.05]);
title('RCWA: silicon grating, TM');

%% 4. Metalens unit cells: phase library with 2D RCWA
% Circular a-Si pillars (n = 3.6, placeholder) on SiO2 at 940 nm. One
% batched call evaluates every diameter; mirror symmetry is used
% automatically at normal incidence.
asi = orf.materialConst(3.6);
makeCell = @(D) orf.makeStructure([0.4 0.4], glass, air, ...
    {orf.makeLayer(0.5, air, {orf.shapeCircle(D/2, asi)})});
lib = orf.buildPhaseLibrary(makeCell, linspace(0.08, 0.36, 15), 0.94, N=6);
figure; yyaxis left; plot(lib.param, rad2deg(lib.phase), 'o-'); ylabel('phase [deg]');
yyaxis right; plot(lib.param, lib.T, 's-'); ylabel('transmittance'); ylim([0 1]);
xlabel('pillar diameter [\mum]'); title(sprintf('Phase library: %.0f deg coverage', rad2deg(lib.span)));

%% 5. Time-domain simulation with 2D FDTD
% A plane wave through a 0.5 um slab (periodic in z, PML in x). One run
% gives the whole spectrum; it must agree with TMM.
dx = 0.01; x = (0:dx:6).'; z = (0:3).' * dx;
lamF = linspace(1.2, 1.8, 13);
s = struct('x', x, 'z', z, 'npml', [20 0], 'periodicZ', true, 'lambdas', lamF, ...
    'monitors', [61 501]);
s.source = struct('ix', 101, 'profile', ones(4, 1), 'neff', 1, 'lambda0', 1.5, 'bw', 0.3);
s.eps = ones(numel(x), 4);                         % empty run for normalisation
o0 = orf.fdtd2DTE(s);
s.eps = orf.epsFromBoxes(x, z, 1, [3.0 3.5 -Inf Inf 2.0]);
o1 = orf.fdtd2DTE(s);
Rf = -o1.flux(1, :) ./ o0.flux(2, :);
Rt = arrayfun(@(l) orf.tmm(l, [1 2 1], 0.5, 0, "s").R, lamF);
figure; plot(lamF, Rt, '-', lamF, Rf, 'o', 'LineWidth', 1.5);
xlabel('wavelength [\mum]'); ylabel('reflectance'); legend('TMM', 'FDTD');
title(sprintf('FDTD vs TMM: max difference %.1e', max(abs(Rf - Rt))));

%% Next steps
% * |docs/TUTORIAL.md| - step-by-step guide (English and Chinese)
% * |orf.MetalensDesigner| and |orf.GratingCouplerDesigner| - the same flows as apps
% * |examples/materials_dispersion.m| - built-in, measured and Tauc-Lorentz materials
% * |examples/metalens_tio2_visible.m| - visible metalens from parameters to GDSII
% * |examples/metasurface_pb_phase.m| - geometric phase of rotated nanofins
% * |examples/gmr_filter.m|, |examples/waveguide_modes_soi.m|,
%   |examples/sidewall_angle_study.m|, |examples/workflow_scripting.m|
% * |examples/rcwa_fields_pillar.m| - the field inside a metalens unit cell
% * |examples/metalens_demo_940nm.m| - full metalens: library, layout, focus
% * |examples/metalens_fullwave_3d.m| - 3D FDTD of a metalens vs RCWA+LPA
% * |examples/cpo_grating_coupler_1550.m| - SOI grating coupler to a fiber
% * |examples/cpo_grating_optimize.m| - apodized coupler optimisation
% * |orf.saveDesign("cell.json", struct('device', grating))| keeps a design;
%   |orf.loadDesign| reads it back ready to simulate.
% * |help orf| lists every function.
