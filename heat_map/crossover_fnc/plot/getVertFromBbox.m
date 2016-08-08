function [ vert ] = getVertFromBbox( v_min, v_max )
%GETVERTFROMBBOX Computes 8 vertices for a bounding box
%   [ VERT ] = GETVERTFROMBBOX( V_MIN, V_MAX ) Given a bounding box extreme
%   vertices V_MIN and V_MAX 1x3 arrays, a 8x3 matrix VERT with all the
%   vertices of the bounding box cube is computed.

vert = zeros(8, 3);

vert(8, :) = v_min;
vert(4, :) = v_max;
vert(5,:) = [v_min(1), v_min(2), v_max(3)];
vert(2,:) = [v_min(1), v_max(2), v_min(3)];
vert(7,:) = [v_max(1), v_min(2), v_min(3)];
vert(3,:) = [v_min(1), v_max(2), v_max(3)];
vert(6,:) = [v_max(1), v_min(2), v_max(3)];
vert(1,:) = [v_max(1), v_max(2), v_min(3)];

end

