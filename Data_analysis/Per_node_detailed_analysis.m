% =========================================================================
%  Per-node polyfit deviation plots
%
%  Layout:
%    Row 1: B, D, E, G, I
%    Row 2: A, C, F, H
%
%  For each node, this script plots the x-y movement path using:
%    1) Image-processing polyfit from Image_processing_data/Poly_Fit_Results.csv
%    2) Abaqus polyfit from Abaqus simulation data/Poly_Fit_Results.csv
%    3) Measured points from Image_processing_data/Processed_data.csv
%
%  Loads <= 0.42 are shown as the fitted pre-deformation path.
%  The Abaqus fit continues to 1 kg as a dotted prediction line.
%  Loads >= 0.51 are marked at the Processed_data load points for:
%    - processed measured data
%    - image-processing polyfit prediction
%    - Abaqus polyfit prediction
%
%  Each node axis is zoomed independently around that node's movement.
% =========================================================================

clear; clc; close all;

%% ---------------- User settings ----------------
load_fit_end   = 0.42;
load_dev_start = 0.51;
abaqus_fit_end = 1.00;
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

%% ---------------- Load vectors ----------------
pre_load_points = loads(loads <= load_fit_end);
if isempty(pre_load_points)
    error('No processed load points found at or below %.2f.', load_fit_end);
end

L_pre = linspace(min(pre_load_points), load_fit_end, 160);
L_dev = loads(loads >= load_dev_start);
if isempty(L_dev)
    error('No processed load points found at or above %.2f.', load_dev_start);
end

%% ---------------- Plot styling ----------------
c_img    = [0.78, 0.18, 0.20];
c_abaqus = [0.05, 0.38, 0.70];
c_meas   = [0.05, 0.05, 0.05];
c_grid   = [0.65, 0.65, 0.65];

