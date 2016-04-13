clear all;
close all;

%% Spectral lines
folder = 'spec_12/';

is_chem = false;

if is_chem
    fileID = fopen('Na.specline','r');
    formatSpec = '%f %f %f %f %f %f %f';
    specline = fscanf(fileID,formatSpec);
    specline = specline(2:end);
    lambdas = specline(1:7:end,:);
    values = specline(2:7:end,:);
    a21 = specline(3:7:end,:);
    e1 = specline(4:7:end,:);
    e2 = specline(5:7:end,:);
    g1 = specline(6:7:end,:);
    g2 = specline(7:7:end,:);
    
    lambdas = [400; lambdas; 700];
    values = [0; values; 0];
    a21 = [0; a21; 0];
else
    fileID = fopen('Propane.optconst','r');
    formatSpec = '%f %f %f';
    specline = fscanf(fileID,formatSpec);
    R = specline(2);
    alpha = specline(3);
    specline = specline(4:end); % Remove num lines, R and alpha(lambda)
    lambdas = specline(1:3:end,:);
    n = specline(2:3:end,:);
    k = specline(3:3:end,:);
    fix_factor = 1e-6;
    values = fix_factor .* (4/3) .* pi .* R^3 .* ((36 * pi) ./ (lambdas .* 1e-3).^alpha) .* ...
        ((n .* k) ./ ((n.^2 - k.^2 + 2).^2 + 4 .* n.^2 .* k.^2));
end

figure(1);
set(gcf,'Name', 'Spectral line', 'Position', [105 515 570 450]);
% plot(lambdas, values, 'b*-');
bar(lambdas, values);
ylim([0, max(values)]);

if is_chem
    figure(2);
    set(gcf,'Name', 'A21', 'Position', [1329 513  570 450]);
    plot(lambdas, a21, 'b*-');
end

lambdas1 = linspace(405, 695, 30);

fileID = fopen([folder 'abs.txt'],'r');
formatSpec = '%f';
abs = fscanf(fileID,formatSpec);

figure(3);
set(gcf,'Name', 'Absorption', 'Position', [736 516 570 450]);
plot(lambdas1, abs, 'b*-');
ylim([0, max(abs)]);

fileID = fopen([folder 'bb.txt'],'r');
bb = fscanf(fileID,formatSpec);

figure(4);
set(gcf,'Name', 'Black body', 'Position', [128 14 570 450]);
plot(lambdas1, bb, 'b*-');

fileID = fopen([folder 'bb-abs.txt'],'r');
bbabs = fscanf(fileID,formatSpec);

figure(5);
set(gcf,'Name', 'Black body * Absorption', 'Position', [736 1 570 450]);
plot(lambdas1, bbabs, 'b*-');

figure(6);
set(gcf,'Name', 'All', 'Position', [1302 26 570 450]);
hold on
% plot(lambdas, values, 'r*-');
plot(lambdas1, abs, 'g*-');
plot(lambdas1, bb, 'b*-');
plot(lambdas1, bbabs, 'y*-');
legend('Absorption', 'Black Body', 'BB * Abs')
hold off

%% Whole black body curve
% temp = fliplr([1000:100:2000]);
% wl = [400:10:700];
%
% inv_8_pi = 1.0 / (8 * pi);
% k = 1.3806488e-5;
% h = 6.62606957e-16;
% c = 299792458e9;
% C1 = 2.0 * h * c * c;
% C2 = (h .* c) ./ (k .* temp);
%
% for i=1:size(temp,2)
%     for j=1:size(wl,2)
%         res(i,j) = C1 / (wl(j)^5 * (exp(C2(i) / wl(j)) - 1.0));
%     end
% end
%
% figure(4);
% hold on;
% for i=1:size(temp,2)
% % for i=5
%     plot(wl, res(i,:));
% end
% hold off;
% legend(arrayfun(@num2str, temp, 'unif', 0), 'Location', 'NorthWest');