clear all;
close all;

% Code from
% http://uk.mathworks.com/matlabcentral/fileexchange/34265-nist-atomic-spectra-database-import

min_lambda = 400;
max_lambda = 700;

% Copper->Green, Sulfur->Blue, Lithium->Red, Barium->Pale-Green,
% Sodium->Yellow, Cobalt->Silver-White, Scandium->Orange
spec={'Cu', 'S', 'Li', 'Ba', 'Na', 'Co', 'Sc'};

file_dest = fileparts(mfilename('fullpath'));
file_dest = [file_dest '/fire_shader_data/'];

for i=1:size(spec, 2)
    full_name = [spec{i}, ' i'];
    nistln=nist_asd(full_name, min_lambda, max_lambda); % Get always the first isotope
    
    % Get max relative intensity
    mxrint=1;
    num_valid = 0;
    for ii=1:length(nistln)
        if ~isempty(nistln(ii).rint) && ~isempty(nistln(ii).Aki)
            num_valid = num_valid + 1;
            if nistln(ii).rint>mxrint
                mxrint=nistln(ii).rint;
            end
        end
    end
    
    % Save the normalized intensities in a variable with the wavelenghts
    norm_intensities = zeros(num_valid, 3);
    valid_ind = 1;
    
    for ii=1:length(nistln)
        if ~isempty(nistln(ii).rint) && ~isempty(nistln(ii).Aki)
            norm_intensities(valid_ind, 1) = nistln(ii).meanor;
            norm_intensities(valid_ind, 2) = nistln(ii).rint/mxrint;
            norm_intensities(valid_ind, 3) = nistln(ii).Aki;
            valid_ind = valid_ind + 1;
        end
    end
    
    % Save both variables into a file
    fileID = fopen([file_dest, spec{i}, '.specline'],'w');
    fprintf(fileID, '%d\n',num_valid);
    fprintf(fileID, '%d %d %d\n',norm_intensities');
    fclose(fileID);
end
