function maya_set_custom_parameters( maya_send, opts )
%MAYA_SET_CUSTOM_PARAMETERS Set parameters of Maya
%   MAYA_SET_CUSTOM_PARAMETERS(MAYA_SEND, OPTS) Sets Maya parameters using
%   the information in OPTS.
%
%   See also heatMapReconstruction

if isfield(opts, 'maya_new_density_scale')
    
    if isfield(opts, 'maya_density_scale')
        base_d_scale = opts.maya_density_scale;
    else
        base_d_scale = 1;
    end
    
    if opts.is_custom_shader
        shape_name = 'fire_volume_shader.density_scale';
    else
        shape_name = '"Flame:flameShape.densityScale"';
    end
    
    for i=1:numel(maya_send)
        cmd = ['setAttr ' shape_name ' ' ...
            num2str( base_d_scale * opts.maya_new_density_scale)];
        maya_send{i}(cmd, 0);
    end
    
end

end
