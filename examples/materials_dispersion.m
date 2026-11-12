%% Materials: built-in dispersion, measured films and tables
% How to describe materials in OpticRCWAFDTD:
%
% * |orf.material(name)| - built-in dispersion formulas (SiO2, Si, Si3N4,
%   TiO2, Al2O3), each with its valid range and source
% * |orf.materialTaucLorentz| - amorphous films (a-Si, SiNx) from the
%   Tauc-Lorentz parameters of an ellipsometry report
% * |orf.materialTable| - any measured n, k table (e.g. a CSV file)
% * |orf.materialConst| - a constant index for quick studies
%
% Every material is a struct with |nk(lambda)| (n + ik, k >= 0), so all
% solvers accept all of them. Runs in a few seconds.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

%% 1. Built-in materials
% Each one is only defined inside its range; evaluating outside is an
% error rather than a silent extrapolation.
figure('Position', [100 100 640 420]); hold on
for name = ["SiO2", "Al2O3", "Si3N4", "TiO2"]
    m = orf.material(name);
    lam = linspace(max(0.4, m.range(1)), min(1.6, m.range(2)), 200);
    plot(lam, real(m.nk(lam)), 'LineWidth', 1.5, 'DisplayName', name);
end
si = orf.material("Si");
lam = linspace(si.range(1), 1.6, 100);
plot(lam, real(si.nk(lam)) - 1.5, 'LineWidth', 1.5, 'DisplayName', 'Si - 1.5');
xlabel('wavelength [\mum]'); ylabel('n'); legend('Location', 'eastoutside'); grid on
title('Built-in dispersion');
fprintf('TiO2 at 532 nm: n = %.3f   (%s)\n', real(orf.material("TiO2").nk(0.532)), ...
    orf.material("TiO2").source);

%% 2. Amorphous silicon from ellipsometry (Tauc-Lorentz)
% a-Si depends on the deposition, so there is no built-in a-Si. Put your
% film's fit here. The numbers below are typical of PECVD a-Si and only
% illustrate the call.
aSi = orf.materialTaucLorentz(122, 3.45, 2.54, 1.20, 1.15, Name="a-Si (example)");
lam = linspace(0.4, 1.6, 200);
nk = aSi.nk(lam);
figure('Position', [100 100 640 420]);
yyaxis left;  plot(lam, real(nk), 'LineWidth', 1.5); ylabel('n');
yyaxis right; semilogy(lam, imag(nk) + 1e-6, 'LineWidth', 1.5); ylabel('k');
xlabel('wavelength [\mum]'); grid on; title('a-Si, Tauc-Lorentz model');
fprintf('a-Si (example) at 940 nm: n + ik = %.3f + %.4fi\n', real(aSi.nk(0.94)), imag(aSi.nk(0.94)));

%% 3. A measured table
% Typical use: T = readmatrix("my_film.csv"); with columns lambda [um], n, k.
% Here the table is sampled from the model above to show the interpolation.
lt = linspace(0.5, 1.5, 11).';
tab = orf.materialTable(lt, real(aSi.nk(lt)), imag(aSi.nk(lt)), "a-Si table");
fprintf('table vs model at 940 nm: %.4f vs %.4f\n', real(tab.nk(0.94)), real(aSi.nk(0.94)));

%% 4. Use any material in a simulation
% A quarter-wave Si3N4 anti-reflection coating on a-Si, designed at
% 940 nm, with the real dispersion of both films (TMM takes the index of
% every layer at every wavelength).
lam = linspace(0.7, 1.3, 121).';
sin3 = orf.material("Si3N4");
d = 0.94 / (4 * real(sin3.nk(0.94)));
R0 = orf.tmm(lam, [ones(size(lam)), aSi.nk(lam)], [], 0, "s").R;
R1 = orf.tmm(lam, [ones(size(lam)), sin3.nk(lam), aSi.nk(lam)], d, 0, "s").R;
figure('Position', [100 100 640 420]);
plot(1e3 * lam, 100 * R0, 1e3 * lam, 100 * R1, 'LineWidth', 1.5); grid on
xlabel('wavelength [nm]'); ylabel('reflectance [%]');
legend('bare a-Si', sprintf('%.0f nm Si_3N_4 AR coating', 1e3 * d));
title('Dispersive materials in TMM');
fprintf('reflectance at 940 nm: bare %.1f %%, coated %.2f %%\n', ...
    100 * interp1(lam, R0, 0.94), 100 * interp1(lam, R1, 0.94));

%% 5. Materials travel with the design file
% saveDesign stores the recipe (name, table or Tauc-Lorentz parameters),
% so a loaded design has the same dispersion.
air = orf.material("air");
dev = orf.makeStructure([0.4 0.4], orf.material("SiO2"), air, ...
    {orf.makeLayer(0.5, air, {orf.shapeCircle(0.1, aSi)})});
file = fullfile(tempdir, 'aSi_cell.json');
orf.saveDesign(file, struct('device', dev, 'lambda0', 0.94));
d2 = orf.loadDesign(file);
fprintf('a-Si after save/load: %.6f (same: %d)\n', real(d2.device.layers{1}.shapes{1}.mat.nk(0.94)), ...
    d2.device.layers{1}.shapes{1}.mat.nk(0.94) == aSi.nk(0.94));
