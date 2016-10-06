function volumetricData = convert4dma_to_raw2(file_path)
L = load(file_path);
colourvox = L.colourvox;

colourvox1 = colourvox(:,:,:,1) + colourvox(:,:,:,2) + colourvox(:,:,:,3);

whd = size(colourvox1)';
xyz = [];
values = [];
numPoints = 1;

for i=1:size(colourvox,1)
    for j=1:size(colourvox,2)
        for k=1:size(colourvox,3)
            if colourvox1(i,j,k) ~= 0
                xyz(numPoints,:) = [i,k,j];
                r = colourvox(i,j,k,1);
                g = colourvox(i,j,k,2);
                b = colourvox(i,j,k,3);
                values(numPoints,:) = [r,g,b];
                numPoints = numPoints + 1;
            end
        end
    end
end
numPoints = numPoints - 1;
volumetricData = struct('xyz', xyz, 'v', values, 'count', numPoints, ...
    'size', whd');
end