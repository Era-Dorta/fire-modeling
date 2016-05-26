function [ error_fnc ] = get_error_fnc_from_file( opts, goal_img, ...
    goal_mask, syn_img_mask)
%GET_ERROR_FNC_FROM_FILE Gets GA error function from option file
%   [ ERROR_FNC ] = GET_ERROR_FNC_FROM_FILE( OPTS, GOAL_IMG, ...
%    GOAL_MASK, SYN_IMG_MASK)
%
%   See also do_genetic_solve, do_genetic_solve_resample, args_test1,
%   args_test_template

dist_fnc = get_dist_fnc_from_file(opts);

error_fnc = cell(size(opts.error_foo));
for i=1:numel(opts.error_foo)
    
    if isequal(opts.error_foo{i}, @histogramErrorOpti)
        
        error_fnc{i} = @(syn_img) histogramErrorOpti(goal_img, syn_img, goal_mask,...
            syn_img_mask, dist_fnc, opts.n_bins, opts.is_histo_independent);
        
    elseif isequal(opts.error_foo{i}, @histogramDErrorOpti)
        
        error_fnc{i} = @(syn_img) histogramDErrorOpti(goal_img, syn_img, goal_mask,...
            syn_img_mask, dist_fnc, opts.n_bins, opts.n_bins_dist,...
            opts.is_histo_independent);
        
    elseif isequal(opts.error_foo{i}, @MSE)
        
        error_fnc{i} = @(syn_img) MSE(goal_img, syn_img, goal_mask, ...
            syn_img_mask);
        
    else
        error(['Unkown GA error function @' func2str(error_fnc{i}) ' in ' ...
            L.args_path]);
    end
    
end

end

