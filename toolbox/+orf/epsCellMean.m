%EPSCELLMEAN Cell-averaged eps of axis-aligned boxes at grid points (xc, yc).
%   m = orf.epsCellMean(xc, yc, dx, dy, boxes, nBg, harmonicDir) averages
%   eps over nSub x nSub sub-samples of the dx x dy cell centred at each
%   point (ndgrid layout: numel(xc) x numel(yc)). boxes is K x 5
%   [x1 x2 y1 y2 n] (+-Inf allowed, later rows paint over earlier).
%   harmonicDir: "none" = arithmetic mean (field tangential to every edge),
%   "x" / "y" = harmonic mean along that direction, then arithmetic along
%   the other (field component normal to edges of constant x / y).
%   Options: NSub (default 4), WrapY = [y0 Ly] to fold y periodically.
% (Protected file: the implementation is distributed as P-code.)
