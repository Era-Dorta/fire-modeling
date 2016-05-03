function d=histogram_l1_norm(XI,XJ)
% Implementation of the histogram l1 norm distance to use with pdist
m=size(XJ,1); % number of samples of p
p=size(XI,2); % dimension of samples

assert(p == size(XJ,2)); % equal dimensions
assert(size(XI,1) == 1); % pdist requires XI to be a single sample

d=zeros(m,1); % initialize output array

% Max error is 2, so divide by 2 to have a 0..1 range
for i=1:m
    d(i,1) = sum(abs(XI(i,:) - XJ(i,:))) / 2;
end