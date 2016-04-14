clear all;
close all;

% Code from
% http://uk.mathworks.com/matlabcentral/fileexchange/34265-nist-atomic-spectra-database-import

min_lambda = 400;
max_lambda = 700;

% Copper->Green, Sulfur->Blue, Lithium->Red, Barium->Pale-Green,
% Sodium->Yellow, Cobalt->Silver-White, Scandium->Orange
% The ionization states should be choosen to be the "common" ones, as those
% are the ones used in the familiar flame tests
% https://en.wikipedia.org/wiki/List_of_oxidation_states_of_the_elements
% Note that the numbering scheme is +1 the above link, e.g. Cu i would be
% neutral copper. Search for any element in the following link to check
% http://physics.nist.gov/PhysRefData/ASD/ionEnergy.html
% Elements wihout number mean using all of the oxidation states
spec={'Cu', 'S', 'Li', 'Ba', 'Na', 'Co', 'Sc', 'C', 'H'};

file_dest = fileparts(mfilename('fullpath'));
file_dest = [file_dest '/fire_shader_data/'];

for i=1:size(spec, 2)
    nistln=nist_asd([spec{i} ' i'], min_lambda, max_lambda);
    
    % Get sum of relative intensities
    srint=0;
    num_valid = 0;
    for ii=1:length(nistln)
        if ~isempty(nistln(ii).rint) && ~isempty(nistln(ii).Aki) && ...
                ~isempty(nistln(ii).Ei) && ~isempty(nistln(ii).Ek) && ...
                ~isempty(nistln(ii).gigk)
            num_valid = num_valid + 1;
            srint = srint + nistln(ii).rint;
        end
    end
    
    % Save the normalized intensities, wavelengths, A21, E1, E2, g1, g2
    specline_data = zeros(num_valid, 7);
    valid_ind = 0;
    
    for ii=1:length(nistln)
        if ~isempty(nistln(ii).rint) && ~isempty(nistln(ii).Aki) && ...
                ~isempty(nistln(ii).Ei) && ~isempty(nistln(ii).Ek) && ...
                ~isempty(nistln(ii).gigk)
            valid_ind = valid_ind + 1;
            specline_data(valid_ind, 1) = nistln(ii).meanor;
            specline_data(valid_ind, 2) = nistln(ii).rint/srint;
            specline_data(valid_ind, 3) = nistln(ii).Aki;
            specline_data(valid_ind, 4) = nistln(ii).Ei;
            specline_data(valid_ind, 5) = nistln(ii).Ek;
            % g1 and g2 are in a string '%d - %d'
            C = textscan(nistln(ii).gigk,'%d%s%d');
            specline_data(valid_ind, 6) = C{1};
            specline_data(valid_ind, 7) = C{3};
        end
    end
    
    % Save the data into a file
    fileID = fopen([file_dest, spec{i}, '.specline'],'w');
    % First line number of data lines in the file
    fprintf(fileID, '%d\n',num_valid);
    % Each file line corresponds to a visible is a spectrum line:
    % \lambda \phi A21 E1 E2 g1 g2
    fprintf(fileID, '%e %e %e %e %e %d %d\n',specline_data');
    fclose(fileID);
end
