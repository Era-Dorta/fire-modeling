function [ dist_fnc ] = get_dist_fnc_from_file( opts)
%GET_DIST_FNC_FROM_FILE Gets GA distance function from option file
%   [ DIST_FNC ] = GET_DIST_FNC_FROM_FILE( OPTS)
%
%   See also do_genetic_solve, do_genetic_solve_resample, args_test1,
%   args_test_template

if isequal(opts.dist_foo, @gaussian_weighted_intersection)
    
    check_valid_opts(opts);
    dist_fnc = @(x,y) gaussian_weighted_intersection(x, y, opts.n_bins);
    
elseif isequal(opts.dist_foo, @gaussian_weighted_intersection_opti)
    
    check_valid_opts(opts);
    dist_fnc = @(x,y) gaussian_weighted_intersection_opti(x, y, opts.n_bins);
    
else
    dist_fnc = opts.dist_foo;
end

    function check_valid_opts(opts)
        func_name = func2str(opts.dist_foo);
        if opts.is_histo_independent
            error(['@' func_name ' can only be used when is_histo_independent == false']);
        end
        if opts.n_bins > 10
            warning(['Using n_bins larger than 10 can cause severe '...
                'slowdowns with @' func_name]);
        end
    end

end