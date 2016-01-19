function prob = weights2prob( weights, invert )
%WEIGHTS2PROB Weights to probabilities
%   PROB = WEIGHTS2PROB (WEIGHTS) converts a vector WEIGHTS of arbitrary
%   weights into a vector PROB of probabilities

if(nargin < 1)
    error('Not enough input arguments.');
end

if(nargin < 2)
    invert = false;
end

if(invert)
    % Inverted weights, lower ones should have higher probabilities, so
    % compute new weights that are inversely proprotional to the old ones
    weights = 1 ./ (weights + eps);
end

weights_sum = sum(weights);

if(weights_sum ~= 0)
    prob = weights ./ weights_sum;
else
    prob = ones(size(weights)) * (1 / length(weights));
end
end

