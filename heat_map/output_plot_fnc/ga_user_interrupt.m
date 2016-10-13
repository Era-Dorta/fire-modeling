function [state, options, optchanged] = ga_user_interrupt( options, state, ~ )
% Time limit check for ga and sa optimization
optchanged = false;
clear user_stop_script; % Reload the function, file might have changed
user_stop_script; % Check if the user wants to stop
end

