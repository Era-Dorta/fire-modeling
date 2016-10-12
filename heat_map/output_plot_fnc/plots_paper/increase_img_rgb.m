function increase_img_rgb()
folder = '~/workspaces/github/paper/images';
imgs_name = {'four-columns-point-light.png', 'teaser1.png', 'teaser2.png'};
for i=1:numel(imgs_name)
    img = imread(fullfile(folder, imgs_name{i}));
    [~, name, ext] = fileparts(imgs_name{i});
    movefile(fullfile(folder, imgs_name{i}),fullfile(folder, [name '-original' ext]));
    
    img = img + 20;
    
    % Saving in png changes the color, use tif
    imwrite(img, fullfile(folder, [name '.tif']));
    %     imwrite(img, map, fullfile(folder, imgs_name{i}));
    
end
end