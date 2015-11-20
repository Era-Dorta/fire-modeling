function saveErrorFunSummary( summary_file, num_samples, neigh_range, ...
    scene_name, raw_file_path, total_time )
% Writes an error function summary file to the destination given as
% parameter

% Save a summary file for the genetics algorithm solver
fileId = fopen(summary_file, 'w');
fprintf(fileId, 'Scene name is %s\n', scene_name);
fprintf(fileId, 'Number of samples is %d\n', num_samples);
fprintf(fileId, 'Neighbourhood range is [%f, %f]\n', neigh_range(1), neigh_range(2));
fprintf(fileId, 'Job took %f seconds\n', total_time);
fprintf(fileId, 'Input raw file is %s\n', raw_file_path);
fclose(fileId);

end
