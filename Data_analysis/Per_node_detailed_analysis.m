% =========================================================================
%  Per-node load-step displacement plots
%
%  Layout:
%    Row 1: B, D, E, G, I
%    Row 2: A, C, F, H
%
%  For each node, this script plots displacement between consecutive loads
%  as a function of load using:
%    1) Measured points from Image_processing_data/Processed_data.csv
%    2) Image-processing polyfit from Image_processing_data/Poly_Fit_Results.csv
%    3) Abaqus polyfit from Abaqus simulation data/Poly_Fit_Results.csv
%
%  Step displacement at load L_i is computed from positions at
%  [L_(i-1), L_i] using sqrt((dx)^2 + (dy)^2).
% =========================================================================

clear; clc; close all;

%% ---------------- User settings ----------------
save_figure    = false;
% -------------------------------------------------

%% ---------------- File locations ----------------
script_dir = fileparts(mfilename('fullpath'));
repo_dir   = fullfile(script_dir, '..');

processed_file = fullfile(repo_dir, 'Image_processing_data', ...
                          'Processed_data.csv');
image_fit_file = fullfile(repo_dir, 'Image_processing_data', ...
                          'Poly_Fit_Results.csv');
abaqus_fit_file = fullfile(repo_dir, 'Abaqus simulation data', ...
                           'Poly_Fit_Results.csv');

%% ---------------- Read processed image data ----------------
raw = readmatrix(processed_file, 'NumHeaderLines', 2);

loads = raw(:, 1);
valid = ~isnan(loads);
raw   = raw(valid, :);
loads = loads(valid);

node_names = {'A','B','C','D','E','F','G','H','I'};
node_order = {'B','D','E','G','I','A','C','F','H'};

% Column pairs in Processed_data.csv: [x, y]
node_cols = [3, 4;    % A
             6, 7;    % B
             9, 10;   % C
             12, 13;  % D
             15, 16;  % E
             18, 19;  % F
             21, 22;  % G
             24, 25;  % H
             27, 28]; % I

meas = struct();
for i = 1:numel(node_names)
    nd = node_names{i};
    meas.(nd).x = raw(:, node_cols(i, 1));
    meas.(nd).y = raw(:, node_cols(i, 2));
end

%% ---------------- Read polyfit coefficients ----------------
image_coef  = readPolyfitCoefficients(image_fit_file, node_names);
abaqus_coef = readPolyfitCoefficients(abaqus_fit_file, node_names);

if numel(loads) < 2
    error('At least two load points are required to compute load-step displacement.');
end

%% ---------------- Plot styling ----------------
c_img    = [0.78, 0.18, 0.20];
c_abaqus = [0.05, 0.38, 0.70];
c_meas   = [0.05, 0.05, 0.05];
c_grid   = [0.65, 0.65, 0.65];

fig = figure('Name', 'Per-node load-step displacement', ...
             'NumberTitle', 'off', ...
             'Color', 'black', ...
             'Units', 'normalized', ...
             'Position', [0.02, 0.05, 0.96, 0.84]);

tl = tiledlayout(2, 5, 'TileSpacing', 'compact');
tl.Padding = 'normal';  % Use 'normal' padding to create space for title
tl.TileIndexing = 'rowmajor';

for k = 1:numel(node_order)
    nd = node_order{k};
    ax = nexttile(k);
    hold(ax, 'on');

    [img_x, img_y] = evalNodePath(image_coef, nd, loads);
    [abq_x, abq_y] = evalNodePath(abaqus_coef, nd, loads);

    [L_meas, disp_meas] = computeLoadStepDisplacement(loads, meas.(nd).x, meas.(nd).y);
    [L_img, disp_img] = computeLoadStepDisplacement(loads, img_x, img_y);
    [L_abq, disp_abq] = computeLoadStepDisplacement(loads, abq_x, abq_y);

    h_meas = plot(ax, L_meas, disp_meas, '-o', ...
        'Color', c_meas, 'LineWidth', 1.8, 'MarkerSize', 4.5, ...
        'MarkerFaceColor', c_meas, 'MarkerEdgeColor', 'white', ...
        'DisplayName', 'Measured load-step displacement');
    h_img = plot(ax, L_img, disp_img, '-o', ...
        'Color', c_img, 'LineWidth', 1.8, 'MarkerSize', 4.5, ...
        'MarkerFaceColor', c_img, 'DisplayName', 'Image processing polyfit load-step displacement');
    h_abq = plot(ax, L_abq, disp_abq, '-d', ...
        'Color', c_abaqus, 'LineWidth', 1.8, 'MarkerSize', 4.8, ...
        'MarkerFaceColor', c_abaqus, 'DisplayName', 'Abaqus polyfit load-step displacement');

    if isempty(L_meas) && isempty(L_img) && isempty(L_abq)
        text(ax, 0.5, 0.5, 'No valid load-step points', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'Color', 'white', 'FontSize', 9, 'FontWeight', 'bold');
    end

    xlim(ax, [min(loads), max(loads)]);
    setLocalYLimits(ax, [disp_meas(:); disp_img(:); disp_abq(:)]);

    title(ax, sprintf('Node %s', nd), 'FontWeight', 'bold', 'Color', 'white');
    xlabel(ax, 'Load', 'Color', 'white');
    ylabel(ax, 'Displacement from previous load', 'Color', 'white');
    grid(ax, 'on');
    box(ax, 'on');
    ax.Color = 'black';
    ax.XColor = 'white';
    ax.YColor = 'white';
    ax.GridColor = c_grid;
    ax.GridAlpha = 0.35;
    ax.FontSize = 9;
    pbaspect(ax, [1, 1, 1]);

    hold(ax, 'off');
