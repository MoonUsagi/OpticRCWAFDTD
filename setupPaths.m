function setupPaths()
%SETUPPATHS Put the orf package on the MATLAB path (development checkout).
%   All functions live in toolbox/+orf and are called as orf.<name>,
%   e.g. orf.rcwa2D. An installed toolbox (.mltbx) does this itself.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'toolbox'));
end
