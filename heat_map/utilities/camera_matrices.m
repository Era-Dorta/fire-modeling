function [  ] = camera_matrices(port)
%CAMERA_MATRICES Summary of this function goes here
%   Detailed explanation goes here
if nargin < 1
    port = 2222;
end
[parentFolder,~,~] = fileparts(fileparts(mfilename('fullpath')));
sendMayaScript = [parentFolder '/maya_comm/sendMaya.rb'];

calib_folder = '~/maya/projects/fire/data/from_dmitry/volumes/RequestedFrames/calib/';
L = load([calib_folder 'Ce.mat']);
C = L.C;
L = load([calib_folder 'Pmatrices.mat']);
P = L.P;
L = load([calib_folder 'Re.mat']);
R = L.R;

for i = 1:6
    cam(i).P = P((i-1)*3+1:(i-1)*3+3,: );
    cam(i).R = R((i-1)*3+1:(i-1)*3+3,: );
    cam(i).K = cam(i).P(:,1: 3) * cam(i).R';
    cam(i).cen = C(:,i); % The camera centre in world coordinates
end

do_plot = true;
if do_plot
    figure;
end

for i = 1:6
    if do_plot
        hold on;
        % Plot world centre
        centre = [0,0,0];
        forward = [1; 0; 0];
        quiver3(centre(1), centre(2), centre(3), forward(1), forward(2), forward(3), 'r');
        forward = [0; 1; 0];
        quiver3(centre(1), centre(2), centre(3), forward(1), forward(2), forward(3), 'g');
        forward = [0; 0; 1];
        quiver3(centre(1), centre(2), centre(3), forward(1), forward(2), forward(3), 'b');
        
        centre = cam(i).cen;
        scatter3(centre(1), centre(2), centre(3));
        
        % Plot axis in each camera
        %forward = cam(i).R * [1; 0; 0];
        forward = [1, 0, 0] * cam(i).R;
        quiver3(centre(1), centre(2), centre(3), forward(1), forward(2), forward(3), 'r');
        
        %forward = cam(i).R * [0; 1; 0];
        forward = [0, 1, 0] * cam(i).R;
        quiver3(centre(1), centre(2), centre(3), forward(1), forward(2), forward(3), 'g');
        
        %forward = cam(i).R * [0; 0; -1];
        forward = [0, 0, -1] * cam(i).R;
        quiver3(centre(1), centre(2), centre(3), forward(1), forward(2), forward(3), 'b');
    end
    
    % Get the camera rotation
    r = cam(i).R;
    
    % Add the camera centre to the rotation matrix to create a general
    % transformation matrix
    r(4,:) = cam(i).cen; r(:, 4) = [0,0,0,1]';
    
    % Rotate -90 around z
    angle = -90;
    rz = [cosd(angle), -sind(angle), 0, 0;
        sind(angle), cosd(angle), 0, 0;
        0, 0, 1, 0;
        0, 0, 0, 1];
    
    % Change the sign of z
    m0 = eye(4); m0(3,3) = -1;
    
    % Apply the extra transformations to Maya world space
    rf = (r * rz * m0)';
    %rf = (r * m0)';
    
    % Create a string with the matrix in row order to send to Maya
    rf = rf(:);
    matrix = sprintf('%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', ...
        rf(1),rf(2),rf(3),rf(4),rf(5),rf(6),rf(7),rf(8),rf(9),rf(10), ...
        rf(11),rf(12),rf(13),rf(14),rf(15),rf(16));
    
    % Maya doesn't allow for setting the projection matrix directly, we can
    % change other parameters, focal length, camera aperture, ...
    % Focal length is first parameter in K divided by the number of pixels
    % in the image and multiplied by the sensor size
    focalLength = (- cam(i).K(1,1) * 6) / (1400);
    
    sendToMaya(sendMayaScript, port, ['select -r camera' num2str(i)], false);
    sendToMaya(sendMayaScript, port, ['xform -worldSpace -matrix ' matrix], false);
    sendToMaya(sendMayaScript, port, ['setAttr \"camera' num2str(i) 'Shape.focalLength\" '...
        num2str(focalLength)], false);
    
    %sendToMaya(sendMayaScript, 2300, ['xform -worldSpace -translation ' num2str(centre(1)) ...
    %    ' ' num2str(centre(2)) ' ' num2str(centre(3))], false);
end
if do_plot
    xlabel('x'); ylabel('y'); zlabel('z');
    view(3);
    axis equal;
    hold off;
end

% Set the volume in position and scale
voxelfromto = [-1 1 -0.8 1.2 -1.5 0.5]; % candle, from andrew_code.m file
voxelfrom = voxelfromto([1 3 5]);
voxelto = voxelfromto([2 4 6]);
vox_centre = (voxelto + voxelfrom)./2;
volume_size = voxelto - voxelfrom;
vox_scale = 2 ./ volume_size;
% Negate z in the centre coordinates
vox_centre(3) = -vox_centre(3);

sendToMaya(sendMayaScript, port, 'select -r fire_volume_box', false);
sendToMaya(sendMayaScript, port, ['xform -worldSpace -translation ' num2str(vox_centre(1)) ...
    ' ' num2str(vox_centre(2)) ' ' num2str(vox_centre(3))], false);
sendToMaya(sendMayaScript, port, ['xform -worldSpace -scale '  num2str(vox_scale(1)) ...
    ' ' num2str(vox_scale(2)) ' ' num2str(vox_scale(3))], false);
end

