function cb = progressText(label)
%PROGRESSTEXT Progress callback that prints to the command window.
%   cb = orf.progressText(label) returns a callback for the Progress /
%   progress options of the solvers; it prints a line every 10 %.
%   Example: orf.buildPhaseLibrary(mk, D, 0.94, Progress=orf.progressText("library"))
arguments
    label (1,1) string = "progress"
end
last = -Inf;
cb = @report;
    function report(frac, msg)
        pct = floor(100 * frac / 10) * 10;
        if pct > last
            last = pct;
            fprintf('%s: %3d %%  %s\n', label, pct, msg);
        end
    end
end
