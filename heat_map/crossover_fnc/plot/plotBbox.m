function plotBbox( v_min, v_max, color )
%PLOTBBOX Plots a bounding box
%   PLOTBBOX( V_MIN, V_MAX, COLOR ) Plot a cube (bounding box) with
%   vertices in V_MIN and V_MAX and COLOR

fac = [1 2 3 4;
    4 3 5 6;
    6 7 8 5;
    1 2 8 7;
    6 7 1 4;
    2 3 5 8];

vert = getVertFromBbox(v_min, v_max);

patch('Faces',fac,'Vertices',vert,'FaceColor', color); 

end

