%% =========================================================
%  Truss Node Polynomial Fitting — Abaqus Simulation Data
%  Fits a degree-n polynomial to x and y displacements of
%  each node as a function of load, then exports to CSV.
%
%  Data range: all available load steps (0.15 → 1.0 kg)
%  Nodes: A B C D E F G H I  (x and y per node)
% =========================================================

clear; clc; close all;

%% ---------- USER SETTINGS ----------
n           = 3;                                    % Polynomial degree
csv_input   = 'Abaqus simulation data/Abaqus_node_displacement_data.csv';
csv_output  = 'Poly_Fit_Results.csv';
% ------------------------------------

%% --- Read CSV ---
T = readtable(csv_input, 'VariableNamingRule', 'preserve');

% Extract load vector
load_fit = T.("load(kg)");

% Node names and their column name pairs in the table
node_names = {'A','B','C','D','E','F','G','H','I'};
col_pairs  = { {'Ax','Ay'}, {'Bx','By'}, {'Cx','Cy'}, ...
               {'Dx','Dy'}, {'Ex','Ey'}, {'Fx','Fy'}, ...
               {'Gx','Gy'}, {'Hx','Hy'}, {'Ix','Iy'} };

fprintf('=== Abaqus Data | Polynomial Degree: n = %d ===\n', n);
fprintf('Data range: %.2f kg → %.2f kg  (%d points)\n\n', ...
        min(load_fit), max(load_fit), numel(load_fit));
fprintf('%-6s  %-4s  %-8s  %s\n', 'Node', 'Axis', 'R²', ...
        'Polynomial coefficients [highest → constant]');
fprintf('%s\n', repmat('-', 1, 90));

%% --- Fit and collect results ---
out_rows = {};

for k = 1:length(node_names)
    name  = node_names{k};
    cols  = col_pairs{k};

    for ax = 1:2
        axis_label = cols{ax}(end);           % 'x' or 'y'
        data_fit   = T.(cols{ax});

        %% --- Polynomial fit ---
        p    = polyfit(load_fit, data_fit, n);
        yhat = polyval(p, load_fit);

        %% --- R² ---
        ss_res = sum((data_fit - yhat).^2);
        ss_tot = sum((data_fit - mean(data_fit)).^2);
        if ss_tot == 0
            r2 = 1;
        else
            r2 = 1 - ss_res / ss_tot;
        end

        %% --- Human-readable polynomial string ---
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

        %% --- Coefficients as comma-separated string for CSV ---
        coef_str = strjoin(arrayfun(@(c) sprintf('%.8g', c), p, ...
                           'UniformOutput', false), ', ');

        out_rows{end+1} = {name, axis_label, n, r2, poly_str, coef_str};
    end
end

%% --- Export to CSV ---
header = {'Node','Axis','Poly_Degree','R_squared', ...
          'Polynomial_Expression','Coefficients_high_to_low'};

fid = fopen(csv_output, 'w');
fprintf(fid, '%s,%s,%s,%s,%s,%s\n', header{:});
for i = 1:length(out_rows)
    r = out_rows{i};
    fprintf(fid, '%s,%s,%d,%.8f,"%s","%s"\n', ...
            r{1}, r{2}, r{3}, r{4}, r{5}, r{6});
end
fclose(fid);

fprintf('\n✓ Results exported to: %s\n', csv_output);

%% --- Plots ---
figure('Name', sprintf('Abaqus Node Fits (n=%d)', n), 'NumberTitle', 'off');
L_smooth = linspace(min(load_fit), max(load_fit), 300);

for k = 1:length(node_names)
    name = node_names{k};
    cols = col_pairs{k};

    for ax = 1:2
        subplot_idx = (k-1)*2 + ax;
        subplot(length(node_names), 2, subplot_idx);

        data_fit = T.(cols{ax});
        p        = polyfit(load_fit, data_fit, n);
        yhat_s   = polyval(p, L_smooth);

        ss_res = sum((data_fit - polyval(p, load_fit)).^2);
        ss_tot = sum((data_fit - mean(data_fit)).^2);
        r2     = 1 - ss_res / max(ss_tot, eps);

        axis_label = cols{ax}(end);

        hold on;
        scatter(load_fit, data_fit, 30, 'wo', 'filled');
        plot(L_smooth, yhat_s, 'b-', 'LineWidth', 1.5);
        xlabel('Load (kg)');
        ylabel(sprintf('Node %s – %s (mm)', name, axis_label));
        title(sprintf('Node %s  %s  |  R²=%.5f', name, axis_label, r2));
        grid on; box on;
    end
end
sgtitle(sprintf('Abaqus Polynomial Fits  |  Degree n = %d', n));