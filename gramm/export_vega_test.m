%% Complete Gramm Test Suite - SVG and Vega Export
% Generates all SVG files and Vega-Lite outputs for gramm tests

clear; clc; close all;

vega_dir = './gramm_vega';
svg_dir = './gramm_svg';

if ~exist(vega_dir, 'dir')
    mkdir(vega_dir);
end
if ~exist(svg_dir, 'dir')
    mkdir(svg_dir);
end

svg_files = {};
test_titles = {};

%% Test 1: geom_point - Basic Scatter Plot
figure('Visible', 'off');
x1 = randn(50, 1);
y1 = randn(50, 1);

g1 = gramm('x', x1, 'y', y1);
g1.geom_point();
g1.set_title('Basic Scatter Plot');
g1.set_names('x', 'X Values', 'y', 'Y Values');
g1.draw();

export_vega(g1, 'file_name', 'test_geom_point', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_point.svg');
g1.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_point.svg';
test_titles{end+1} = 'Basic Scatter Plot';

%% Test 2: geom_point with Color Groups
figure('Visible', 'off');
x2 = randn(60, 1);
y2 = randn(60, 1);
colors = repmat([4, 6, 8], 1, 20);

g2 = gramm('x', x2, 'y', y2, 'color', colors);
g2.geom_point();
g2.set_title('Scatter Plot with Color Groups');
g2.set_names('x', 'X Values', 'y', 'Y Values', 'color', 'Group');
g2.draw();

export_vega(g2, 'file_name', 'test_geom_point_colors', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_point_colors.svg');
g2.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_point_colors.svg';
test_titles{end+1} = 'Scatter Plot with Color Groups';

%% Test 3: geom_line - Line Chart
figure('Visible', 'off');
x3 = 1:20;
y3 = cumsum(randn(1, 20));

g3 = gramm('x', x3, 'y', y3);
g3.geom_line();
g3.set_title('Basic Line Chart');
g3.set_names('x', 'Time', 'y', 'Value');
g3.draw();

export_vega(g3, 'file_name', 'test_geom_line', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_line.svg');
g3.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_line.svg';
test_titles{end+1} = 'Basic Line Chart';

%% Test 4: geom_line with Multiple Series
figure('Visible', 'off');
n = 15;
x = repmat(1:n, 1, 3);
y = [cumsum(randn(1,n)), cumsum(randn(1,n)) + 2, cumsum(randn(1,n)) - 1];
groups = [repmat(4,1,n), repmat(6,1,n), repmat(8,1,n)];

g = gramm('x', x, 'y', y, 'color', groups);
g.geom_line();
g.set_title('Multi-Series Line Chart');
g.set_names('x', 'Time', 'y', 'Value', 'color', 'Series');
g.draw();

export_vega(g, 'file_name', 'test_geom_line_multi', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_line_multi.svg');
g.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_line_multi.svg';
test_titles{end+1} = 'Multi-Series Line Chart';

%% Test 5: geom_bar - Bar Chart with Categorical Data
figure('Visible', 'off');
categories = {'A', 'B', 'C', 'D', 'E'};
values = [23, 45, 56, 78, 32];

g5 = gramm('x', categories, 'y', values);
g5.geom_bar();
g5.set_title('Categorical Bar Chart');
g5.set_names('x', 'Category', 'y', 'Count');
g5.draw();

export_vega(g5, 'file_name', 'test_geom_bar_categorical', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_bar_categorical.svg');
g5.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_bar_categorical.svg';
test_titles{end+1} = 'Categorical Bar Chart';

%% Test 6: geom_bar with Numeric Data and Groups
figure('Visible', 'off');
x_bars = repmat([1, 2, 3, 4], 1, 3);
y_bars = [10, 15, 12, 18, 8, 20, 14, 22, 16, 25, 11, 19];
bar_groups = [repmat(4,1,4), repmat(6,1,4), repmat(8,1,4)];

g6 = gramm('x', x_bars, 'y', y_bars, 'color', bar_groups);
g6.geom_bar('dodge', 0.6);
g6.set_title('Grouped Bar Chart');
g6.set_names('x', 'Position', 'y', 'Value', 'color', 'Group');
g6.draw();

export_vega(g6, 'file_name', 'test_geom_bar_groups', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_bar_groups.svg');
g6.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_bar_groups.svg';
test_titles{end+1} = 'Grouped Bar Chart';

%% Test 7: geom_jitter - Jittered Points
figure('Visible', 'off');
categories_jitter = repmat({'Low', 'Medium', 'High'}, 1, 20);
values_jitter = [randn(1, 20) + 1, randn(1, 20) + 3, randn(1, 20) + 5];

g7 = gramm('x', categories_jitter, 'y', values_jitter);
g7.geom_jitter('width', 0.3);
g7.set_title('Jittered Points');
g7.set_names('x', 'Category', 'y', 'Value');
g7.draw();

export_vega(g7, 'file_name', 'test_geom_jitter', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_jitter.svg');
g7.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_jitter.svg';
test_titles{end+1} = 'Jittered Points';

%% Test 8: geom_raster - Strip Plot
figure('Visible', 'off');
x_raster = randn(100, 1) * 2;

g8 = gramm('x', x_raster);
g8.geom_raster();
g8.set_title('Strip Plot (Raster)');
g8.set_names('x', 'Values');
g8.draw();

export_vega(g8, 'file_name', 'test_geom_raster', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_raster.svg');
g8.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_raster.svg';
test_titles{end+1} = 'Strip Plot (Raster)';

%% Test 9: Combined geom_point and geom_line
figure('Visible', 'off');
x9 = 1:10;
y9 = x9 + randn(1, 10);

g9 = gramm('x', x9, 'y', y9);
g9.geom_point();
g9.geom_line();
g9.set_title('Combined Point and Line');
g9.set_names('x', 'X Values', 'y', 'Y Values');
g9.draw();

export_vega(g9, 'file_name', 'test_combined_point_line', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_combined_point_line.svg');
g9.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_combined_point_line.svg';
test_titles{end+1} = 'Combined Point and Line';

%% Test 10: Data with NaN Values
figure('Visible', 'off');
x_nan = 1:15;
y_nan = [1, 2, NaN, 4, 5, NaN, 7, 8, 9, NaN, 11, 12, 13, 14, 15];

g10 = gramm('x', x_nan, 'y', y_nan);
g10.geom_point();
g10.geom_line();
g10.set_title('Data with NaN Values');
g10.set_names('x', 'Index', 'y', 'Value');
g10.draw();

export_vega(g10, 'file_name', 'test_nan_handling', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_nan_handling.svg');
g10.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_nan_handling.svg';
test_titles{end+1} = 'Data with NaN Values';

%% Test 11: Custom Parameters
figure('Visible', 'off');
x_custom = linspace(0, 4*pi, 100);
y_custom = sin(x_custom) .* exp(-x_custom/10);

g11 = gramm('x', x_custom, 'y', y_custom);
g11.geom_line();
g11.set_title('Damped Sine Wave');
g11.set_names('x', 'Time (s)', 'y', 'Amplitude');
g11.draw();

export_vega(g11, 'file_name', 'test_custom_params', 'export_path', vega_dir, ...
    'title', 'Damped Sine Wave', 'x', 'Time (s)', 'y', 'Amplitude', ...
    'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_custom_params.svg');
g11.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_custom_params.svg';
test_titles{end+1} = 'Custom Export Parameters';

%% Test 12: geom_swarm (Beeswarm approximation)
figure('Visible', 'off');
groups_swarm = repmat({'Group A', 'Group B', 'Group C'}, 1, 15);
values_swarm = [randn(1, 15) + 2, randn(1, 15) + 4, randn(1, 15) + 6];

g12 = gramm('x', groups_swarm, 'y', values_swarm);
g12.geom_swarm();
g12.set_title('Beeswarm Plot');
g12.set_names('x', 'Group', 'y', 'Value');
g12.draw();

export_vega(g12, 'file_name', 'test_geom_swarm', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_geom_swarm.svg');
g12.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_geom_swarm.svg';
test_titles{end+1} = 'Beeswarm Plot';

%% Test 13: Interactive Legend - Scatter Plot
figure('Visible', 'off');
x_int = randn(80, 1);
y_int = randn(80, 1);
colors_int = repmat({'Red Group', 'Blue Group', 'Green Group', 'Orange Group'}, 1, 20);

g13 = gramm('x', x_int, 'y', y_int, 'color', colors_int);
g13.geom_point();
g13.set_title('Interactive Scatter Plot - Click Legend to Filter');
g13.set_names('x', 'X Values', 'y', 'Y Values', 'color', 'Groups');
g13.draw();

export_vega(g13, 'file_name', 'test_interactive_scatter', 'export_path', vega_dir, ...
    'interactive', 'true', 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_interactive_scatter.svg');
g13.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_interactive_scatter.svg';
test_titles{end+1} = 'Interactive Scatter Plot';

%% Test 14: Interactive Legend - Line Chart
figure('Visible', 'off');
x_lines = repmat(1:20, 1, 4);
y_lines = [];
line_groups = [];
group_names = {'Sales', 'Marketing', 'Engineering', 'Support'};

for i = 1:4
    y_lines = [y_lines, cumsum(randn(1, 20)) + i*5];
    line_groups = [line_groups, repmat(group_names(i), 1, 20)];
end

g14 = gramm('x', x_lines, 'y', y_lines, 'color', line_groups);
g14.geom_line();
g14.set_title('Interactive Multi-Series Lines - Click Legend to Highlight');
g14.set_names('x', 'Time Period', 'y', 'Performance Score', 'color', 'Department');
g14.draw();

export_vega(g14, 'file_name', 'test_interactive_lines', 'export_path', vega_dir, ...
    'interactive', 'true', 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_interactive_lines.svg');
g14.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_interactive_lines.svg';
test_titles{end+1} = 'Interactive Multi-Series Lines';

%% Test 15: Interactive Legend - Grouped Bar Chart
figure('Visible', 'off');
quarters = repmat({'Q1', 'Q2', 'Q3', 'Q4'}, 1, 3);
revenues = [120, 150, 180, 200, 80, 95, 110, 125, 60, 70, 85, 90];
divisions = repmat({'North', 'South', 'West'}, 1, 4);

g15 = gramm('x', quarters, 'y', revenues, 'color', divisions);
g15.geom_bar();
g15.set_title('Interactive Grouped Bars - Legend Controls Visibility');
g15.set_names('x', 'Quarter', 'y', 'Revenue (K)', 'color', 'Division');
g15.draw();

export_vega(g15, 'file_name', 'test_interactive_bars', 'export_path', vega_dir, ...
    'interactive', 'true', 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_interactive_bars.svg');
g15.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_interactive_bars.svg';
test_titles{end+1} = 'Interactive Grouped Bars';

%% Test 16: Interactive Jitter Plot
figure('Visible', 'off');
treatments = repmat({'Control', 'Treatment A', 'Treatment B'}, 1, 25);
responses = [randn(1, 25) + 2, randn(1, 25) + 4, randn(1, 25) + 3.5];

g16 = gramm('x', treatments, 'y', responses, 'color', treatments);
g16.geom_jitter('width', 0.4);
g16.set_title('Interactive Jitter Plot - Filter by Treatment');
g16.set_names('x', 'Treatment', 'y', 'Response', 'color', 'Treatment');
g16.draw();

export_vega(g16, 'file_name', 'test_interactive_jitter', 'export_path', vega_dir, ...
    'interactive', 'true', 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_interactive_jitter.svg');
g16.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_interactive_jitter.svg';
test_titles{end+1} = 'Interactive Jitter Plot';

%% Test 17: Standard Legend (Non-Interactive)
figure('Visible', 'off');
x_std = randn(75, 1);
y_std = randn(75, 1);
groups_std = repmat({'Alpha', 'Beta', 'Gamma'}, 1, 25);

g17 = gramm('x', x_std, 'y', y_std, 'color', groups_std);
g17.geom_point();
g17.set_title('Standard Legend (Non-Interactive)');
g17.set_names('x', 'X Values', 'y', 'Y Values', 'color', 'Groups');
g17.draw();

export_vega(g17, 'file_name', 'test_standard_legend', 'export_path', vega_dir, 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_standard_legend.svg');
g17.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_standard_legend.svg';
test_titles{end+1} = 'Standard Legend (Non-Interactive)';

%% Test 18: Interactive Legend Demo
figure('Visible', 'off');
x_demo = randn(100, 1);
y_demo = randn(100, 1);
demo_groups = repmat({'Click Me', 'Shift+Click', 'Multi-Select', 'Reset'}, 1, 25);

g18 = gramm('x', x_demo, 'y', y_demo, 'color', demo_groups);
g18.geom_point();
g18.set_title('Interactive Legend Demo - Click & Shift+Click');
g18.set_names('x', 'X Values', 'y', 'Y Values', 'color', 'Interactive Groups');
g18.draw();

export_vega(g18, 'file_name', 'test_interactive_legend', 'export_path', vega_dir, ...
    'interactive', 'true', 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_interactive_legend.svg');
g18.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_interactive_legend.svg';
test_titles{end+1} = 'Interactive Legend Demo';

%% Test 19: Large Dataset Interactive Test
figure('Visible', 'off');
x_large = randn(500, 1);
y_large = randn(500, 1);
large_groups = repmat({'Dataset A', 'Dataset B', 'Dataset C', 'Dataset D', 'Dataset E'}, 1, 100);

g19 = gramm('x', x_large, 'y', y_large, 'color', large_groups);
g19.geom_point();
g19.set_title('Large Dataset Interactive Test - 500 Points');
g19.set_names('x', 'X Values', 'y', 'Y Values', 'color', 'Datasets');
g19.draw();

export_vega(g19, 'file_name', 'test_large_interactive', 'export_path', vega_dir, ...
    'interactive', 'true', 'width', '400', 'height', '300');

svg_filename = fullfile(svg_dir, 'test_large_interactive.svg');
g19.export('file_name', svg_filename);
close all;

svg_files{end+1} = 'test_large_interactive.svg';
test_titles{end+1} = 'Large Dataset Interactive Test';