function move_temp_files( output_img_folder_name, opts )
%MOVE_TEMP_FILES
if isunix && isfield(opts, 'use_ram_fs') && opts.use_ram_fs
    % If using ram filesystem, move the files from ram to disk
    local_dir = fullfile(opts.scene_img_folder, output_img_folder_name);
    ram_dir = fullfile('/dev/shm/', output_img_folder_name);
    delete(fileparts(local_dir)); % Delete the link, fileparts is needed
    movefile(ram_dir, local_dir);
end
end

