function volumetricData = convert4dma_to_raw2(file_path, vmin, vmax)
L = load(file_path);
colourvox = L.colourvox;

colourvox1 = colourvox(:,:,:,1) + colourvox(:,:,:,2) + colourvox(:,:,:,3);

whd = size(colourvox1);
numPoints = 1;

if nargin == 1
    vmin = [1,1,1];
    vmax = whd;
end

total_non_zero = 0;
for i=1:size(colourvox,1)
    for j=1:size(colourvox,2)
        for k=1:size(colourvox,3)
            if colourvox1(i,j,k) ~= 0 && all([i,j,k] >= vmin) && ...
                    all([i,j,k] <= vmax)
                total_non_zero = total_non_zero + 1;
            end
        end
    end
end

whd = size(colourvox1)';
xyz = zeros(total_non_zero, 3);
values = zeros(total_non_zero, 4);

for i=1:size(colourvox,1)
    for j=1:size(colourvox,2)
        for k=1:size(colourvox,3)
            if colourvox1(i,j,k) ~= 0 && all([i,j,k] >= vmin) && ...
                    all([i,j,k] <= vmax)
                xyz(numPoints,:) = [i,k,j];
                r = colourvox(i,j,k,1);
                g = colourvox(i,j,k,2);
                b = colourvox(i,j,k,3);
                values(numPoints,:) = [r,g,b,0];
                numPoints = numPoints + 1;
            end
        end
    end
end
numPoints = numPoints - 1;
volumetricData = struct('xyz', xyz, 'v', values, 'count', numPoints, ...
    'size', whd);
end