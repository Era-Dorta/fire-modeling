function [stop] = gradplotbestgen(~, optimValues, state, input_image_path, ...
    output_img_folder, num_goal)
%GRADPLOTBESTGEN Plotting for Gradient solver
%   GRADPLOTBESTGEN Plot the rendered image of the best heat map on each
%   iteration
stop = false;

% In iteration zero is called twice, once with state = 'init' and once with
% state = 'iter', ignore the first one
if isequal('init', state)
    return;
end

% Use the GA function to avoid code replication
stateGA.Generation = optimValues.iteration;
flag = state;

gaplotbestgen([], stateGA, flag, input_image_path, output_img_folder, ...
    num_goal);

end

