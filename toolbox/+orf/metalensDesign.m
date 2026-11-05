%METALENSDESIGN Metalens flow: unit-cell library -> layout -> focal spot.
%   r = orf.metalensDesign(p) runs the steps of examples/metalens_demo_940nm
%   for a parameter struct p (defaults in brackets):
%     lambda0 [0.94], period [0.4], height [0.5] (um)
%     pillar  [orf.materialConst(3.6)] material struct or index
%     substrate [orf.materialConst(1.45)] (light enters from the substrate)
%     dMin [0.08], dMax [0.36], nLib [41]: pillar diameters of the library
%     N [8]: RCWA harmonics; pol ["s"]
%     D [20], f [20]: lens diameter and focal length (um)
%     sub [4]: field samples per cell edge for the propagation
%   Option Progress: callback progress(fraction, message); throw in it to
%   cancel (the library is ~90 % of the time).
%
%   r.lib       : orf.buildPhaseLibrary result
%   r.diameters : nc x nc pillar diameters [um] (0 outside the aperture),
%                 ready for orf.metalensToGDS(file, r.diameters, p.period)
%   r.xc        : cell centres [um]; r.x, r.focal: focal-plane grid, |E|^2
%   r.metrics   : orf.focusMetrics of the lens; r.ideal: of an ideal lens
%   r.NA, r.params (p with defaults filled in)
% (Protected file: the implementation is distributed as P-code.)
