%% How much do sloped sidewalls change a metalens phase library?
% Etched pillars are rarely vertical. This example rebuilds the 940 nm
% a-Si phase library with sidewall angles of 90, 87 and 84 degrees (the
% diameter is the one at the pillar base) and shows the phase error a
% design would inherit if it assumed vertical walls.
%
% Shows: orf.slantedLayers (staircase of thin layers), a phase library
% built from any makeCell function, comparing libraries. About 10 s.
% (An 87 deg wall already makes the top ~50 nm narrower than the base.)
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('orf.tmm')), run(fullfile(root, 'setupPaths.m')); end   % installed toolbox: already on path

lambda0 = 0.94; P = 0.4; H = 0.5; N = 6;
glass = orf.materialConst(1.45, "SiO2"); air = orf.material("air");
asi = orf.materialConst(3.6, "a-Si (placeholder)");
D = linspace(0.10, 0.34, 13);

% Light comes from the glass, so the pillar base is on the incident side:
% Base="top" puts the widest slice first.
makeCell = @(d, wall) orf.makeStructure([P P], glass, air, ...
    orf.slantedLayers(H, air, orf.shapeCircle(d/2, asi), wall, NSlices=6, Base="top"));

walls = [90 87 84];
libs = cell(size(walls));
for k = 1:numel(walls)
    tic;
    libs{k} = orf.buildPhaseLibrary(@(d) makeCell(d, walls(k)), D, lambda0, N=N);
    fprintf('sidewall %2d deg: phase span %.0f deg, mean T %.2f (%.1f s)\n', walls(k), ...
        rad2deg(libs{k}.span), mean(libs{k}.T), toc);
end

%% Compare
figure('Position', [100 100 900 360]);
subplot(1, 2, 1); hold on
for k = 1:numel(walls)
    plot(D, rad2deg(libs{k}.phase), 'o-', 'LineWidth', 1.5, 'DisplayName', sprintf('%d deg', walls(k)));
end
xlabel('base diameter [\mum]'); ylabel('phase [deg]'); grid on; legend('Location', 'northwest');
title('Phase library');
subplot(1, 2, 2); hold on
for k = 2:numel(walls)
    err = rad2deg(angle(libs{k}.t ./ libs{1}.t));
    plot(D, err, 'o-', 'LineWidth', 1.5, 'DisplayName', sprintf('%d deg vs 90', walls(k)));
    fprintf('%d deg: worst phase error %.0f deg if the design assumed vertical walls\n', ...
        walls(k), max(abs(err)));
end
xlabel('base diameter [\mum]'); ylabel('phase error [deg]'); grid on; legend;
title('Error of assuming vertical walls');

%% What to do with it
% Measure the real sidewall angle (cross-section SEM) and build the
% library with it, or compensate by choosing the base diameter for each
% target phase from the sloped library: orf.layoutFromLibrary works with
% any library. The same staircase (orf.slantedLayers) works for polygons
% and holes, and orf.gratingCouplerTE has p.sidewall for etched grooves.
