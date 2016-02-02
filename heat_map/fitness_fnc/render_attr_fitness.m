function [ error ] = render_attr_fitness( render_attr, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img)
%RENDER_ATTR_FITNESS Render attr fitness function

output_img_folder = [scene_img_folder output_img_folder_name];

num_error_foos = size(error_foo, 2);
error = zeros(num_error_foos, size(render_attr, 1));

for pop=1:size(render_attr, 1)
    
    %% Make temp dir for the render image
    [~, tmpdir] = system(['mktemp -d ' output_img_folder 'dirXXXXXX']);
    [~,tmpdirName,~] = fileparts(tmpdir);
    % Remove end on line characters
    tmpdirName = regexprep(tmpdirName,'\r\n|\n|\r','');
    
    %% Set the render attributes
    cmd = ['setAllFireAttributes(\"fire_volume_shader\", ' ...
        '0.010, 0, ' num2str(render_attr(1)) ', ' num2str(render_attr(2)) ', ' ...
        num2str(render_attr(3)) ', ' num2str(render_attr(4)) ')'];
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd scene_name '/' output_img_folder_name tmpdirName '/fireimage' '\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Render the image
    % This command only works on Maya running in batch mode, if running with
    % the GUI, use Mayatomr -preview. and then save the image with
    % $filename = "Path to save";
    % renderWindowSaveImageCallback "renderView" $filename "image";
    startTime = tic;
    cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
    sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
    %fprintf('Image rendered with');
    
    %% Compute the error with respect to the goal image
    c_img = imread([output_img_folder tmpdirName '/fireimage.tif']);
    c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
    
    % Evaluate all the error functions, usually only one will be given
    for i=1:num_error_foos
        if(sum(c_img(:)) == 0)
            % If the rendered image is completely black set the error manually
            error(i, pop) = realmax;
        else
            error(i, pop) = sum(feval(error_foo{i}, goal_img, c_img));
        end
    end
    
    % Print the rest of the information on the same line
    %fprintf(' error %.2f, in %.2f seconds.\n', error(1), toc(startTime));
    
    % Delete the temporary files
    system(['rm -rf ' tmpdir '&']);
end
end
