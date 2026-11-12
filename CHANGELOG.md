# Changelog

## 0.3.0 — inverse design

- Inverse design of grating couplers with the adjoint method:
  `orf.inverseDesignGratingCoupler`. Every pixel of every mask and the
  fiber position are design variables; filtering, projection, minimum
  feature size, and a polish stage give fabricable binary designs.
  Processes: single shallow etch, shallow etch + poly-Si overlay, and an
  experimental dual (shallow + full) etch.
- Results (220 nm SOI, 2 um BOX, SMF-28 at 10 deg, 100 nm minimum feature,
  checked with the FDTD): single 70 nm etch 52.6 % (-2.79 dB);
  with a 160 nm poly-Si overlay 87.6 % (-0.58 dB).
- `orf.fdfd2D`: frequency-domain 2D TE solver with stretched-coordinate
  PML and adjoint solves; agrees with the FDTD to 1e-4 on the same grid.
- `orf.gratingCouplerTE` accepts any cross-section (`p.layout`).
- `orf.gratingToGDS` accepts a period that starts with a groove (ff = 0).
- Example `inverse_design_grating_coupler.m`; tests for the gradient
  (all processes, 2e-7 vs finite differences), FDFD vs FDTD, and the
  optimised designs.

## 0.2.0 — materials in the apps, GDS paths, tutorial and new examples

- Apps: pillar, substrate, Si, BOX and cladding accept a built-in material
  name (`TiO2`, `Si3N4`, `SiO2`, `Si`, ...) as well as an index; design files
  with measured materials (`orf.materialTable`, `orf.materialTaucLorentz`)
  load into the Metalens Designer unchanged.
- GDSII: `orf.gdsRead` converts PATH elements (waveguides, wires) to polygons
  (mitred joins; flush, round, extended or custom ends); `orf.gdsWrite`
  writes paths (`cells.paths`).
- Tutorial: `docs/TUTORIAL.md`, step-by-step in English and Traditional Chinese.
- New examples: `materials_dispersion.m`, `waveguide_modes_soi.m`,
  `metasurface_pb_phase.m` (geometric phase of TiO2 nanofins),
  `sidewall_angle_study.m`, `gmr_filter.m` (guided-mode resonance filter),
  `metalens_tio2_visible.m` (532 nm metalens to GDSII),
  `workflow_scripting.m` (estimates, convergence, cancelling, batch runs).
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
