function [ newv ] = fitToRange(v, oldmin, oldmax, newmin, newmax)
% Scales a value to a new range
newv = newmin + ((v - oldmin) ./ (oldmax - oldmin)) .* (newmax - newmin);
end
