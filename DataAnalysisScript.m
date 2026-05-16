

clear;
clc;
close all;


files = { ...
    '480p_5Min_Dataset.txt', ...
    '240p_2Min_Dataset.txt', ...
    '1080p_2Min_Dataset.txt'};

dataset_names = { ...
    '480p 5Min MP4', ...
    '240p 2Min MP4', ...
    '1080p 2Min MP4'};

T = 1.0;              
numBins = 40;         
outlierFactor = 5;   

nData = length(files);

mu_all = zeros(nData,1);
sigma2_all = zeros(nData,1);
sigma_all = zeros(nData,1);
skew_all = zeros(nData,1);
kurt_all = zeros(nData,1);

P_emp_all = zeros(nData,1);
P_gauss_all = zeros(nData,1);

P_abs_emp_all = zeros(nData,1);
P_abs_gauss_all = zeros(nData,1);

N_all = zeros(nData,1);

all_dx_detrended = cell(nData,1);
all_time = cell(nData,1);

Pz_all = zeros(nData,1);
Pz_gauss_all = zeros(nData,1);


for i = 1:nData
    
   
    data = readmatrix(files{i});
    
    time = data(:,2);
    dx = data(:,5);
    dy = data(:,6); %#ok<NASGU>
    
    
    med = median(dx);
    mad_raw = median(abs(dx - med));
    mad_sigma = 1.4826 * mad_raw;
    
    threshold = outlierFactor * mad_sigma;
    mask = abs(dx - med) < threshold;
    
    dx = dx(mask);
    time = time(mask);
    
    
    N_all(i) = length(dx);
    
   
if contains(dataset_names{i}, '480p 5Min')
    end_mask = time < 280;
    dx = dx(end_mask);
    time = time(end_mask);
end

% Remove slow drift using moving average
window = 500;
trend = movmean(dx, window);
dx_detrended = dx - trend;
    % Basic Statistics on Detrended Data 
    mu = mean(dx_detrended);
    sigma2 = var(dx_detrended);   
    sigma = sqrt(sigma2);
    % Lucky Imaging Frame Yield Estimate 
Tgood = 0.1;         % "good frame" threshold in pixels
G = 300;             % desired number of good frames
targetProb = 0.95;   % desired confidence level

% Empirical probability that a frame is "good"
p_good = mean(abs(dx_detrended) < Tgood);

% Expected total frames needed
N_expected = ceil(G / p_good);

% Binomial estimate: frames needed so that
% P(at least G good frames) >= targetProb
N_required = G;
while 1 - binocdf(G-1, N_required, p_good) < targetProb
    N_required = N_required + 1;
end

fprintf('Good-frame threshold |dx| < %.2f pixels\n', Tgood);
fprintf('P(good frame) empirical: %.4f\n', p_good);
fprintf('Frames needed for %.0f good frames on average: %d\n', G, N_expected);
fprintf('Frames needed for at least %.0f good frames with %.0f%% probability: %d\n', ...
    G, 100*targetProb, N_required);
    % Normalized (Z-score) Analysis
    z = dx_detrended / sigma;

    Pz = mean(abs(z) > 1);                 % empirical
    Pz_gauss = 2 * (1 - normcdf(1, 0, 1)); % Gaussian reference 
    % Tail Probabilities 
    P_empirical = mean(dx_detrended > T);
    P_theoretical = 1 - normcdf(T, 0, sigma);
    
    P_abs = mean(abs(dx_detrended) > T);
    P_abs_gauss = 2 * (1 - normcdf(T, 0, sigma));
    
    % Higher-Order Statistics
    sk = skewness(dx_detrended);
    k = kurtosis(dx_detrended);
    
    % Save Results
    mu_all(i) = mu;
    sigma2_all(i) = sigma2;
    sigma_all(i) = sigma;
    skew_all(i) = sk;
    kurt_all(i) = k;
    
    P_emp_all(i) = P_empirical;
    P_gauss_all(i) = P_theoretical;
    
    P_abs_emp_all(i) = P_abs;
    P_abs_gauss_all(i) = P_abs_gauss;
    
    all_dx_detrended{i} = dx_detrended;
    all_time{i} = time;

    Pz_all(i) = Pz;
    Pz_gauss_all(i) = Pz_gauss;
    %% Figure 1: Raw vs Detrended Signal 
    figure('Name', ['Raw vs Detrended - ' dataset_names{i}], 'NumberTitle', 'off');
    clf;
    
    plot(time, dx, 'LineWidth', 1.2);
    hold on;
    plot(time, dx_detrended, 'LineWidth', 1.2);
    
    xlabel('Time (s)');
    ylabel('Displacement (pixels)');
    title(['Raw and Detrended Displacement: ' dataset_names{i}]);
    legend('Raw dx', 'Detrended dx', 'Location', 'best');
    grid on;
    
    %% Figure 2: PDF + Gaussian PDF + CDF Comparison 
    figure('Name', ['PDF/CDF - ' dataset_names{i}], 'NumberTitle', 'off');
    clf;
    
    h1 = histogram(dx_detrended, numBins, 'Normalization', 'pdf');
    hold on;
    
    x_vals = linspace(min(dx_detrended), max(dx_detrended), 1000);
    gaussian_pdf = normpdf(x_vals, 0, sigma);
    h2 = plot(x_vals, gaussian_pdf, 'LineWidth', 2);
    
    [f, x] = ecdf(dx_detrended);
    h3 = plot(x, f, 'LineWidth', 1.5);
    h4 = plot(x, normcdf(x, 0, sigma), 'LineWidth', 1.5);
    
    h5 = xline(0, '--k', 'Zero Mean');
    
    xlim([-4*sigma, 4*sigma]);
    
    xlabel('Detrended Displacement (pixels)');
    ylabel('PDF / CDF')
    title(['Detrended PDF and CDF Comparison: ' dataset_names{i}]);
    legend('Empirical PDF', 'Gaussian PDF', ...
       'Empirical CDF', 'Gaussian CDF', ...
       'Zero Mean', 'Location','best');
    grid on;
    
    %% Figure 3: Q-Q Plot 
    figure('Name', ['QQ Plot - ' dataset_names{i}], 'NumberTitle', 'off');
    clf;
    qqplot(dx_detrended);
    title(['Q-Q Plot vs Gaussian (Detrended): ' dataset_names{i}]);
    grid on;
    
    %% Print Individual Dataset Results 
    fprintf('\n====================================================\n');
    fprintf('Dataset: %s\n', dataset_names{i});
    fprintf('File: %s\n', files{i});
    fprintf('Samples after filtering: %d\n', N_all(i));
    fprintf('Mean (mu): %.4f\n', mu);
    fprintf('Variance (sigma^2): %.4f\n', sigma2);
    fprintf('Std Dev (sigma): %.4f\n', sigma);
    fprintf('P(X > %.2f) empirical: %.4f\n', T, P_empirical);
    fprintf('P(X > %.2f) Gaussian: %.4f\n', T, P_theoretical);
    fprintf('P(|X| > %.2f) empirical: %.4f\n', T, P_abs);
    fprintf('P(|X| > %.2f) Gaussian: %.4f\n', T, P_abs_gauss);
    fprintf('Skewness: %.4f\n', sk);
    fprintf('Kurtosis: %.4f\n', k);
    fprintf('P(|Z| > 1) empirical: %.4f\n', Pz);
    fprintf('P(|Z| > 1) Gaussian: %.4f\n', Pz_gauss);
