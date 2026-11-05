function bytes = gdsReal8(v)
%GDSREAL8 Encode a double as a GDSII 8-byte real (excess-64, base 16).
%   bytes = orf.gdsReal8(v) returns 8 uint8 values: sign bit, 7-bit
%   exponent E (value = mantissa * 16^(E-64)) and a 56-bit mantissa in
%   [1/16, 1). The mantissa is formed with integer arithmetic from the
%   exact binary value of v, so decoding returns v exactly.
arguments
    v (1,1) double {mustBeFinite}
end
bytes = zeros(1, 8, 'uint8');
if v == 0, return; end
neg = v < 0; v = abs(v);
[f, e2] = log2(v);                       % v = f * 2^e2, f in [0.5, 1)
sig = uint64(f * 2^53);                  % exact 53-bit integer significand
e16 = floor((e2 - 1) / 4) + 1;           % v = m * 16^e16 with m in [1/16, 1)
shift = e2 - 53 - 4 * e16 + 56;          % mantissa = sig * 2^shift
mant = bitshift(sig, shift);
exponent = e16 + 64;
assert(exponent >= 0 && exponent <= 127, 'orf:gdsReal8:range', 'Value out of GDSII range.');
bytes(1) = uint8(exponent) + uint8(128 * neg);
for k = 8:-1:2
    bytes(k) = uint8(bitand(mant, uint64(255)));
    mant = bitshift(mant, -8);
end
end
