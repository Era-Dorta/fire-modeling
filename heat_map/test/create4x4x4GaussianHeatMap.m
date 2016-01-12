% Create 4x4x4 gaussian heatmap

save_path = '~/maya/projects/fire/data/heat_maps/gaussian4x4x4.raw';

% set the size at 5x5x5 to avoid indexing problems
heatm = struct('xyz', zeros(64, 3), 'v', zeros(64, 1), 'count', 64, ...
    'size', [5,5,5]');

vol = zeros(4,4,4);

% Gaussian centered in the middle of our 5x5x5 volume data with sigma = 0
mu = [2.5, 2.5, 2.5];

indx = 1;
for i=1:4
    for j=1:4
        for k=1:4
            heatm.xyz(indx,:) = [i, j, k];
            vol(i,j,k) = (1/sqrt(2*pi).*exp(-((i-mu(1)).^2 + (j-mu(2)).^2 + (k-mu(3)).^2)));
            heatm.v(indx) = vol(i,j,k);
            indx = indx + 1;
        end
    end
end

% Normalize so that the max values are around 2000K as this is a toy
% heatmap volume
heatm.v = heatm.v / max(heatm.v(:));
heatm.v = heatm.v * 2000;

save_raw_file(save_path, heatm);

plotHeatMap(heatm);