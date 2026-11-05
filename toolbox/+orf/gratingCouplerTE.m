%GRATINGCOUPLERTE 2D FDTD of a uniform SOI grating coupler, TE0 input.
%   res = orf.gratingCouplerTE(p) launches the TE0 slab mode toward +x into a
%   shallow-etched grating and returns the power budget and the upward
%   field for fiber overlap (see fiberCoupling). Fields of p (defaults):
%     lambda0 1.55, lambdas linspace(1.5,1.6,11), dx 0.02,
%     tSi 0.22, etch 0.07, period 0.62, ff 0.5 (unetched fraction; period
%     and ff may also be vectors of length nPer for an apodized grating),
%     nPer 20, box 2.0, nSi 3.476, nBox 1.444, nClad 1.0,
%     substrate true (Si below the BOX), useGPU false, precision "double",
%     zUp 1.0 / zDown 1.0 (monitor
%     distances above the Si top / below the Si bottom),
%     progress [] (callback, see fdtd2D),
%     sidewall 90 (groove wall angle [deg]; below 90 the groove narrows
%     with depth, ff staying the unetched fraction at the top surface,
%     i.e. the mask; drawn as 1/4-cell steps, smoothed by sub-sampling).
%   Geometry: Si core z in [0, tSi], BOX below, cladding above; grooves
%   of depth etch at the top of the core. Grating starts at x = 4 um.
%
%   res.Pinc  : incident power (net flux at the input + reflection)
%   res.R, res.Pup, res.Pdown, res.Ptrans : fractions of Pinc
%   res.xUp, res.EyUp : x grid and DFT E_y along the upward monitor
%   res.balance : 1 - (R + Pup + Pdown + Ptrans), monitor box closure
%   res.geometry : x, z, eps of the simulated cross-section
% (Protected file: the implementation is distributed as P-code.)
