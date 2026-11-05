function res = convergeN(fun, opts)
%CONVERGEN Raise the RCWA truncation until the result stops changing.
%   res = orf.convergeN(fun) calls q = fun(N) for N = 3, 5, 7, ... and stops
%   when two successive results differ by less than Tol (max abs over the
%   elements of q, e.g. efficiencies, or a complex amplitude to include the
%   phase). fun is typically
%     fun = @(N) orf.rcwa2D(dev, lambda0, 0, 0, "s", Nx=N).Ttot
%   Options: Tol (1e-3), Ns (list to try, default 3:2:25), Progress
%   (callback progress(fraction, message); throw in it to cancel).
%   res.N (first N that met Tol, or the last tried), res.value (fun(res.N)),
%   res.converged, res.history (table N, change, seconds).
%   Each step runs a larger problem (cost ~ N^6 in 2D); check the time of
%   the largest N first with orf.estimateResources.
arguments
    fun (1,1) function_handle
    opts.Tol (1,1) double {mustBePositive} = 1e-3
    opts.Ns (1,:) double {mustBeInteger, mustBeNonnegative} = 3:2:25
    opts.Progress = []
end
Ns = opts.Ns;
change = NaN(numel(Ns), 1); secs = change;
prev = [];
res.converged = false;
for k = 1:numel(Ns)
    if ~isempty(opts.Progress)
        opts.Progress((k - 1) / numel(Ns), sprintf('N = %d', Ns(k)));
    end
    tic; q = fun(Ns(k)); secs(k) = toc;
    if ~isempty(prev)
        change(k) = max(abs(q(:) - prev(:)));
    end
    prev = q;
    res.N = Ns(k); res.value = q;
    if change(k) < opts.Tol
        res.converged = true;
        break
    end
end
n = find(~isnan(secs), 1, 'last');
res.history = table(Ns(1:n).', change(1:n), secs(1:n), 'VariableNames', ["N", "change", "seconds"]);
if ~res.converged
    warning('orf:convergeN:notConverged', 'Not converged to %g by N = %d (last change %.2g).', ...
        opts.Tol, res.N, change(n));
end
end
