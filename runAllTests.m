function results = runAllTests(mode)
%RUNALLTESTS Run the test suite and print a compact summary.
%   runAllTests          full suite (~6.5 min on the dev laptop)
%   runAllTests("fast")  skips tests tagged 'Slow' (3D FDTD, the
%                        RCWA <-> FDTD cross-validation) for quick checks
arguments
    mode (1,1) string {mustBeMember(mode, ["full", "fast"])} = "full"
end
import matlab.unittest.TestSuite
import matlab.unittest.selectors.HasTag
root = fileparts(mfilename('fullpath'));
setupPaths();
suite = TestSuite.fromFolder(fullfile(root, 'tests'));
if mode == "fast"
    suite = suite.selectIf(~HasTag('Slow'));
end
results = run(suite);
fprintf('%d passed, %d failed, %d incomplete (%s, %.0f s)\n', ...
    nnz([results.Passed]), nnz([results.Failed]), nnz([results.Incomplete]), ...
    mode, sum([results.Duration]));
end
