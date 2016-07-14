function [ dist_rgb ] = do_sampler_img_comparisons( I0, I1, img_mask, opts )
%DO_SAMPLER_IMG_COMPARISONS Get histogram distances of images
%   [ DIST_RGB ] = DO_SAMPLER_IMG_COMPARISONS( I0, I1, IMG_MASK, OPTS )

dist_fnc = get_dist_fnc_from_file(opts);

histo_dim = 3;

edges = linspace(0, 255, opts.n_bins+1);

norm_factor = 1 / sum(img_mask(:) == 1);
assert(~isinf(norm_factor));

dist_rgb = cell(numel(opts.c_space), 1);
dist_rgb(:) = {zeros(1, histo_dim)};

for i=1:numel(opts.c_space)
    out_imgs = colorspace_transform_imgs({I0, I1}, 'RGB', opts.c_space{i});
    
    ori_histo = getImgRGBHistogram( out_imgs{1}, img_mask, opts.n_bins, edges);
    ori_histo = ori_histo * norm_factor;
    
    i_histo = getImgRGBHistogram( out_imgs{2}, img_mask, opts.n_bins, edges);
    i_histo = i_histo * norm_factor;
    
    for j=1:histo_dim
        dist_rgb{i}(j) = dist_fnc(i_histo(j, :), ori_histo(j, :));
    end
end

