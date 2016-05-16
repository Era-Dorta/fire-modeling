function build_color_space()
%BUILD_COLOR_SPACE Compile colorspacecode
%   BUILD_COLOR_SPACE

% Go into current folder as we are giving mex relative file paths
cdir = pwd;
cd(fileparts(mfilename('fullpath')));

mex('colorspace.c');

% Return to previous folder
cd(cdir);

end

