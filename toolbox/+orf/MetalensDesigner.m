%METALENSDESIGNER Interactive metalens design: library, layout, focus.
%   orf.MetalensDesigner opens the app. Enter the unit cell (circular
%   pillars on a substrate, light from the substrate) and the lens, then
%     Estimate     time and memory of the library (orf.estimateResources)
%     Converge     smallest harmonic count N with stable cell phases
%     Run          library -> layout -> focal spot (orf.metalensDesign)
%     Cell field   |E| in one unit cell (orf.rcwaFields)
%     Save / Load  the parameters as a design file (orf.saveDesign)
%     Export GDS   the pillar layout (orf.metalensToGDS)
%   Pillar and substrate take an index (n or n+ik) or a built-in material
%   name (TiO2, Si3N4, SiO2, ...); a design file can carry any material
%   (orf.materialTable, orf.materialTaucLorentz).
%   Long runs show a progress bar with Cancel.
%   app = orf.MetalensDesigner(Visible=false) builds it hidden (scripting
%   and tests); app.params / app.setParams / app.run work without the UI.
% (Protected file: the implementation is distributed as P-code.)
