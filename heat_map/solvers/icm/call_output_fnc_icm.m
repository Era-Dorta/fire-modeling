function [stop, optimValues] = call_output_fnc_icm(x, options, optimValues, state)
stop = false;
for k=1:numel(options.OutputFcn)
    if(options.OutputFcn{k}(x(1,:), optimValues, state))
        if ~stop
            optimValues.message = ['Interrupted by ' func2str(options.OutputFcn{k})];
        end
        stop = true;
    end
end
end