end

%% ---------------- Legend / notes tile ----------------
ax_legend = nexttile(10);
hold(ax_legend, 'on');
h_meas_l = plot(ax_legend, nan, nan, '-o', ...
    'Color', c_meas, 'LineWidth', 1.8, 'MarkerSize', 4.5, ...
    'MarkerFaceColor', c_meas, 'MarkerEdgeColor', 'white');
h_img_l = plot(ax_legend, nan, nan, '-o', ...
    'Color', c_img, 'LineWidth', 1.8, 'MarkerSize', 4.5, ...
    'MarkerFaceColor', c_img);
h_abq_l = plot(ax_legend, nan, nan, '-d', ...
    'Color', c_abaqus, 'LineWidth', 1.8, 'MarkerSize', 4.8, ...
    'MarkerFaceColor', c_abaqus);
axis(ax_legend, 'off');
legend(ax_legend, ...
    [h_meas_l, h_img_l, h_abq_l], ...
    {'Measured load-step displacement', 'Image processing polyfit load-step displacement', ...
     'Abaqus polyfit load-step displacement'}, ...
    'Location', 'northwest', 'FontSize', 9, 'TextColor', 'white', 'Color', 'black');
text(ax_legend, 0.02, 0.42, ...
    sprintf(['Each point at load L_i gives displacement between\n' ...
             'positions at [L_(i-1), L_i].\n' ...
             'Polyfit curves are evaluated at processed load values.\n' ...
             'Displacement units are in mm and load in kg']), ...
    'Units', 'normalized', 'FontSize', 9, 'Color', [0.90, 0.90, 0.90]);
hold(ax_legend, 'off');

if save_figure
    out_file = fullfile(repo_dir, 'Results', 'node_load_step_displacement_subplots.png');
    exportgraphics(fig, out_file, 'Resolution', 300);
    fprintf('Saved figure to: %s\n', out_file);
end

fprintf('\nDone. Figure generated in the following node order.\n');
fprintf('  Row 1: B, D, E, G, I\n');
fprintf('  Row 2: A, C, F, H\n');

%% ========================================================================
%  Local functions
% ========================================================================
function coef = readPolyfitCoefficients(csv_file, node_names)
    T = readtable(csv_file, 'TextType', 'string');

    coef = struct();
    for i = 1:numel(node_names)
        nd = node_names{i};
        for axis_name = ["x", "y"]
            mask = strcmp(string(T.Node), nd) & strcmp(string(T.Axis), axis_name);
            if ~any(mask)
                error('Missing %s-axis polyfit coefficients for node %s in %s.', ...
                      axis_name, nd, csv_file);
            end

            coef_text = string(T.Coefficients_high_to_low(find(mask, 1, 'first')));
            parts = strsplit(coef_text, ',');
            values = str2double(strtrim(parts));
            if any(isnan(values))
                error('Could not parse coefficients for node %s axis %s in %s.', ...
                      nd, axis_name, csv_file);
            end

            coef.(nd).(char(axis_name)) = values;
        end
    end
end

function [x, y] = evalNodePath(coef, node_name, loads)
    x = polyval(coef.(node_name).x, loads);
    y = polyval(coef.(node_name).y, loads);
end

function [step_loads, step_displacement] = computeLoadStepDisplacement(loads, x_values, y_values)
    loads = loads(:);
    x_values = x_values(:);
    y_values = y_values(:);

    if numel(loads) ~= numel(x_values) || numel(loads) ~= numel(y_values)
        error('Load and coordinate vectors must have the same number of elements.');
    end

    dx = diff(x_values);
    dy = diff(y_values);
    all_step_loads = loads(2:end);
    all_step_disp = hypot(dx, dy);

    valid_steps = isfinite(all_step_loads) & isfinite(dx) & isfinite(dy) & isfinite(all_step_disp);
    step_loads = all_step_loads(valid_steps);
    step_displacement = all_step_disp(valid_steps);
end

function setLocalYLimits(ax, y_values)
    y_values = y_values(isfinite(y_values));
    if isempty(y_values)
        ylim(ax, [0, 1]);
        return;
    end

    y_min = min(y_values);
    y_max = max(y_values);

    if y_min == y_max
        pad = max(0.05 * max(abs(y_max), 1), 1e-4);
    else
        pad = 0.10 * (y_max - y_min);
    end

    lower_lim = y_min - pad;
    if y_min >= 0
        lower_lim = max(0, lower_lim);
    end
    ylim(ax, [lower_lim, y_max + pad]);
end
