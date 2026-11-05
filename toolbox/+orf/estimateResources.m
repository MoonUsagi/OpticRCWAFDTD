function est = estimateResources(kind, opts)
%ESTIMATERESOURCES Memory and run-time estimate before a large simulation.
%   est = orf.estimateResources("rcwa", Nx=10, Ny=10, NStructures=40,
%                               NPatterned=1, Symmetry=true)
%   est = orf.estimateResources("fdtd3D", Grid=[nx ny nz], Steps=..., UseGPU=true,
%                               Precision="single")
%   est = orf.estimateResources("fdtd2D", Grid=[nx nz], Steps=..., UseGPU=false)
%
%   est.memoryGB, est.seconds, est.text (one-line summary) and the inputs
%   used. Times come from a short calibration on this machine (eig speed
%   for RCWA, a 200-step run of the FDTD solver; ~1-3 s on the first call,
%   then cached), so they follow the hardware, e.g. a laptop vs an RTX 3090.
%   FDTD stops when the fields have decayed, so the step count is not
%   known in advance: Steps defaults to 25 x the longest grid dimension
%   (the order seen for grating couplers and metalenses); pass your own.
%   Expect the estimate to be within a factor of ~2.
arguments
    kind (1,1) string {mustBeMember(kind, ["rcwa", "fdtd2D", "fdtd3D"])}
    opts.Nx (1,1) double = 10
    opts.Ny (1,1) double = -1
    opts.NStructures (1,1) double = 1
    opts.NPatterned (1,1) double = 1
    opts.Symmetry (1,1) logical = false
    opts.Grid (1,:) double = []
    opts.Steps (1,1) double = NaN
    opts.UseGPU (1,1) logical = false
    opts.Precision (1,1) string {mustBeMember(opts.Precision, ["single", "double"])} = "double"
end
switch kind
    case "rcwa"
        Ny = opts.Ny; if Ny < 0, Ny = opts.Nx; end
        M = (2*opts.Nx + 1) * (2*Ny + 1);
        D = 2*M / (1 + 3*opts.Symmetry);                  % mirror symmetry: ~4x smaller
        perLayer = 12 * D^2 * 16;                         % P, Q, W, V, S blocks, temporaries
        chunk = max(1, floor(2e8 / (16 * (2*M)^2)));      % rcwa2D batches ~200 MB
        est.memoryGB = min(opts.NStructures, chunk) * perLayer / 1e9 + 2*M * 2*M * 16 / 1e9;
        % measured: a patterned layer costs ~3 complex eigs of size D
        est.seconds = 3 * eigTime(round(D)) * opts.NStructures * opts.NPatterned;
        est.harmonics = M;
        est.text = sprintf(['RCWA: %d harmonics (%d unknowns per layer), %d structure(s) x %d ' ...
            'patterned layer(s): ~%.2g GB, ~%s'], M, round(D), opts.NStructures, ...
            opts.NPatterned, est.memoryGB, duration(seconds(est.seconds), 'Format', 'hh:mm:ss'));
    otherwise
        dims = 2 + (kind == "fdtd3D");
        assert(numel(opts.Grid) == dims, 'orf:estimateResources:grid', ...
            'Grid must have %d entries for %s.', dims, kind);
        cells = prod(opts.Grid);
        steps = opts.Steps;
        if isnan(steps), steps = 25 * max(opts.Grid); end
        bytes = 4 * (1 + (opts.Precision == "double"));
        nArrays = 3 + 9 * (kind == "fdtd3D");              % fields + update coefficients
        est.memoryGB = nArrays * cells * bytes / 1e9;
        rate = stencilRate(dims, opts.UseGPU, opts.Precision);
        est.seconds = cells * steps / rate;
        est.cells = cells; est.steps = steps; est.cellsPerSecond = rate;
        dev = "CPU"; if opts.UseGPU, dev = "GPU"; end
        est.text = sprintf('%s: %.2g cells, ~%d steps on the %s (%s): ~%.2g GB, ~%s', kind, ...
            cells, round(steps), dev, opts.Precision, est.memoryGB, ...
            duration(seconds(est.seconds), 'Format', 'hh:mm:ss'));
end
end

function t = eigTime(D)
% time of one complex eig of size D, measured at that size (up to 1500;
% beyond, scaled as D^3 from 1500) and cached
persistent cache
Dm = min(D, 1500);
if isempty(cache), cache = containers.Map('KeyType', 'double', 'ValueType', 'double'); end
if ~isKey(cache, Dm)
    A = complex(randn(Dm), randn(Dm));
    eig(A);                                          % warm-up
    nRep = max(1, ceil(0.2 / (2e-9 * Dm^3)));       % ~0.2 s of repeats for small D
    tic; for k = 1:nRep, eig(A); end
    cache(Dm) = toc / nRep;
end
t = cache(Dm) * (D / Dm)^3;
end

function r = stencilRate(dims, useGPU, precision)
% cell updates per second of orf.fdtd2D / orf.fdtd3D on this machine,
% from a short run of the real solver (~0.3 s, cached per setting)
persistent cache
key = sprintf('d%d_g%d_%s', dims, useGPU, precision);
if isempty(cache), cache = struct(); end
if ~isfield(cache, key)
    d = 0.02; nSteps = 200 - 140 * (dims == 3);      % grids sized like real runs
    common = {'lambdas', [1.4 1.5 1.6], 'useGPU', useGPU, 'precision', precision, 'shutoff', 0};
    if dims == 2
        x = (0:999).' * d; z = (0:249).' * d;          % with x and z monitors, as a coupler
        sim = struct('x', x, 'z', z, 'eps', ones(1000, 250), 'npml', [15 15], ...
            'monitors', [40 960], 'monitorsZ', [30 220], common{:});
        sim.source = struct('ix', 30, 'profile', ones(250, 1), 'neff', 1, 'lambda0', 1.5, 'bw', 0.2);
        sim.maxTime = nSteps * 0.99 / sqrt(2) * d;
        run = @() orf.fdtd2D(sim);
    else
        n = 96; x = (0:n-1).' * d; z = (0:2*n-1).' * d;
        src = struct('axis', 3, 'index', 20, 'Ea', ones(n), 'Eb', zeros(n), 'Ha', zeros(n), ...
            'Hb', ones(n), 'neff', 1, 'lambda0', 1.5, 'bw', 0.2);
        sim = struct('x', x, 'y', x, 'z', z, 'npml', [0 0 10], 'periodic', [true true false], ...
            'source', src, 'monitors', struct('axis', {3, 3}, 'index', {15, 2*n - 15}), common{:});
        sim.eps = orf.epsComponents3D(x, x, z, 1, {}, NSub=1);
        sim.maxTime = nSteps * 0.99 / sqrt(3) * d;
        run = @() orf.fdtd3D(sim);
    end
    w = warning('off', 'fdtd2D:notConverged'); w3 = warning('off', 'fdtd3D:notConverged');
    restore = onCleanup(@() warning([w w3]));
    run();                                           % warm-up (compilation, GPU init)
    tic; o = run(); t = toc;
    cells = numel(sim.x) * numel(sim.z);
    if dims == 3, cells = cells * numel(sim.y); end
    cache.(key) = cells * o.steps / t;
end
r = cache.(key);
end
