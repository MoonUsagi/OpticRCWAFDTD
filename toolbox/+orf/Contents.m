% OpticRCWAFDTD  RCWA, FDTD and mode solvers for metalenses and fiber couplers
% Version 0.2.0
%
% Call every function with the orf prefix, e.g. orf.rcwa2D. Start with
% orf.checkEnvironment and examples/GettingStarted.m.
%
% Setup
%   orf.version                 - Version of the OpticRCWAFDTD toolbox (semantic versioning).
%   orf.checkEnvironment        - Report whether this MATLAB can run the OpticRCWAFDTD toolbox.
%
% Materials and geometry
%   orf.material                - Built-in dispersive materials: air, SiO2, Si, Si3N4, TiO2, Al2O3.
%   orf.materialTaucLorentz     - Amorphous films (a-Si, SiN_x) from Tauc-Lorentz ellipsometry fits.
%   orf.materialConst           - Non-dispersive material with constant complex index.
%   orf.materialTable           - Dispersive material from tabulated n, k data.
%   orf.evalMaterials           - Evaluate a list of materials into an index matrix.
%   orf.makeStructure           - Solver-independent device description.
%   orf.makeLayer               - One z-uniform layer: a background material plus shapes.
%   orf.shapeRect               - Axis-aligned rectangle inside a layer's unit cell.
%   orf.shapeCircle             - Circular pillar cross-section inside a layer's unit cell.
%   orf.shapePolygon            - Polygonal cross-section inside a layer's unit cell.
%   orf.slantedLayers           - Staircase of layers for a structure with sloped sidewalls.
%   orf.layerEps                - Sample a layer's relative permittivity on a grid.
%   orf.cellGrid                - Cell-centred sample points over one unit cell.
%   orf.alignedSampleCount      - Sample count that puts rectangle edges on pixel boundaries.
%   orf.structureToTMM          - Convert a homogeneous-layer structure to tmm inputs.
%
% Thin films
%   orf.tmm                     - 1D transfer-matrix method (Abeles characteristic matrix).
%
% RCWA
%   orf.rcwa1D                  - RCWA for gratings periodic in x (invariant in y), incl. conical.
%   orf.rcwa2D                  - RCWA for crossed gratings, batched over a set of structures.
%   orf.rcwaFields              - Electromagnetic field inside and around a grating (RCWA).
%   orf.convergeN               - Raise the RCWA truncation until the result stops changing.
%
% FDTD
%   orf.fdtd2D                  - 2D FDTD in the xz plane, TE (Ey, Hx, Hz) or TM (Hy, Ex, Ez).
%   orf.fdtd2DTE                - 2D FDTD in the xz plane, TE polarisation (Ey, Hx, Hz).
%   orf.fdtd3D                  - 3D FDTD on a Yee grid. Real fields, H~ = eta0*H, time c0*t [um].
%   orf.epsFromBoxes            - Cell-averaged permittivity of axis-aligned boxes on an xz grid.
%   orf.epsComponents2D         - Permittivity at each Yee field location, with subpixel averaging.
%   orf.epsComponents3D         - Permittivity at the 3D Yee E locations, subpixel averaged.
%   orf.cpmlCoefficients        - Convolutional PML (Roden & Gedney 2000) update coefficients.
%
% Mode solvers
%   orf.slabModes               - Guided modes of a 1D index profile n(z) by finite differences.
%   orf.wgModes2D               - Full-vector modes of a waveguide cross-section (Yee-grid FD).
%
% Metalens
%   orf.metalensDesign          - Metalens flow: unit-cell library -> layout -> focal spot.
%   orf.buildPhaseLibrary       - Zero-order transmission of a unit-cell sweep (RCWA).
%   orf.targetPhaseHyperbolic   - Phase that focuses a normal plane wave to (0,0,f).
%   orf.layoutFromLibrary       - Pick the library cell that best realises each target phase.
%   orf.angularSpectrum         - Exact scalar propagation of a sampled field by distance z.
%   orf.focusMetrics            - Spot size and focusing efficiency in the focal plane.
%   orf.metalensFullWave3D      - Full 3D FDTD of a small metalens vs the RCWA+LPA prediction.
%
% Fiber couplers (CPO)
%   orf.gratingCouplerTE        - 2D FDTD of a uniform SOI grating coupler, TE0 input.
%   orf.fiberCoupling           - Grating-to-fiber efficiency from the upward DFT field.
%   orf.bestFiberCoupling       - Best fiber position/angle for a grating-coupler run.
%   orf.apodizedGrating         - Linearly apodized fill factor with phase-matched periods.
%   orf.optimizeGratingCoupler  - Uniform grid scan, then Nelder-Mead on an apodized design.
%
% Apps and run control
%   orf.MetalensDesigner        - Interactive metalens design: library, layout, focus.
%   orf.GratingCouplerDesigner  - Interactive SOI grating coupler design (2D FDTD).
%   orf.estimateResources       - Memory and run-time estimate before a large simulation.
%   orf.progressText            - Progress callback that prints to the command window.
%   orf.progressDialog          - Cancellable progress dialog for apps (uiprogressdlg).
%
% Saving designs
%   orf.saveDesign              - Save a design (structure, materials, parameters) as a JSON file.
%   orf.loadDesign              - Read a design saved by orf.saveDesign.
%
% Layout (GDSII export and import)
%   orf.gdsWrite                - Write a GDSII stream file (polygons, paths and cell references).
%   orf.metalensToGDS           - Write a metalens pillar layout to GDSII.
%   orf.gratingToGDS            - Write a (uniform or apodized) 1D grating coupler to GDSII.
%   orf.gdsRead                 - Read a GDSII stream file.
%   orf.gdsFlatten              - All polygons of a GDSII cell in absolute coordinates.
%   orf.gdsToShapes             - Turn imported GDSII polygons into RCWA layer shapes.
%
% Lower-level building blocks (convolution matrices, S-matrices, mode
% helpers) are also in the orf namespace; see "help orf.<name>".
