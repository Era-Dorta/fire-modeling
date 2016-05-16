function [out_imgs] = colorspace_transform_imgs(in_imgs, in_space, out_space)

out_imgs = in_imgs;

if ~strcmp(in_space, out_space)
    for i=1:numel(in_imgs)
        out_imgs{i} = colorspace([out_space,'<-', in_space], double(in_imgs{i}));
        out_imgs{i} = uint8(out_imgs{i});
    end
end

end