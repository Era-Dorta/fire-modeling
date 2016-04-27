function fnc_names = clear_cache( fnc_names )
%CLEAR_CACHE Clear ga functions cache
%   FNC_NAMES = CLEAR_CACHE() Clears the cache of all the ga functions.
%   The actual names are returned in FNC_NAMES.
%
%   CLEAR_CACHE(FNC_NAMES) Clears the cache of all FNC_NAMES functions.
%
%   FNC_NAMES is a string cell array where each entry is the name of one
%   function

if nargin == 0
    fnc_names = {'histogramErrorApprox', 'histogramErrorOpti', ...
        'histogramDErrorOpti', 'render_attr_fitness', ...
        'heat_map_fitness_interp', 'heat_map_fitness'};
end

clear(fnc_names{:});
end

