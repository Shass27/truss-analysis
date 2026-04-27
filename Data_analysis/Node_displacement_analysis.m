clear; clc; close all;

%% ---- READ DATA ----
raw = readmatrix('Image_processing_data/Processed_data.csv', 'NumHeaderLines', 2);

loads  = raw(:, 1);
nLoads = length(loads);

colIdx = [3,4; 6,7; 9,10; 12,13; 15,16; 18,19; 21,22; 24,25; 27,28];
nodeNames = {'A','B','C','D','E','F','G','H','I'};
nNodes = 9;

%% ---- NODE COLORS ----
colors = [
    0.85, 0.15, 0.15;
    0.10, 0.45, 0.85;
    0.10, 0.70, 0.25;
    0.90, 0.50, 0.00;
    0.60, 0.10, 0.80;
    0.00, 0.70, 0.70;
    0.75, 0.65, 0.00;
    0.85, 0.25, 0.60;
    0.20, 0.55, 0.30;
];

%% ---- EXTRACT POSITIONS ----
nodeX = zeros(nLoads, nNodes);
nodeY = zeros(nLoads, nNodes);

for n = 1:nNodes
    nodeX(:, n) = raw(:, colIdx(n, 1));
    nodeY(:, n) = raw(:, colIdx(n, 2));
end

%% ---- CONNECTIVITY ----
% A=1 B=2 C=3 D=4 E=5 F=6 G=7 H=8 I=9
members = [
    1,2;   % AB
    1,3;   % AC
    2,4;   % BD
    1,4;   % AD
    3,4;   % CD
    4,5;   % DE
    3,5;   % CE
    3,6;   % CF
    5,6;   % EF
    5,7;   % EG
    6,7;   % FG
    6,8;   % FH
    7,8;   % GH
    7,9;   % GI
    8,9;   % HI
];

%% ---- FIGURE ----
figure('Color', 'white', 'Position', [100, 100, 1100, 650]);
hold on;

%% ---- PLOT NODE TRAJECTORIES (darkening as load increases) ----
for n = 1:nNodes
    base = colors(n, :);
    for i = 1:nLoads - 1
        t = (i - 1) / (nLoads - 1);
        darkFactor = 1.0 - 0.72 * t;
        lineCol = base * darkFactor;
        plot([nodeX(i,n), nodeX(i+1,n)], ...
             [nodeY(i,n), nodeY(i+1,n)], ...
             '-', 'Color', lineCol, 'LineWidth', 2.5);
    end
end

%% ---- JOIN NODES: INITIAL STATE ----
for m = 1:size(members, 1)
    n1 = members(m,1); n2 = members(m,2);
    plot([nodeX(1,n1), nodeX(1,n2)], [nodeY(1,n1), nodeY(1,n2)], ...
         '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.8);
end

%% ---- JOIN NODES: FINAL STATE ----
for m = 1:size(members, 1)
    n1 = members(m,1); n2 = members(m,2);
    plot([nodeX(end,n1), nodeX(end,n2)], [nodeY(end,n1), nodeY(end,n2)], ...
         '-', 'Color', [0.15 0.15 0.15], 'LineWidth', 2.2);
end

%% ---- MARKERS at start (circle) and end (square) ----
for n = 1:nNodes
    scatter(nodeX(1,   n), nodeY(1,   n), 70, colors(n,:), 'o', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
    scatter(nodeX(end, n), nodeY(end, n), 70, colors(n,:), 's', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
    text(nodeX(1,n) + 2, nodeY(1,n) + 2, nodeNames{n}, ...
         'FontSize', 9, 'FontWeight', 'bold', 'Color', colors(n,:) * 0.7);
end

%% ---- LEGEND ----
trajHandles = gobjects(nNodes, 1);
for n = 1:nNodes
    trajHandles(n) = plot(nan, nan, '-', 'Color', colors(n,:), ...
                          'LineWidth', 2.5, 'DisplayName', ['Node ' nodeNames{n}]);
end
hInit  = plot(nan, nan, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.8, ...
              'DisplayName', sprintf('Initial (%.2f N)', loads(1)));
hFinal = plot(nan, nan, '-',  'Color', [0.15 0.15 0.15], 'LineWidth', 2.2, ...
              'DisplayName', sprintf('Final (10 N)', loads(end)));
hCirc  = scatter(nan, nan, 60, [0.3 0.3 0.3], 'o', 'filled', 'DisplayName', 'Start position');
hSq    = scatter(nan, nan, 60, [0.3 0.3 0.3], 's', 'filled', 'DisplayName', 'End position');

legend([trajHandles; hInit; hFinal; hCirc; hSq], ...
       'Location', 'eastoutside', 'FontSize', 8.5);

%% ---- AXES ----
xlabel('X Position (px)', 'FontSize', 11);
ylabel('Y Position (px)', 'FontSize', 11);
title('Node Displacement Under Increasing Load — All Nodes', ...
      'FontSize', 13, 'FontWeight', 'bold');
grid on; box on;
axis equal;

ax = gca;
ax.Color       = 'white';
ax.XColor      = 'black';
ax.YColor      = 'black';
ax.GridColor   = [0.15 0.15 0.15];
ax.FontSize    = 10;
ax.FontWeight  = 'bold';
ax.Title.Color  = 'black';
ax.XLabel.Color = 'black';
ax.YLabel.Color = 'black';

hold off;

% %% ---- EXPORT ----
% exportgraphics(gcf, 'truss_node_displacement.png', 'Resolution', 600);