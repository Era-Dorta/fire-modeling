% Build the C/C++ files provided in the package
%
% @author: B. Schauerte
% @date:   2009
% @url:    http://cvhci.anthropomatik.kit.edu/~bschauer/

% Go into current folder as we are giving mex relative file paths
cdir = pwd;
cd(fileparts(mfilename('fullpath')));

cpp_files=dir('*.cpp');
for i=1:length(cpp_files)
    fprintf('Building %d of %d: %s\n',i,length(cpp_files),cpp_files(i).name);
    mex(cpp_files(i).name);
end

% Return to previous folder
cd(cdir);