fig = figure('Name', 'Per-node polyfit deviation', ...
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

    % Fitted paths up to 0.42.
    [img_x_pre, img_y_pre] = evalNodePath(image_coef, nd, L_pre);
    [abq_x_pre, abq_y_pre] = evalNodePath(abaqus_coef, nd, L_pre);

    h_img_pre = plot(ax, img_x_pre, img_y_pre, '-', ...
        'Color', c_img, 'LineWidth', 2.0, ...
        'DisplayName', 'Image processing poly fit <= 0.42');
    h_abq_pre = plot(ax, abq_x_pre, abq_y_pre, '-', ...
        'Color', c_abaqus, 'LineWidth', 2.0, ...
        'DisplayName', 'Abaqus poly fit points <= 0.42');

    % Mark the exact Processed_data load points used before 0.42.
    [img_x_pre_pts, img_y_pre_pts] = evalNodePath(image_coef, nd, pre_load_points);
    [abq_x_pre_pts, abq_y_pre_pts] = evalNodePath(abaqus_coef, nd, pre_load_points);
    scatter(ax, img_x_pre_pts, img_y_pre_pts, 18, c_img, 'o', ...
        'filled', 'MarkerFaceAlpha', 0.45, 'MarkerEdgeColor', 'none', ...
        'HandleVisibility', 'off');
    scatter(ax, abq_x_pre_pts, abq_y_pre_pts, 18, c_abaqus, 'd', ...
        'filled', 'MarkerFaceAlpha', 0.45, 'MarkerEdgeColor', 'none', ...
        'HandleVisibility', 'off');

    % Abaqus prediction after 0.42 continues to 1 kg as a dotted line.
    % Image-processing fit after 0.42 is shown only through load-point markers.
    L_abq_ext = linspace(load_fit_end, abaqus_fit_end, 160);
    [abq_x_ext, abq_y_ext] = evalNodePath(abaqus_coef, nd, L_abq_ext);

    plot(ax, abq_x_ext, abq_y_ext, ':', 'Color', c_abaqus, ...
        'LineWidth', 2.0, 'DisplayName', 'Abaqus poly fit points to 1 kg');

    [img_x_dev, img_y_dev] = evalNodePath(image_coef, nd, L_dev);
    [abq_x_dev, abq_y_dev] = evalNodePath(abaqus_coef, nd, L_dev);

    dev_mask = loads >= load_dev_start;
    meas_x_dev = meas.(nd).x(dev_mask);
    meas_y_dev = meas.(nd).y(dev_mask);

    h_meas_dev = scatter(ax, meas_x_dev, meas_y_dev, 34, c_meas, 'o', ...
        'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 0.6, ...
        'DisplayName', 'Measured >= 0.51');
    h_img_dev = scatter(ax, img_x_dev, img_y_dev, 42, c_img, 'o', ...
        'LineWidth', 1.3, 'DisplayName', 'Image processing poly fit >= 0.51');
    h_abq_dev = scatter(ax, abq_x_dev, abq_y_dev, 42, c_abaqus, 'd', ...
        'LineWidth', 1.3, 'DisplayName', 'Abaqus poly fit points >= 0.51');

    % Mark first deviation point so the post-0.51 comparison is easy to find.
    text(ax, meas_x_dev(1), meas_y_dev(1), ' 0.51', ...
        'Color', c_meas, 'FontSize', 8, 'FontWeight', 'bold');

    % Independent zoom around each node's local movement.
    x_all = [img_x_pre(:); abq_x_pre(:); abq_x_ext(:); ...
             meas_x_dev(:); img_x_dev(:); abq_x_dev(:)];
    y_all = [img_y_pre(:); abq_y_pre(:); abq_y_ext(:); ...
             meas_y_dev(:); img_y_dev(:); abq_y_dev(:)];
    setLocalSquareLimits(ax, x_all, y_all);

    title(ax, sprintf('Node %s', nd), 'FontWeight', 'bold', 'Color', 'white');
    xlabel(ax, 'X coordinate', 'Color', 'white');
    ylabel(ax, 'Y coordinate', 'Color', 'white');
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
h_img_pre_l = plot(ax_legend, nan, nan, '-', ...
    'Color', c_img, 'LineWidth', 2.0);
h_abq_pre_l = plot(ax_legend, nan, nan, '-', ...
    'Color', c_abaqus, 'LineWidth', 2.0);
h_abq_ext_l = plot(ax_legend, nan, nan, ':', ...
    'Color', c_abaqus, 'LineWidth', 2.0);
h_meas_dev_l = scatter(ax_legend, nan, nan, 34, c_meas, 'o', ...
    'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 0.6);
h_img_dev_l = scatter(ax_legend, nan, nan, 42, c_img, 'o', ...
    'LineWidth', 1.3);
h_abq_dev_l = scatter(ax_legend, nan, nan, 42, c_abaqus, 'd', ...
    'LineWidth', 1.3);
axis(ax_legend, 'off');
legend(ax_legend, ...
    [h_img_pre_l, h_abq_pre_l, h_abq_ext_l, h_meas_dev_l, h_img_dev_l, h_abq_dev_l], ...
    {'Image processing poly fit <= 0.42', 'Abaqus poly fit points <= 0.42', 'Abaqus dotted fit to 1 kg', ...
     'Measured >= 0.51', 'Image processing poly fit >= 0.51', ...
     'Abaqus poly fit points >= 0.51'}, ...
    'Location', 'northwest', 'FontSize', 9, 'TextColor', 'white', 'Color', 'black');
text(ax_legend, 0.02, 0.42, ...
    sprintf('Solid paths: fitted range to %.2f\nDotted blue path: Abaqus poly fit points to %.2f kg\nMarked points: Processed data loads >= %.2f', ...
            load_fit_end, abaqus_fit_end, load_dev_start), ...
    'Units', 'normalized', 'FontSize', 9, 'Color', [0.90, 0.90, 0.90]);
hold(ax_legend, 'off');

if save_figure
    out_file = fullfile(repo_dir, 'Results', 'node_polyfit_deviation_subplots.png');
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

function setLocalSquareLimits(ax, x_values, y_values)
    x_values = x_values(isfinite(x_values));
    y_values = y_values(isfinite(y_values));

    x_min = min(x_values);
    x_max = max(x_values);
    y_min = min(y_values);
    y_max = max(y_values);

    x_span = max(x_max - x_min, 0.5);
    y_span = max(y_max - y_min, 0.5);
    span = max([x_span, y_span, 1.0]) * 1.18;

    x_mid = (x_min + x_max) / 2;
    y_mid = (y_min + y_max) / 2;

    xlim(ax, x_mid + [-span, span] / 2);
    ylim(ax, y_mid + [-span, span] / 2);
end
