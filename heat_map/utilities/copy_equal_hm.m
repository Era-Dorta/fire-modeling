function [out_hm] = copy_equal_hm(in_hm0, in_hm1)
% COPY_EQUAL_HM Copy heatmaps
%   [OUT_HM] = COPY_EQUAL_HM(IN_HM0, IN_HM1) Creates a heatmap OUT_HM with
%   where OUT_HM.XYZ are the common XYZ coordinates in IN_HM0 and IN_HM1,
%   and OUT_HM.V are the IN_HM1.V for those coordinates.
%
%   Example: density = read_raw_file('path-density.raw');
%            temperature = read_raw_file('path-temperature.raw');
%            [tCommon] = copy_equal_hm(density, temperature);
%
%   See also read_raw_file and save_raw_file

out_hm = in_hm0;
out_hm.xyz = [];
out_hm.v = [];
out_hm.count = 0;

disp_warning = true;

for i=1:in_hm0.count
    val_found = false;
    for j=1:in_hm1.count
        if all(in_hm0.xyz(i,:) == in_hm1.xyz(j,:))
            out_hm.count = out_hm.count + 1;
            out_hm.xyz(out_hm.count,:) = in_hm1.xyz(j,:);
            out_hm.v(out_hm.count,1) = in_hm1.v(j);
            val_found = true;
            break;
        end
    end
    if disp_warning && ~val_found
        warning([num2str(in_hm0.xyz(i,:)) ' and possibly others not ' ...
            'present in in_hm1.xyz']);
        disp_warning = false;
    end
end

end