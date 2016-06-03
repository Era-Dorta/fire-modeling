function bottom_bright_prior_plot()
%BOTTOM_BRIGHT_PRIOR_PLOT Plot bottom bright function
figure;
hold on;

% Points on the x axis, change to adjust the x values position
x = [-1, -0.3, 1.3, 2];

% Increased fontsize for better viewing
fontsize = 16;

% Plot values
plot(x(1:2),[1,1], 'b-');
scatter(x(2), 1, 'bo');
scatter(x(2), 0, 'bo', 'filled');
plot(x(2:4), [0, 0, 1], 'b-');

% Set axis ticks and names
set(gca,'YTick', [0, 1],'fontsize',fontsize);
set(gca,'XTick', x,'fontsize',fontsize);

% Names in the x axis, using latex fonts
format_ticks(gca,{'$-\infty$', '0', '$th_{bb}$', '$t_{md}$'});

% Set axis labels
ylabel('$f_{bb}(v_{i,j,k})$','Interpreter','latex','fontsize',fontsize);
xlabel('$\left( v_{i,j-1,k} - v_{i,j,k} \right)$','Interpreter','latex','fontsize',fontsize);

% Strecht the x axis and squash the y axis
pbaspect([1.1 0.5 1]);

hold off;

% Optionally run this command to reduce margin size in the saved figure
% pdfcrop -margins 10 infile.pdf outfile.pdf
end

