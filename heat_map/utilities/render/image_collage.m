function image_collage( num_img, output_folder)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
all_population_img = [];
row_img = [];
num_column = 0;

for i=1:num_img
    img_path = fullfile(output_folder, ['fireimage' num2str(i) '.tif']);
    img = imread(img_path);
    img = img(:,:,1:3);
    
    if ~exist('max_column','var')
        % Assuming all result images have the same size and that we want to
        % build of mosaic of width 1920 pixels
        max_column = max(floor(1920 / size(img, 2)), 1);
    end
    
    row_img = [row_img, img];
    num_column = num_column + 1;
    
    if(num_column >= max_column)
        all_population_img = [all_population_img; row_img];
        row_img = [];
        num_column = 0;
    end
    
end

% Check if last row was not completed
if(~isempty(row_img))
    % Create a padding with black squares
    row_size = size(row_img);
    padding = zeros(row_size(1), size(all_population_img, 2) - row_size(2), ...
        row_size(3));
    padding(1:10:end, :,:) = 255;
    padding(:,1:10:end,:) = 255;
    
    all_population_img = [all_population_img; row_img, padding];
end
imwrite(all_population_img, fullfile(output_folder, 'AllPopulation.tif'));

end

