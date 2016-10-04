function display_info_icm(options, optimValues, num_dim)
if strcmp(options.Display, 'iter')
    if mod(optimValues.iteration, 25) == 0
        disp('Iter F-count           f(x)       Block');
    end
    fprintf('% 4d %7d    %.5e       %d/%d\n', optimValues.iteration, ...
        optimValues.funccount, optimValues.fval, optimValues.ite_inc, ...
         num_dim);
end
end