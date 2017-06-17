function generate_all_test_data()
%GENERATE_ALL_TEST_DATA Generates args_test.mat files
%   GENERATE_ALL_TEST_DATA fills the heat_map/test/data folder by executing
%   all the heat_map/test/functions/args_test<digit> functions

current_dir = fileparts(mfilename('fullpath'));
args_files_folders = dir(fullfile(current_dir, 'functions'));
args_files_folders = {args_files_folders.name};

% Remove anything that is not args_test[digit]
to_del_idx = [];
for i=1:numel(args_files_folders)
    if isempty(regexp(args_files_folders{i},'args_test[0-9]+', 'ONCE'))
        to_del_idx = [to_del_idx; i];
    end
    % Test 76 is video test, so it's a special case that does not need to
    % generate a .mat file
    if strcmp(args_files_folders{i}, 'args_test76.m')
        to_del_idx = [to_del_idx; i];
    end
end
args_files_folders(to_del_idx) = [];

for i=1:numel(args_files_folders)
    [~, foo_name] = fileparts(args_files_folders{i});
    feval(foo_name);
end

end

