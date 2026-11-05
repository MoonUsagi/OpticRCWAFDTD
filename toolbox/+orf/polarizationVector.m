function E = polarizationVector(khat, pol)
%POLARIZATIONVECTOR Unit incident E for "s", "p" or Jones [aTE aTM].
%   aTE = z x khat (y-hat at normal incidence), aTM = aTE x khat.
if isstring(pol) || ischar(pol)
    pol = string(pol);
    assert(any(pol == ["s", "p"]), 'rcwa:pol', 'pol must be "s", "p" or [aTE aTM].');
    jones = double(pol == ["s", "p"]);
else
    jones = pol(:).';
    assert(numel(jones) == 2, 'rcwa:pol', 'Jones vector must be [aTE aTM].');
end
if abs(khat(1)) < 1e-12 && abs(khat(2)) < 1e-12
    aTE = [0; 1; 0];
else
    aTE = cross([0; 0; 1], khat);
    aTE = aTE / norm(aTE);
end
aTM = cross(aTE, khat);
E = jones(1) * aTE + jones(2) * aTM;
E = E / norm(E);
end
