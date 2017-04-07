function plot_clustering_k_means_fig_for_paper()
rng(0);
t = read_raw_file( '~/maya/projects/fire/data/from_dmitry/volumes/frame00001vox_clean_128.raw2');

%t.v = t.v + 4; % Make plot colours more red/yellow

minxyz = min(t.xyz);
maxxyz = max(t.xyz);

c = 'rgb';
numc = numel(c);
for i=[3, 10, 20]
    
    clusters = compute_clusters(i, t.xyz);
    
    hstep = 1.0/(i-1);
    for j=1:i
        jj = clusters{j};
        t.v(jj) = (j-1)*hstep;
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
    
    %     for j=1:i
    %         jj = clusters{j};
    %
    %         if numel(jj) == 1
    %             minxyzj = t.xyz(jj,:);
    %             maxxyzj = t.xyz(jj,:);
    %         else
    %             minxyzj = min(t.xyz(jj,:));
    %             maxxyzj = max(t.xyz(jj,:));
    %         end
    %
    %         minxyzj = [minxyzj(1), minxyzj(3), minxyzj(2)];
    %         maxxyzj = [maxxyzj(1), maxxyzj(3), maxxyzj(2)];
    %
    %         plotBbox( minxyzj, maxxyzj, c(k), 0.2 );
    %     end
    % set(gca,'visible','off');
    
    
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
    
    ipath = fullfile('~/workspaces/matlab/testvis/clustering/', ['k_mean_cluster' num2str(i) ]);
    saveas(gcf, ipath, 'png');
    saveas(gcf, ipath, 'fig');
    %     saveas(gcf, ipath, 'pdf');
    
    i0 = imread([ipath '.png']);
    %i0 = imcrop(i0, [340, 0, 230, 690]);
    i0 = i0(:,170:720,:); % Crop
    imwrite(i0, [ipath '.png']);
    
    
end

    function clusters_idx = compute_clusters(num_clusters, xyz)
        clusters_idx = cell(1, num_clusters);
        idx = kmeans(xyz, num_clusters);
        for l=1:num_clusters
            clusters_idx{l} = find(idx == l);
        end
        return;
    end

end
