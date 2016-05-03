function d=histogram_l1_norm(XI,XJ)
% Implementation of the histogram l1 norm distance to use with pdist
m=size(XJ,1); % number of samples of p
p=size(XI,2); % dimension of samples

assert(p == size(XJ,2)); % equal dimensions
assert(size(XI,1) == 1); % pdist requires XI to be a single sample

d=zeros(m,1); % initialize output array

sxij = sum(XI) + sum(XJ);

if sxij == 0 % Both histograms empty means zero error
    d(:,1) = 0;
    return;
end

% Divide by the sum to have an error metric in the [0,1] range
for i=1:m
    d(i,1) = sum(abs(XI(i,:) - XJ(i,:))) / sxij;
end