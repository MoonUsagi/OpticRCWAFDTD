function [cb, dlg] = progressDialog(fig, title)
%PROGRESSDIALOG Cancellable progress dialog for apps (uiprogressdlg).
%   [cb, dlg] = orf.progressDialog(fig, title) opens a uiprogressdlg on the
%   uifigure fig and returns a callback for the solvers' Progress option.
%   The bar never moves backward. Pressing Cancel makes the next callback
%   throw 'orf:cancelled', which stops the solver; catch it in the app:
%     [cb, dlg] = orf.progressDialog(app.UIFigure, "Building library");
%     try
%         lib = orf.buildPhaseLibrary(mk, D, 0.94, Progress=cb);
%     catch err
%         if err.identifier ~= "orf:cancelled", rethrow(err); end
%     end
%     close(dlg)
arguments
    fig (1,1) matlab.ui.Figure
    title (1,1) string = "Running"
end
dlg = uiprogressdlg(fig, 'Title', title, 'Cancelable', 'on', 'Value', 0);
best = 0;
cb = @report;
    function report(frac, msg)
        if dlg.CancelRequested
            error('orf:cancelled', 'Cancelled by the user.');
        end
        best = max(best, min(1, frac));
        dlg.Value = best;
        dlg.Message = msg;
        drawnow limitrate
    end
end
