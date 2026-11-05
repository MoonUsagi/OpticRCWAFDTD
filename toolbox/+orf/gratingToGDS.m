%GRATINGTOGDS Write a (uniform or apodized) 1D grating coupler to GDSII.
%   info = orf.gratingToGDS(file, period, ff) draws the coupler of
%   orf.gratingCouplerTE in the chip plane: light arrives along +x from a
%   single-mode waveguide, through a linear taper, into the grating.
%   period and ff (unetched fraction of each period) are scalars or
%   vectors (apodized, e.g. from orf.apodizedGrating).
%
%   Layers (PDK conventions differ; set them to match yours):
%     SiLayer    full-thickness silicon: waveguide, taper, grating slab
%     EtchLayer  shallow-etch openings: one rectangle per groove
%   Options: NPer (if period and ff are scalars, default 20), Width
%   (grating width, 12 um), WgWidth (0.5 um), TaperLength (300 um),
%   WgLength (10 um), Margin (Si beyond the last groove, 2 um),
%   SiLayer (1), EtchLayer (2), DbUnit (1e-3 um), Cell ("GRATING_COUPLER").
%   The grating starts at x = 0; the taper occupies x < 0.
%   info: grooves (nGrooves x 2 [x1 x2] in um), nGrooves, file.
% (Protected file: the implementation is distributed as P-code.)
