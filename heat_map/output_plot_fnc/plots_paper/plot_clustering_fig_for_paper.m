function plot_clustering_fig_for_paper()
t = read_raw_file( '~/maya/projects/fire/data/from_dmitry/vox_bin_00841_clean_128.raw2');

lin_idx = sub2ind(t.size, t.xyz(:,1), t.xyz(:,3), t.xyz(:,2));
[~, ordered_idx] = sort(lin_idx);
t.xyz = t.xyz(ordered_idx,:);

minxyz = min(t.xyz);
maxxyz = max(t.xyz);

c = 'rgb';
numc = numel(c);
for i=[3, 10, 20]
    hstep = round(t.count/i);
    k = 1;
    
    plotHeatMap(t, 1/0.0127);
    hold on;
    
    % Set background color to white
    set(gca,'Color',[1 1 1]);
    
    for j=1:hstep:t.count
        jj = j:min(j+hstep, t.count);
        
        if numel(jj) == 1
            minxyzj = t.xyz(jj,:);
            maxxyzj = t.xyz(jj,:);
        else
            minxyzj = min(t.xyz(jj,:));
            maxxyzj = max(t.xyz(jj,:));
        end
        
        minxyzj = [minxyzj(1), minxyzj(3), minxyzj(2)];
        maxxyzj = [maxxyzj(1), maxxyzj(3), maxxyzj(2)];
        
        plotBbox( minxyzj, maxxyzj, c(k), 0.2 );
        
        if k + 1 <= numc
            k = k + 1;
        else
            k = 1;
        end
    end
    set(gca,'visible','off');
    view(-37,20)
    
    set(gca,'xlim', [minxyz(1),maxxyz(1)]);
    set(gca,'ylim', [minxyz(2),maxxyz(2)]);
    set(gca,'zlim', [minxyz(3),maxxyz(3)]);
    
    axis equal;
    set(gca,'position',[0 0 1 1],'units','normalized');
    
    hold off;
    
    ipath = fullfile('~/workspaces/matlab/testvis/clustering/', ['cluster' num2str(i) ]);
    saveas(gcf, ipath, 'png');
    saveas(gcf, ipath, 'fig');
    %     saveas(gcf, ipath, 'pdf');
    
    i0 = imread([ipath '.png']);
    i0 = imcrop(i0, [340, 0, 230, 690]);
    imwrite(i0, [ipath '.png']);
    
    
end

end
