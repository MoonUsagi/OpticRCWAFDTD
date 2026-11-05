function dev = makeStructure(period, incident, substrate, layers)
%MAKESTRUCTURE Solver-independent device description.
%   dev = orf.makeStructure([Lx Ly], incMat, subMat, {layer1, layer2, ...})
%
%   Layers are listed from the incident side toward the substrate (+z).
%   The unit cell spans [-Lx/2, Lx/2) x [-Ly/2, Ly/2), centred at the
%   origin. Use Inf for a non-periodic (or invariant) direction, e.g.
%   [Lx Inf] for a 1D grating. RCWA samples it with layerEps over one
%   period; FDTD samples it at its own (staggered) grid points.
arguments
    period (1,2) double {mustBePositive}
    incident (1,1) struct
    substrate (1,1) struct
    layers cell = {}
end
dev.period = period;
dev.incident = incident;
dev.substrate = substrate;
dev.layers = layers;
end
