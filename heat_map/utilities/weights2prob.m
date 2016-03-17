function prob = weights2prob( weights, invert, max_weight )
%WEIGHTS2PROB Weights to probabilities
%   PROB = WEIGHTS2PROB (WEIGHTS) converts a vector WEIGHTS of arbitrary
%   weights into a vector PROB of probabilities

if(nargin < 1)
    error('Not enough input arguments.');
end

if(nargin < 2)
    invert = false;
end

if(nargin < 3)
    max_weight = 1;
end

if(invert)
    % Invert weights
    weights = max_weight - weights;
    assert(all(weights >= 0));
end

weights_sum = sum(weights);

if(weights_sum ~= 0)
    prob = weights ./ weights_sum;
else
    prob = ones(size(weights)) * (1 / length(weights));
end
end

