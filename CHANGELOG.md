# Changelog

## 0.1.0 — first public preview

- Solvers: TMM; RCWA 1D/2D (Li factorization, batching, mirror-symmetry
  reduction); FDTD 2D TE/TM and 3D (CPML, TF/SF plane-wave and mode sources,
  plane DFT monitors, subpixel averaging, GPU single precision); slab and
  full-vector 2D mode solvers.
- Applications: metalens phase library, layout, angular-spectrum focusing,
  3D full-wave comparison; SOI grating coupler with fiber overlap,
  apodization and optimisation.
- Materials: `orf.material` (SiO2, Si, Si3N4, TiO2, Al2O3; coefficients and
  tables from the published sources), `orf.materialTaucLorentz` with a
  numerical Kramers-Kronig transform (`orf.kkEps1`).
- GDSII export: `orf.gdsWrite`, `orf.metalensToGDS`, `orf.gratingToGDS`,
  `examples/export_gds.m`.
- `orf.checkEnvironment`, `examples/GettingStarted.m`.
- RCWA stays finite at Rayleigh anomalies (an order exactly grazing).
- RCWA samples rectangles on an edge-aligned grid, so their geometry is exact
  (before: edges moved by up to half a pixel, ~5e-4 in efficiency).
- Apps: `orf.MetalensDesigner`, `orf.GratingCouplerDesigner` (programmatic
  uifigure apps; computation in `orf.metalensDesign` and the solvers).
- RCWA field reconstruction: `orf.rcwaFields`, `examples/rcwa_fields_pillar.m`.
- Geometry: `orf.shapePolygon`, `orf.slantedLayers` (sloped sidewalls), cone,
  polygon and tapered-lattice shapes in 3D FDTD, groove sidewall angle in
  `orf.gratingCouplerTE`.
- GDSII import: `orf.gdsRead`, `orf.gdsFlatten`, `orf.gdsToShapes`.
- Run control: Progress callbacks with cancellation in the solvers and flows,
  `orf.progressText`, `orf.progressDialog`, `orf.estimateResources`,
  `orf.convergeN`.
- Design files: `orf.saveDesign` / `orf.loadDesign` (JSON; materials saved as
  their recipe, so they reload exactly).
- 114 automated tests, including RCWA ↔ FDTD cross-validation in 2D and 3D and
  reference values from RETICOLO V10 (agreement to round-off) and published
  converged values for classic metallic and dielectric gratings.
