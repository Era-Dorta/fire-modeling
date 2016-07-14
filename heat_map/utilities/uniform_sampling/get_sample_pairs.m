function [ out_samples, bin_norm ] = get_sample_pairs(opts, init_heat_map)
%GET_SAMPLES_PAIRS Get pairs of random samples

opts.hm_count = init_heat_map.count;

switch opts.sample_method
    case 'mirror'
        [out_samples, bin_norm] = get_samples_mirror( opts );
    case 'rand-and-corner'
    case 'rand'
end
end

