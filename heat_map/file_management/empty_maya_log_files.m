function empty_maya_log_files( logfile, ports)
% EMPTY_MAYA_LOG_FILES Save logs in folder
%   EMPTY_MAYA_LOG_FILES( LOGFILE, PORTS)

% Empty maya log files, one for each Maya instance
logs_ori_folder = fileparts(logfile);
for i=1:numel(ports)
    log_name = ['mayaLog-' num2str(ports(i)) '.log'];
    log_ori_path = fullfile(logs_ori_folder, log_name);
    
    fileId = fopen(log_ori_path, 'w');
    
    if(fileId ~= -1)
        fclose(fileId);
    else
        error('Cannot open file %s.', log_ori_path);
    end
end
end
