classdef TestMaterials < matlab.unittest.TestCase
    %TESTMATERIALS Material module and kz branch selection.

    methods (TestClassSetup)
        function addPaths(~)
            run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'setupPaths.m'));
        end
    end

    methods (Test)
        function constantMaterial(tc)
            m = orf.materialConst(2.0 + 0.1i, "X");
            tc.verifyEqual(m.nk([0.5; 1.0]), [2.0 + 0.1i; 2.0 + 0.1i]);
        end

        function tableInterpolatesNodes(tc)
            lt = [0.4 0.6 0.8 1.0].'; nt = [2.5 2.4 2.35 2.3].'; kt = [0.1 0.05 0.01 0].';
            m = orf.materialTable(lt, nt, kt, "T");
            tc.verifyEqual(m.nk(lt), nt + 1i*kt, 'AbsTol', 1e-14);
        end

        function tableRejectsExtrapolation(tc)
            m = orf.materialTable([0.4 1.0].', [2 2].', [0 0].');
            tc.verifyError(@() m.nk(1.2), 'materialTable:range');
        end

        function evalMaterialsMatrix(tc)
            mats = {orf.materialConst(1), orf.materialConst(1.5)};
            n = orf.evalMaterials(mats, [0.5; 0.6; 0.7]);
            tc.verifySize(n, [3 2]);
        end

        function kzBranchOutgoing(tc)
            kz = orf.kzBranch([4, -4, -4 - 1e-15i, 4 + 1i]);
            tc.verifyGreaterThanOrEqual(imag(kz), 0);
            tc.verifyEqual(kz(1:2), [2, 2i]);
        end
    end
end
