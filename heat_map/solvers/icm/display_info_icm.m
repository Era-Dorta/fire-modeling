function display_info_icm(options, optimValues)
if strcmp(options.Display, 'iter')
    if mod(optimValues.iteration, 25) == 0
        disp('Iter F-count           f(x)');
    end
    fprintf('% 4d %7d    %.5e\n', optimValues.iteration, ...
        optimValues.funccount, optimValues.fval);
end
end