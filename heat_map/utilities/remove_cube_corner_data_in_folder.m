function remove_cube_corner_data_in_folder(input_folder_regex)
%REMOVE_CUBE_CORNER_DATA_IN_FOLDER
files = dir(input_folder_regex);
folder = fileparts(input_folder_regex);
save_dir = fullfile(folder, 'removed_corners');

if(exist(save_dir, 'dir') == 7)
    filesIndDir = dir(save_dir);
    if(size(filesIndDir,1) > 2 || ~(size(filesIndDir,1) == 2 && ...
            (strcmp(filesIndDir(1).name,'.') && strcmp(filesIndDir(2).name,'..'))))
        disp(['Folder ' save_dir ' exists and is not empty']);
        return;
    end
else
    mkdir(save_dir);
end

doPlot = true;

f1 = figure;
f2 = figure;

for file = files'
    data = read_raw_file(fullfile(file.folder,file.name));
    clean_data = remove_cube_corner_data(data, 0.3);
    
    if doPlot
        plotHeatMap(data, 1 / max(data.v), f1);
        plotHeatMap(clean_data, 1 / max(clean_data.v), f2);
        drawnow;
    end
    
    save_path = fullfile(save_dir, file.name);
    save_raw_file(save_path, clean_data);
end

end