end

%% Final Comparison Table
fprintf('\n\n==================== FINAL COMPARISON ====================\n');
fprintf('%-18s %-8s %-10s %-10s %-10s %-10s %-10s %-10s\n', ...
    'Dataset', 'N', 'Mean', 'Std Dev', 'Skew', 'Kurtosis', 'P(X>1)', 'P(|Z|>1)');
for i = 1:nData
    fprintf('%-18s %-8d %-10.4f %-10.4f %-10.4f %-10.4f %-10.4f %-10.4f\n', ...
    dataset_names{i}, N_all(i), mu_all(i), sigma_all(i), ...
    skew_all(i), kurt_all(i), P_emp_all(i), Pz_all(i));
end

%% Summary Bar Charts 
figure('Name', 'Comparison Summary', 'NumberTitle', 'off');

subplot(2,2,1);
bar(mu_all);
set(gca, 'XTickLabel', dataset_names, 'XTickLabelRotation', 20);
ylabel('Mean');
title('Mean Comparison (Detrended)');
grid on;

subplot(2,2,2);
bar(sigma_all);
set(gca, 'XTickLabel', dataset_names, 'XTickLabelRotation', 20);
ylabel('Std Dev');
title('Standard Deviation Comparison (Detrended)');
grid on;

subplot(2,2,3);
bar(skew_all);
set(gca, 'XTickLabel', dataset_names, 'XTickLabelRotation', 20);
ylabel('Skewness');
title('Skewness Comparison (Detrended)');
grid on;

subplot(2,2,4);
bar(kurt_all);
set(gca, 'XTickLabel', dataset_names, 'XTickLabelRotation', 20);
ylabel('Kurtosis');
title('Kurtosis Comparison (Detrended)');
grid on;

%% Overlay Empirical CDFs 
figure('Name', 'Empirical CDF Comparison', 'NumberTitle', 'off');
hold on;

for i = 1:nData
    [f_i, x_i] = ecdf(all_dx_detrended{i});
    plot(x_i, f_i, 'LineWidth', 2);
end
xline(0,'--k');
xlabel('Detrended Displacement (pixels)');
ylabel('CDF');
title('Empirical CDF Comparison Across Datasets (Detrended)');
legend(dataset_names, 'Location', 'best');
grid on;

%% Overlay Histograms
figure('Name', 'Detrended PDF Comparison', 'NumberTitle', 'off');
hold on;

for i = 1:nData
    histogram(all_dx_detrended{i}, numBins, ...
        'Normalization', 'pdf', ...
        'DisplayStyle', 'stairs', ...
        'LineWidth', 1.5);
end

xlabel('Detrended Displacement (pixels)');
ylabel('Probability Density');
title('Detrended PDF Comparison Across Datasets');
legend(dataset_names, 'Location', 'best');
grid on;