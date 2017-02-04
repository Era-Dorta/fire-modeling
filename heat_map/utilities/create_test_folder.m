function create_test_folder( output_img_folder_name, opts)
%CREATE_TEST_FOLDER
if isunix && isfield(opts, 'use_ram_fs') && opts.use_ram_fs
    % Create a RAM file system
    ram_dir = fullfile('/dev/shm/', output_img_folder_name);
    if(exist(ram_dir, 'dir'))
        error(['Test folder exists in RAM file system ' ram_dir ...
            ', delete it or move it to ' opts.scene_img_folder]);
    end
    mkdir(ram_dir);
    system(['ln -s ' ram_dir ' ' opts.scene_img_folder]);
else
    mkdir(fullfile(opts.scene_img_folder, output_img_folder_name));
end
end

