function check_size_limitations(opts,  heat_map)
%CHECK_SIZE_LIMITATIONS Size check for mutation functions
%   CHECK_SIZE_LIMITATIONS(OPTS,  HEAT_MAP)
%
%   See also get_ga_options_from_file

if(heat_map.count >= 10000)
    mem_foo = { @mutationadaptfeasible, @gamutationadaptprior, ...
        @gamutationadaptscale };
    if isequalFncCell(opts.options.MutationFcn, mem_foo)
        warning(['For heat maps with active voxel number larger than 10000' ...
            ' @' func2str(opts.options.MutationFcn) ' is not recommended ' ...
            'due to large memory usage']);
    end
end
end

