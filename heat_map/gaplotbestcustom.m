function [ state ] = gaplotbestcustom(options, state, flag, figurePath)
% Plots the error in GA optimization
figure(1);
hold on;
plot([1:state.Generation], state.Best, '-rx');
hold off;
disp(['figure path is ' figurePath]);
end
