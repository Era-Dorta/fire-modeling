function [ dist_fnc ] = get_dist_fnc_from_file( opts)
%GET_DIST_FNC_FROM_FILE Gets GA distance function from option file
%   [ DIST_FNC ] = GET_DIST_FNC_FROM_FILE( OPTS)
%
%   See also do_genetic_solve, do_genetic_solve_resample, args_test1,
%   args_test_template

if isequal(opts.dist_foo, @gaussian_weighted_intersection)
    if opts.is_histo_independent
        error(['@gaussian_weighted_intersection can only be used when ' ...
            'is_histo_independent == false']);
    end
    dist_fnc = @(x,y) gaussian_weighted_intersection(x, y, opts.n_bins);
else
    dist_fnc = opts.dist_foo;
end

end

