function kz = kzNonzero(kz)
%KZNONZERO Nudge exactly grazing orders (kz = 0) off zero for RCWA.
%   At a Rayleigh anomaly (lambda = period * n / m) one diffraction order
%   is exactly grazing, kz = 0, and V = Q / lambda divides by zero. Such
%   an order carries no power, so replacing kz by a tiny value on the
%   outgoing branch (Im > 0) leaves the physics unchanged and keeps the
%   S-matrices finite. kz is normalised by k0, so 1e-8 is negligible.
tiny = 1e-8;
kz(abs(kz) < tiny) = tiny * (1 + 1i);
end
