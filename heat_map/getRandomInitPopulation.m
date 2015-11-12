function [ result ] = getRandomInitPopulation( LB, UB, n )
% Generates a new population of size n in the LB and UB range
result = rand(n, size(LB, 2));
for i=1:n
    result(i,:) = fitToRange(result(i,:), 0, 1, LB, UB);
end
end
