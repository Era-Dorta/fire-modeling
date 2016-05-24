function d=gaussian_weighted_intersection(XI,XJ)
% Implementation of the histogram gaussian weighted intersection distance 
% to use with pdist
% Gaussian weighted histogram intersection for license plate classification
% Jia et. al. 2006
m=size(XJ,1); % number of samples of p
p=size(XI,2); % dimension of samples

assert(p == size(XJ,2)); % equal dimensions
assert(size(XI,1) == 1); % pdist requires XI to be a single sample

d=zeros(m,1); % initialize output array

sxi=sum(XI);

if sxi == 0 % No pixels in first histogram, try with the second
    sxi = sum(XJ);
    if sxi == 0 % Both histograms empty means zero error
        d(:,1) = 0;
        return;
    end
end

for i=1:m
    for j=1:m
        d(i,1) = 1 -
        d(i,1) = 1 - (sum(min(XI, XJ(i,:))) / sxi);
    end
end