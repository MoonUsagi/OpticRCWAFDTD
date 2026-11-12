%INVERSEDESIGNGRATINGCOUPLER Adjoint inverse design of a 2D grating coupler.
%   res = orf.inverseDesignGratingCoupler(p) optimises the mask pattern(s)
%   of an SOI grating coupler for coupling from the TE0 waveguide mode into
%   a tilted fiber. Each iteration runs, per design wavelength, one FDFD
%   solve (orf.fdfd2D) and one adjoint solve with the same LU factors,
%   which give the gradient with respect to every pixel of every mask.
%   Each mask is a density rho(x) in [0, 1] along the grating (1 =
%   material present), smoothed by a conic filter (radius MinFeature/2)
%   and pushed to 0/1 by a tanh projection whose sharpness beta rises in
%   stages; the result is binarised, features shorter than MinFeature are
%   removed, and the final design is evaluated again.
%
%   Processes (p.process):
%     "shallow" (default) one etch of depth p.etch
%     "dual"     shallow etch p.etch plus a full etch through the Si; the
%                shallow layer exists only where the full etch left Si.
%                Experimental: its optimum relies on features below 100 nm,
%                so the fabricable design is not yet better than "shallow".
%     "overlay"  shallow etch plus a poly-Si overlay of thickness p.tPoly
%                (index p.nPoly) on top of the Si, patterned by its own mask
%   A single 70 nm etch on a 2 um BOX sends at most ~57 % of the light up;
%   the overlay raises that to ~93 % (example: -0.58 dB into SMF-28, FDTD).
%
%   p: stack as in orf.gratingCouplerTE (lambda0 1.55, dx 0.02, tSi 0.22,
%   etch 0.07, box 2.0, nSi 3.476, nBox 1.444, nClad 1.0, substrate true,
%   zUp 1.0), tPoly 0.16, nPoly 3.48, and the design:
%     Ld        design length [um], from x = 4 (default 12)
%     thetaDeg  fiber tilt in the cladding (default 10)
%     w0        fiber mode radius (default 5.2, SMF-28 at 1550 nm)
%     x0        fiber centre from the grating start (default 0.42 Ld); a start
%               value when OptimizeFiber is on
%     lambdas   design wavelengths (default lambda0 + [-0.02 0 0.02])
%     init      shallow-etch start: "uniform" (period 0.62, ff 0.5; or set
%               p.period, p.ff, also as vectors) or densities, one per pixel;
%               other masks start grey (0.5) or without full etch
%   Options: MinFeature (0.1 um), FilterRadius (default MinFeature/2; larger
%   keeps the optimiser away from features the clean-up would remove), Betas ([4 8 16 32]), Iterations per
%   beta (20), Step (Adam step, 0.03), Progress (callback progress(frac,
%   msg); throw in it to cancel), Verbose (true), OptimizeFiber (true:
%   the fiber position is a design variable too; its gradient needs no
%   extra solve), FiberStep (0.1 um), Polish (1: rounds of re-optimising
%   the cleaned binary design at the last beta; the better design is kept).
%
%   res.eta        : coupling of the final binary design per res.lambdas (FDFD)
%   res.x0         : fiber centre from the grating start [um] (x = 4 + x0)
%   res.layout     : struct(boxes, length) for orf.gratingCouplerTE(struct('layout', ...))
%   res.masks      : per mask: name, z, present / absent intervals [um]
%                    (absent = etched openings of an etch mask), gdsLayer
%   res.period, res.ff : per-tooth vectors ("shallow" only), for
%                    orf.gratingCouplerTE and orf.gratingToGDS
%   res.grooves    : K x 2 shallow-etch openings [um] ("shallow" only)
%   res.minFeature : narrowest feature of any mask [um]
%   res.rho, res.x : final densities (masks x pixels) and pixel x
%   res.history    : iteration, beta, x0, coupling per wavelength (grey design)
%   res.etaStart   : coupling of the starting design
%   res.etaGrey    : coupling of the last continuous design (a large drop to
%                    res.eta means the design was not binary yet: raise Betas)
%   res.params     : p with defaults filled in
% (Protected file: the implementation is distributed as P-code.)
