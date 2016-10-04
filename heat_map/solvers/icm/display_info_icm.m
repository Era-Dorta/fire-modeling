function display_info_icm(options, optimValues, num_dim)
if strcmp(options.Display, 'iter')
    if mod(optimValues.iteration, 25) == 0
        disp('Iter F-count           f(x)     exposure   f-exposure(x)   Block');
    end
    fprintf('% 4d %7d    %.5e     %.3f      %.3f        %d/%d\n', optimValues.iteration, ...
        optimValues.funccount, optimValues.fval, optimValues.exposure, ...
        optimValues.fexposure, optimValues.ite_inc, num_dim);
end
end