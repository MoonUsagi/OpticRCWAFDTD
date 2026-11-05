function info = checkEnvironment()
%CHECKENVIRONMENT Report whether this MATLAB can run the OpticRCWAFDTD toolbox.
%   orf.checkEnvironment prints a short report; info = orf.checkEnvironment
%   also returns it as a struct.
%
%   Required : MATLAB R2023a or newer (pageeig, name=value arguments).
%   Optional : Parallel Computing Toolbox and a supported NVIDIA GPU for
%              FDTD (sim.useGPU = true). RCWA runs on the CPU by default.
info.toolboxVersion = orf.version();
info.matlab = string(version('-release'));
info.matlabOK = ~isMATLABReleaseOlderThan("R2023a");
info.parallelToolbox = license('test', 'Distrib_Computing_Toolbox') && ...
    ~isempty(ver('parallel'));
info.gpu = "none";
info.gpuOK = false;
info.gpuMessage = "";
if info.parallelToolbox
    try
        if gpuDeviceCount("available") > 0
            g = gpuDevice;
            info.gpu = string(g.Name);
            info.gpuMemoryGB = g.AvailableMemory / 1e9;
            info.gpuOK = true;
        else
            info.gpuMessage = "no supported GPU found";
        end
    catch err
        info.gpuMessage = string(err.message);   % e.g. the driver is too old
    end
else
    info.gpuMessage = "Parallel Computing Toolbox not available";
end

if nargout == 0
    fprintf('OpticRCWAFDTD %s\n', info.toolboxVersion);
    fprintf('  MATLAB %s : %s\n', info.matlab, okText(info.matlabOK, "OK", "needs R2023a or newer"));
    fprintf('  Parallel Computing Toolbox : %s\n', okText(info.parallelToolbox, "yes", "no (GPU features off)"));
    if info.gpuOK
        fprintf('  GPU : %s, %.1f GB free -> FDTD can use sim.useGPU = true\n', info.gpu, info.gpuMemoryGB);
    else
        fprintf('  GPU : not used (%s). Everything still runs on the CPU.\n', info.gpuMessage);
    end
    clear info
end
end

function s = okText(tf, yes, no)
if tf, s = yes; else, s = no; end
end
