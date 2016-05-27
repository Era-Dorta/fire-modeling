function [ dist_fnc ] = get_dist_fnc_from_file( opts, use_approx)
%GET_DIST_FNC_FROM_FILE Gets GA distance function from option file
%   [ DIST_FNC ] = GET_DIST_FNC_FROM_FILE( OPTS)
%
%   See also do_genetic_solve, do_genetic_solve_resample, args_test1,
%   args_test_template
if nargin == 1
    use_approx = false;
end

if use_approx
    n_bins = opts.approx_n_bins;
else
    n_bins = opts.n_bins;
end

if isequal(opts.dist_foo, @gaussian_weighted_intersection)
    
    check_valid_opts(opts, use_approx);
    dist_fnc = @(x,y) gaussian_weighted_intersection(x, y, n_bins);
    
elseif isequal(opts.dist_foo, @gaussian_weighted_intersection_opti)
    
    check_valid_opts(opts, use_approx);
    dist_fnc = @(x,y) gaussian_weighted_intersection_opti(x, y, n_bins);
    
else
    dist_fnc = opts.dist_foo;
end

    function check_valid_opts(opts, use_approx)
        func_name = func2str(opts.dist_foo);
        if opts.is_histo_independent
            error(['@' func_name ' can only be used when is_histo_independent == false']);
        end
        if use_approx && opts.approx_n_bins > 10
            warning(['Using approx_n_bins larger than 10 can cause severe '...
                'slowdowns with @' func_name]);
        end
        if ~use_approx && opts.n_bins > 10
            warning(['Using n_bins larger than 10 can cause severe '...
                'slowdowns with @' func_name]);
        end
    end

end