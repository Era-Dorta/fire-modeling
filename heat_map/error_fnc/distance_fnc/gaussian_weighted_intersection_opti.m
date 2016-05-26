function d=gaussian_weighted_intersection_opti(XI,XJ, n_bins)
% Implementation of the histogram gaussian weighted intersection distance
% to use with pdist
% Gaussian weighted histogram intersection for license plate classification
% Jia et. al. 2006
persistent wc c_norm prev_p prev_n_bins

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

% Parameters given in the paper
th = 15;
bw = 2.64 * th;
sigma = 0.8 * th;

% Not given in the paper, assumed to be a standard Gaussian function
A = 1;

% Precompute all the constant data
if isempty(wc) || prev_p ~= p || n_bins ~= prev_n_bins
    % Compute the color for each index in the combined histogram
    Xrgb = getColorFromHistoIndex( (1:p)', n_bins, 255/n_bins);
    
    prev_p = p;
    prev_n_bins = n_bins;
    
    wc = zeros(p,p);
    c_norm = zeros(p,p);
    
    for k=1:p
        for l=1:p
            c_norm(k,l) = norm(Xrgb(k,:) - Xrgb(l,:));
            if c_norm(k,l) <= bw
                wc(k, l) = (A / (sigma * sqrt(2 * pi))) * ...
                    exp(- (c_norm(k,l)^2) / (2 * sigma ^ 2));
            end
        end
    end
end

for k=1:p
    for l=1:p
        if c_norm(k,l) <= bw
            d = d + (min(XI(k), XJ(l))) * wc(k,l);
        end
    end
end
d = 1 - d/ sxi;
