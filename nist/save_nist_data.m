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
    
    % Save the normalized intensities, wavelengths, A21, E1, E2, g1, g2
    specline_data = zeros(num_valid, 7);
    valid_ind = 1;
    
    for ii=1:length(nistln)
        if ~isempty(nistln(ii).rint) && ~isempty(nistln(ii).Aki)
            specline_data(valid_ind, 1) = nistln(ii).meanor;
            specline_data(valid_ind, 2) = nistln(ii).rint/mxrint;
            specline_data(valid_ind, 3) = nistln(ii).Aki;
            % Energies come in cm^-1, convert to nm^-1
            specline_data(valid_ind, 4) = nistln(ii).Ei * 1e-7;
            specline_data(valid_ind, 5) = nistln(ii).Ek * 1e-7;
            % g1 and g2 are in a string '%d - %d'
            C = textscan(nistln(ii).gigk,'%d%s%d');
            specline_data(valid_ind, 6) = C{1};
            specline_data(valid_ind, 7) = C{3};
            valid_ind = valid_ind + 1;
        end
    end
    
    % Save the data into a file
    fileID = fopen([file_dest, spec{i}, '.specline'],'w');
    % First line number of data lines in the file
    fprintf(fileID, '%d\n',num_valid);
    % Each file line corresponds to a visible is a spectrum line:
    % \lambda \phi A21 E1 E2 g1 g2
    fprintf(fileID, '%f %f %f %f %f %d %d\n',specline_data');
    fclose(fileID);
end
