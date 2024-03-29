function display_info_icm(options, optimValues, num_dim)
if isempty(optimValues.exposure)
    exposure_str = '';
    exposure_strf = '%.3e';
else
    exposure_str = '    exposure';
    exposure_strf = '   %.3e';
end

if isempty(optimValues.fexposure)
    exposure_str = [exposure_str ''];
    exposure_strf = [exposure_strf '%.3e'];
else
    exposure_str = [exposure_str '   f-exposure(x)'];
    exposure_strf = [exposure_strf '       %.3e'];
end

if isempty(optimValues.density)
    density_str = '';
    density_strf = '%.3e';
else
    density_str = '     density';
    density_strf = '   %.3e';
end

if isempty(optimValues.fdensity)
    density_str = [density_str ''];
    density_strf = [density_strf '%.3e'];
else
    density_str = [density_str '   f-density(x)'];
    density_strf = [density_strf '      %.3e'];
end

if strcmp(options.Display, 'iter')
    if mod(optimValues.iteration, 25) == 0
        disp(['Iter F-count           f(x)' exposure_str density_str '     Block']);
    end
    fprintf(['% 4d %7d    %.5e' exposure_strf density_strf '     %d/%d\n'],  ...
        optimValues.iteration, optimValues.funccount, optimValues.fval,  ...
        optimValues.exposure, optimValues.fexposure, optimValues.density, ...
        optimValues.fdensity, optimValues.num_clusters, num_dim);
end
end