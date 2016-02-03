clear all;
close all;

% Plot a comparison between different variance tests results
%% Initialization
variance_test_num = [0, 1];
hm_number = 0:11;

result_path = '~/maya/projects/fire/images/test79_like_78_rot/VarianceTest';

num_var_test = length(variance_test_num);
num_hm = length(hm_number);

%% Read the data
X = zeros(num_hm, num_var_test);
Y = zeros(num_hm, num_var_test);

for i=1:length(variance_test_num)
    istr = num2str(variance_test_num(i));
    for j=1:length(hm_number)
        T = load([result_path istr '/hm_search_' num2str(hm_number(j)) '/summary_file.mat']);
        X(j,i) = T.summary_data.creation_fnc_sigma;
        Y(j,i) = T.summary_data.ImageError;
    end
end

%% Convert the data for plotting
% Sigmas are repreated so ignore one of them
X = X(:,1);

% Convert the sigmas to strings
Xstr = cell(length(X));
for i=1:length(X)
    Xstr{i} = num2str(X(i));
end

%% Generate the graph
figure;
bar(Y);
set(gca,'xticklabel',Xstr)
title('Crossover function comparison');
ylabel('Error function');
xlabel('Initial Guess Perturbation Variance');
legend('CrossoverCombinePrior','CrossoverScattered', 'Location', 'northwest')