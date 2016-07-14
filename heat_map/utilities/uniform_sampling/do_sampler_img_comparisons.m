function [ dist_rgb ] = do_sampler_img_comparisons( I0, I1, img_mask, opts, ...
    save_histo, output_folder, img_str)
%DO_SAMPLER_IMG_COMPARISONS Get histogram distances of images
%   [ DIST_RGB ] = DO_SAMPLER_IMG_COMPARISONS( I0, I1, IMG_MASK, OPTS )

dist_fnc = get_dist_fnc_from_file(opts);

histo_dim = 3;

edges = linspace(0, 255, opts.n_bins+1);

norm_factor = 1 / sum(img_mask(:) == 1);
assert(~isinf(norm_factor));

dist_rgb = cell(numel(opts.color_space), 1);
dist_rgb(:) = {zeros(1, histo_dim)};

for i=1:numel(opts.color_space)
    out_imgs = colorspace_transform_imgs({I0, I1}, 'RGB', opts.color_space{i});
    
    ori_histo = getImgRGBHistogram( out_imgs{1}, img_mask, opts.n_bins, edges);
    ori_histo = ori_histo * norm_factor;
    
    i_histo = getImgRGBHistogram( out_imgs{2}, img_mask, opts.n_bins, edges);
    i_histo = i_histo * norm_factor;
    
    for j=1:histo_dim
        dist_rgb{i}(j) = dist_fnc(i_histo(j, :), ori_histo(j, :));
    end
    
    if save_histo
        img_save_dir = fullfile(output_folder, opts.color_space{i});
        if (~exist(img_save_dir, 'dir'))
            mkdir(img_save_dir);
        end
        
        out_ylim = plot_histograms(opts.n_bins, opts.color_space{i}, opts.is_histo_independent, ...
            img_save_dir, out_imgs(1), {img_mask}, ['I0-Histo-bin' img_str]);
        
        plot_histograms(opts.n_bins, opts.color_space{i}, opts.is_histo_independent, ...
            img_save_dir, out_imgs(2), {img_mask}, ['I1-Histo-bin' img_str], out_ylim);
        
        out_imgs{1} = uint8(bsxfun(@times, double(out_imgs{1}), img_mask));
        out_imgs{2} = uint8(bsxfun(@times, double(out_imgs{2}), img_mask));
        
        imwrite(out_imgs{1}, fullfile(img_save_dir, ['I0-bin-' img_str '.tif']));
        imwrite(out_imgs{2}, fullfile(img_save_dir, ['I1-bin-' img_str '.tif']));
        
        for j=1:histo_dim
            imwrite(out_imgs{1}(:,:,j), fullfile(img_save_dir, ...
                ['I0-bin-' img_str '-' opts.color_space{i}(j) '.tif']));
            imwrite(out_imgs{2}(:,:,j), fullfile(img_save_dir, ...
                ['I1-bin-' img_str '-' opts.color_space{i}(j) '.tif']));
        end
    end
end

% Many figure are generated close them all
close all;

