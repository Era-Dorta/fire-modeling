function plot_clustering_k_means_fig_for_paper()
rng(0);
t = read_raw_file( '~/maya/projects/fire/data/from_dmitry/volumes/frame00001vox_clean_128.raw2');
do_kmeans = false;

lin_idx = sub2ind(t.size, t.xyz(:,1), t.xyz(:,3), t.xyz(:,2));
[~, ordered_idx] = sort(lin_idx);
t.xyz = t.xyz(ordered_idx,:);
%t.v = t.v + 4; % Make plot colours more red/yellow

minxyz = min(t.xyz);
maxxyz = max(t.xyz);

for i=[3, 10, 20]
    
    if do_kmeans
        clusters = compute_clusters_kmeans(i, t.xyz);
        save_name = 'k_mean_cluster';
        suffle_colors = false;
    else
        clusters = compute_clusters_seq(i, t.v);
        save_name = 'sequential_cluster';
        suffle_colors = true;
    end
    
    
    cluster_colors = linspace(0, 1, i); zeros(i,1);
    if suffle_colors
        cluster_colors = cluster_colors(randperm(length(cluster_colors)));
    end
    
    for j=1:i
        t.v(clusters{j}) = cluster_colors(j);
    end
    
    % IMPORTANT: COMMENT OUT THE FOLLOWING LINE IN PLOT HEATMAP TO GET
    % WALLS FOR THE SHADOWS
    % Set background color to gray
    %set(gca,'Color',[0.8 0.8 0.8]);
    plotHeatMap(t);
    
    hold on;
    colormap('jet');
    % Add shadows to provide better understanding of the 3D scene
    plot3(zeros(size(t.xyz(:,1))), t.xyz(:,3),t.xyz(:,2),'o','color',[0.8 0.8 0.8]);
    plot3(t.xyz(:,1),zeros(size(t.xyz(:,3)))+128,t.xyz(:,2),'o','color',[0.8 0.8 0.8]);
    plot3(t.xyz(:,1), t.xyz(:,3),zeros(size(t.xyz(:,2))),'o','color',[0.8 0.8 0.8]);
    hold off;
    
    % Set background color to white
    set(gca,'Color',[1 1 1]);
    
    view(70,25)
    
    minxyzj = t.xyz(:,:);
    maxxyzj = t.xyz(:,:);
    
    set(gca,'xlim', [minxyz(1),maxxyz(1)]);
    set(gca,'ylim', [minxyz(2),maxxyz(2)]);
    set(gca,'zlim', [minxyz(3),maxxyz(3)]);
    
    axis equal;
    set(gca,'position',[0 0 1 1],'units','normalized');
    
    set(gca,'XTickLabel',[])
    set(gca,'YTickLabel',[])
    set(gca,'ZTickLabel',[])
    xlabel('');
    ylabel('');
    zlabel('');
    
    hold off;
    
    ipath = fullfile('~/workspaces/matlab/testvis/clustering/', [save_name num2str(i) ]);
    saveas(gcf, ipath, 'png');
    saveas(gcf, ipath, 'fig');
    %     saveas(gcf, ipath, 'pdf');
    
    i0 = imread([ipath '.png']);
    %i0 = imcrop(i0, [340, 0, 230, 690]);
    i0 = i0(:,170:720,:); % Crop
    imwrite(i0, [ipath '.png']);
    
    
end

    function clusters_idx = compute_clusters_kmeans(num_clusters, xyz)
        clusters_idx = cell(1, num_clusters);
        idx = kmeans(xyz, num_clusters);
        for l=1:num_clusters
            clusters_idx{l} = find(idx == l);
        end
    end

    function clusters_idx = compute_clusters_seq(num_clusters, v)
        num_dim = numel(v);
        ite_inc = num_dim / num_clusters;
        idx = round(1:ite_inc:num_dim);
        clusters_idx = cell(1, num_clusters);
        for k = 1:numel(idx)-1
            clusters_idx{k} = (idx(k):idx(k+1)-1);
        end
        clusters_idx{end} = (idx(end):num_dim);
    end

end
