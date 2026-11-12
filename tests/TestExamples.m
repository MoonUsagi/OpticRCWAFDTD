classdef TestExamples < matlab.unittest.TestCase
    %TESTEXAMPLES The quick example scripts run without errors (figures
    %   hidden). Long ones (optimisation, 3D FDTD, BOX scan) are left out.

    properties (TestParameter)
        script = {'GettingStarted', 'materials_dispersion', 'metalens_tio2_visible', ...
            'metasurface_pb_phase', 'sidewall_angle_study', 'rcwa_fields_pillar', ...
            'waveguide_modes_soi', 'export_gds'}
    end

    methods (TestClassSetup)
        function setup(tc)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
            old = get(0, 'DefaultFigureVisible');
            set(0, 'DefaultFigureVisible', 'off');
            tc.addTeardown(@() set(0, 'DefaultFigureVisible', old));
        end
    end

    methods (Test, TestTags = {'Slow'})
        function runs(tc, script)
            file = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'examples', [script '.m']);
            tc.addTeardown(@() close('all', 'force'));
            tc.verifyWarningFree(@() runScript(file));
        end
    end
end

function runScript(file)
evalc('run(file)');            % own workspace; output suppressed
end
