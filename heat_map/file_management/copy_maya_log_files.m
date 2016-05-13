function copy_maya_log_files( logfile, dest_folder, ports)
% COPY_MAYA_LOG_FILES Save logs in folder
%   COPY_MAYA_LOG_FILES( LOGFILE, DEST_FOLDER, PORTS)
% Move maya log files, one for each Maya instance
try
    logs_ori_folder = fileparts(logfile);
    for i=1:numel(ports)
        log_name = ['mayaLog-' num2str(ports(i)) '.txt'];
        log_ori_path = fullfile(logs_ori_folder, log_name);
        copyfile( log_ori_path, dest_folder);
    end
catch
    disp(['Could not copy  ' log_ori_path ' to ' dest_folder]);
end
end

