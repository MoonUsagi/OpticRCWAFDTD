function frac = fdtdProgress(t, srcEnd, maxTime, energyRatio, shutoff)
%FDTDPROGRESS Rough completion fraction of an FDTD run, for progress bars.
%   The end is not known in advance (the run stops when the field energy
%   falls below shutoff * peak), so: the first 30 % follow the source
%   pulse, the rest the decay of the energy on a log scale.
if t <= srcEnd
    frac = 0.3 * t / srcEnd;
else
    decay = log(max(energyRatio, shutoff)) / log(shutoff);     % 0 .. 1
    frac = 0.3 + 0.7 * max(0, min(1, decay));
end
frac = max(0, min(1, frac));
end
