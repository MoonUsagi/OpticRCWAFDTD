%% Scripting the workflow: estimates, convergence, cancelling, batch runs
% Everything the apps do is available from code, so studies can be
% automated:
%
% # estimate time and memory before a large run,
% # find the RCWA truncation automatically,
% # stop a run from a progress callback (time limit, Cancel button),
% # drive an app without its window for a parameter sweep.
%
% About 1 min.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

%% 1. Estimate before running
% Calibrated on this machine (first call ~2 s, then cached).
e1 = orf.estimateResources("rcwa", Nx=10, Ny=10, NStructures=41, NPatterned=1, Symmetry=true);
e2 = orf.estimateResources("fdtd2D", Grid=[1500 300]);
fprintf('phase library, N = 10, 41 cells : %s\n', e1.text);
fprintf('2D FDTD, 1500 x 300 grid         : %s\n', e2.text);

%% 2. Automatic convergence
% Increase N until the complex transmission (amplitude and phase) of a
% unit cell changes by less than Tol.
air = orf.material("air"); glass = orf.materialConst(1.45);
makeCell = @(d) orf.makeStructure([0.4 0.4], glass, air, ...
    {orf.makeLayer(0.5, air, {orf.shapeCircle(d/2, orf.materialConst(3.6))})});
% Ns limits the search: the cost grows ~N^6, so check orf.estimateResources first.
% The phase of resonant pillars converges slowly (about 1 % per step near
% N = 10), so ask for what the design needs: 2e-2 in amplitude is ~1 deg.
res = orf.convergeN(@(N) orf.buildPhaseLibrary(makeCell, [0.12 0.24 0.32], 0.94, N=N).t, ...
    Tol=2e-2, Ns=3:2:13);
fprintf('converged: %d, N = %d\n', res.converged, res.N);
disp(res.history)

%% 3. Stop a run from its progress callback
% Any error thrown in the callback stops the solver; the apps use the
% identifier orf:cancelled for their Cancel button. Here: a 1 s budget.
% rcwa2D reports after every batch chunk, so a small BatchSize makes it
% react quickly.
devs = arrayfun(makeCell, linspace(0.08, 0.36, 200), 'UniformOutput', false);
t0 = tic;
stopAfter = @(f, msg) assert(toc(t0) < 1, 'orf:cancelled', 'time budget used at %.0f %%', 100 * f);
try
    orf.rcwa2D(devs, 0.94, 0, 0, "s", Nx=8, BatchSize=10, Progress=stopAfter);
    disp('finished within the budget');
catch err
    fprintf('stopped: %s (%s)\n', err.message, err.identifier);
end

%% 4. Drive the Metalens Designer without its window
% params / setParams / run are the app's public methods; Visible=false
% builds it hidden. Sweep the focal length of a 15 um lens.
app = orf.MetalensDesigner(Visible=false);
cleanup = onCleanup(@() delete(app));
p = app.params();
p.D = 15; p.nLib = 25; p.N = 6;
fs = [10 15 22.5 30];
eff = zeros(size(fs)); fwhm = eff; NA = eff;
for k = 1:numel(fs)
    p.f = fs(k);
    app.setParams(p);
    r = app.run();
    eff(k) = r.metrics.efficiency; fwhm(k) = r.metrics.fwhm; NA(k) = r.NA;
end
disp(table(fs.', NA.', fwhm.', 100 * eff.', 'VariableNames', ...
    {'f_um', 'NA', 'FWHM_um', 'efficiency_pct'}))
% Higher NA: smaller spot, lower efficiency (steeper phase gradient,
% coarser sampling of it by the 0.4 um cells).

%% 5. Keep the parameters
file = fullfile(tempdir, 'lens_f30.json');
orf.saveDesign(file, struct('app', "MetalensDesigner", 'params', app.params()));
fprintf('saved %s - open it in the app with "Load design"\n', file);
