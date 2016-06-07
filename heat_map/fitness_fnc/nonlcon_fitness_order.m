function [C, Ceq] = nonlcon_fitness_order(X, GenomeLength)
%NONLCON_FITNESS_ORDER Non linear constrains for GA
%   [C, CEQ] = NONLCON_FITNESS_ORDER(X, GENOMELENGTH)

% Inequality constrains,
% We want all values being different, but Ceq must be empty, so we set
% two "equivalent" inequality constrains
% http://uk.mathworks.com/help/gads/mixed-integer-optimization.html
tol = 0.01;
C = zeros(size(X,1), 2);
for i=1:size(X,1)
    C(i,1) = numel(unique(X(i,:))) - GenomeLength - tol;
    C(i,2) = -(numel(unique(X(i,:))) - GenomeLength) - tol;
end

% Equality constrains, empty matrices
Ceq = zeros(size(X,1),0);

end

