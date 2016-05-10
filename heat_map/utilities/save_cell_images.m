function [ save_paths ] = save_cell_images( in_imgs, img_names, ...
    save_folder)
%SAVE_CELL_IMAGES Save img cell in folder
%   [ SAVE_PATHS ] = SAVE_CELL_IMAGES( IN_IMGS, IMG_NAMES, ...
%   SAVE_FOLDER) Saves IN_IMGS cell with images, in SAVE_FOLDER directory,
%   using IMG_NAMES cell with the image names with extension, full file
%   paths are supported as well for IMG_NAMES. SAVE_FOLDER contains the
%   resulting saved paths in a cell.

num_imgs = numel(in_imgs);
save_paths = cell(1, num_imgs);

for i=1:num_imgs
    % Save each image in save_folder using the names from the previous
    % full paths
    [~, file_name, file_ext] = fileparts(img_names{i});
    save_paths{i} = fullfile(save_folder, [file_name file_ext]);
    imwrite(in_imgs{i}, save_paths{i});
end

end

