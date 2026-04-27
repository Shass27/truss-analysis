%% =========================================================
%  Truss Node Polynomial Fitting
%  Fits a degree-n polynomial to x and y positions of each
%  node as a function of load, then exports results to CSV.
%
%  NOTE: Pre-deformation range used: 0 → 0.42 kg.
%        Deformation onset observed at ~0.51 kg.
%        Adjust 'load_min' / 'load_max' below to change the range.
% =========================================================

clear; clc; close all;

%% ---------- USER SETTINGS ----------
n              = 3;            % Polynomial degree (change this to compare)
load_min       = 0;            % Use data FROM this load value (kg)
load_max       = 0.42;         % Use data UP TO this load value (kg)
                               % Pre-deformation range: 0 → 0.42 kg
csv_input      = 'Processed_data.csv';
csv_output     = 'Poly_Fit_Results.csv';
% ------------------------------------

%% --- Node definitions ---
node_names = {'A','B','C','D','E','F','G','H','I'};

% Column indices of [x, y] for each node in the raw CSV
% Pattern: load(col1), empty(2), A_x(3), A_y(4), empty(5), B_x(6), ...
node_cols = [3,4;  % A
             6,7;  % B
             9,10; % C
             12,13;% D
             15,16;% E
             18,19;% F
             21,22;% G
             24,25;% H
             27,28];% I

%% --- Read raw CSV (skip 2 header rows) ---
raw = readmatrix('Image_processing_data/Processed_data.csv', 'NumHeaderLines', 2);

% Column 1 = load, keep only numeric rows where load is defined
load_all = raw(:, 1);
valid    = ~isnan(load_all);
raw      = raw(valid, :);
load_all = load_all(valid);

% Apply load range [load_min, load_max]
mask     = load_all >= load_min & load_all <= load_max;
load_fit = load_all(mask);

fprintf('Data range used: %.2f kg → %.2f kg  (%d points)\n\n', ...
        min(load_fit), max(load_fit), numel(load_fit));

fprintf('=== Polynomial Degree: n = %d ===\n\n', n);
fprintf('%-6s  %-4s  %-8s  %-55s\n', 'Node', 'Axis', 'R²', 'Polynomial coefficients [highest → constant]');
fprintf('%s\n', repmat('-', 1, 80));

%% --- Preallocate output table rows ---
out_rows = {};

%% --- Loop over each node ---
for k = 1:length(node_names)
    name = node_names{k};
    cx   = node_cols(k, 1);
    cy   = node_cols(k, 2);

    for ax = 1:2   % 1 = x, 2 = y
        if ax == 1
            axis_label = 'x';
            col_idx    = cx;
        else
            axis_label = 'y';
            col_idx    = cy;
        end

        data_all = raw(:, col_idx);
        data_fit = data_all(mask);

        % --- Fit polynomial ---
        p    = polyfit(load_fit, data_fit, n);
        yhat = polyval(p, load_fit);

        % --- R² ---
        ss_res = sum((data_fit - yhat).^2);
        ss_tot = sum((data_fit - mean(data_fit)).^2);
        if ss_tot == 0
            r2 = 1;   % constant signal → perfect fit
        else
            r2 = 1 - ss_res / ss_tot;
        end

        % --- Build human-readable polynomial string ---
        terms = {};
        for i = 1:length(p)
            power = n - (i - 1);
            coef  = p(i);
            if abs(coef) < 1e-12; continue; end
            if power == 0
                terms{end+1} = sprintf('%.6g', coef);
            elseif power == 1
                terms{end+1} = sprintf('%.6g·L', coef);
            else
                terms{end+1} = sprintf('%.6g·L^%d', coef, power);
            end
        end
        poly_str = strjoin(terms, ' + ');
        poly_str = strrep(poly_str, '+ -', '- ');

        fprintf('%-6s  %-4s  %-8.5f  %s\n', name, axis_label, r2, poly_str);

        % --- Build coefficient string for CSV ---
        coef_str = strjoin(arrayfun(@(c) sprintf('%.8g', c), p, ...
                           'UniformOutput', false), ', ');

        % Store row: Node, Axis, Degree, R2, poly string, coef list
        out_rows{end+1} = {name, axis_label, n, r2, poly_str, coef_str};
    end
end

%% --- Export to CSV ---
header = {'Node', 'Axis', 'Poly_Degree', 'R_squared', ...
          'Polynomial_Expression', 'Coefficients_high_to_low'};

fid = fopen(csv_output, 'w');
fprintf(fid, '%s,%s,%s,%s,%s,%s\n', header{:});
for i = 1:length(out_rows)
    r = out_rows{i};
    fprintf(fid, '%s,%s,%d,%.8f,"%s","%s"\n', ...
            r{1}, r{2}, r{3}, r{4}, r{5}, r{6});
end
fclose(fid);

fprintf('\n✓ Results exported to: %s\n', csv_output);

%% --- Optional: Plot fits ---
figure('Name', sprintf('Node Fits (n=%d)', n), 'NumberTitle', 'off');
num_nodes = length(node_names);
L_smooth  = linspace(min(load_fit), max(load_fit), 200);

for k = 1:num_nodes
    name = node_names{k};
    for ax = 1:2
        subplot_idx = (k-1)*2 + ax;
        subplot(num_nodes, 2, subplot_idx);

        col_idx  = node_cols(k, ax);
        data_fit = raw(mask, col_idx);
        p        = polyfit(load_fit, data_fit, n);
        yhat_s   = polyval(p, L_smooth);

        % R²
        ss_res = sum((data_fit - polyval(p, load_fit)).^2);
        ss_tot = sum((data_fit - mean(data_fit)).^2);
        r2 = 1 - ss_res / max(ss_tot, eps);

        hold on;
        scatter(load_fit, data_fit, 30, 'ko', 'filled');
        plot(L_smooth, yhat_s, 'r-', 'LineWidth', 1.5);
        xlabel('Load (kg)'); 
        ylabel(sprintf('%s_%s (px)', name, ifthenelse(ax==1,'x','y')));
        title(sprintf('Node %s – %s  (R²=%.4f)', name, ...
              ifthenelse(ax==1,'x','y'), r2));
        grid on; box on;
    end
end
sgtitle(sprintf('Polynomial Fits  |  Degree n = %d', n));

%% --- Helper: ternary inline ---
function out = ifthenelse(cond, a, b)
    if cond; out = a; else; out = b; end
end