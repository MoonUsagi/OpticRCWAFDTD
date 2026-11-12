%GRATINGCOUPLERDESIGNER Interactive SOI grating coupler design (2D FDTD).
%   orf.GratingCouplerDesigner opens the app: a shallow-etched uniform
%   grating on BOX, TE0 input, coupled to a tilted Gaussian fiber mode.
%     Estimate      time and memory of one FDTD run
%     Run           orf.gratingCouplerTE + orf.bestFiberCoupling: spectrum,
%                   power budget, cross-section, upward field
%     Sweep period  five runs around the current period, keeps the best
%     Save / Load   the parameters as a design file (orf.saveDesign)
%     Export GDS    the grating with its taper (orf.gratingToGDS)
%   Si, BOX and cladding take an index or a built-in material name (Si,
%   SiO2, Si3N4, ...), evaluated at the design wavelength.
%   For apodized designs use orf.optimizeGratingCoupler (hours of FDTD).
%   app = orf.GratingCouplerDesigner(Visible=false) builds it hidden;
%   app.params / setParams / run / estimate work without the UI.
% (Protected file: the implementation is distributed as P-code.)
