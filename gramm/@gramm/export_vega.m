function export_vega(g, varargin)
%EXPORT_VEGA Export gramm plot to Vega interactive visualization
%   EXPORT_VEGA(g, ...) exports the gramm plot g to an interactive Vega visualization
%   with the following optional parameters:
%       'file_name' - Name of the output files (default: 'untitled')
%       'export_path' - Path where to save the files (default: './')
%       'x' - X-axis label (default: 'x-axis')
%       'y' - Y-axis label (default: 'y-axis')
%       'title' - Plot title (default: 'Untitled')
%       'width' - Width of the plot in pixels (default: figure width)
%       'height' - Height of the plot in pixels (default: figure height)
%       'interactive' - Enable interactive legend ('true' or 'false', default: 'false')
%       'tooltip' - Enable tooltips on hover ('true' or 'false', default: 'true')
%
%   Example:
%       g = gramm('x', x, 'y', y);
%       g.geom_line();
%       g.draw();
%       export_vega(g, 'file_name', 'my_plot', 'export_path', './output');

% Parse input parameters
params = parseInputParameters(g, varargin);

% Analyze gramm object
gramm_analysis = analyzeGrammObject(g);

% Detect chart types and layers
chart_spec = detectAllChartTypes(gramm_analysis, params);

% Extract and process data
vega_data = extractVegaData(gramm_analysis);

% Generate Vega specification
vega_spec = generateVegaSpecification(chart_spec, vega_data, params);

% Write output files
writeVegaFiles(vega_spec, params);

end

%% ===== CORE ANALYSIS FUNCTIONS =====

function params = parseInputParameters(g, varargin)
    % Get figure dimensions
    h_fig = g(1).parent;
    fig_pos = getpixelposition(h_fig);
    if fig_pos(3) == 0
        width_fig = '500';
    else
        width_fig = num2str(fig_pos(3));
    end
    if fig_pos(4) == 0
        height_fig = '500';
    else
        height_fig = num2str(fig_pos(4));
    end
    
    % Extract axis names from gramm object if available
    default_x_label = 'x-axis';
    default_y_label = 'y-axis';
    
    % Handle gramm arrays - use first element
    gramm_obj = g(1);
    
    % Try to get axis labels from facet_axes_handles
    try
        if ~isempty(gramm_obj.facet_axes_handles)
            default_x_label = gramm_obj.facet_axes_handles(1).XLabel.String;
            default_y_label = gramm_obj.facet_axes_handles(1).YLabel.String;
        end
    catch
        % Keep defaults if extraction fails
    end
    
    % Default parameters
    params = struct();
    params.file_name = 'untitled';
    params.export_path = './';
    params.x_label = default_x_label;
    params.y_label = default_y_label;
    params.title = 'Untitled';
    params.width = width_fig;
    params.height = height_fig;
    params.interactive = 'false';
    params.tooltip = 'true';
    
    % Parse input arguments
    args = varargin{1}; % varargin is a cell containing the arguments
    for i = 1:2:length(args)
        if i <= length(args)
            param_name = args{i};
            
            
            % Ensure parameter name is a string/char and convert to char
            if ischar(param_name)
                param_str = param_name;
            elseif isstring(param_name)
                param_str = char(param_name);
            else
                error('Parameter name at position %d must be a string or char array, got %s', i, class(param_name));
            end
            
            switch param_str
                case 'file_name'
                    params.file_name = args{i+1};
                case 'export_path'
                    params.export_path = args{i+1};
                case 'x'
                    params.x_label = args{i+1};
                case 'y'
                    params.y_label = args{i+1};
                case 'title'
                    params.title = args{i+1};
                case 'width'
                    params.width = args{i+1};
                case 'height'
                    params.height = args{i+1};
                case 'interactive'
                    params.interactive = args{i+1};
                case 'tooltip'
                    params.tooltip = args{i+1};
            end
        end
    end
    
end

function analysis = analyzeGrammObject(g)
    analysis = struct();
    
    % Extract aesthetic mappings
    analysis.aes = extractAesthetics(g);
    
    % Analyze g.results to detect all geom_* and stat_* handles
    analysis.geoms = detectGeomHandles(g.results);
    
    % Extract data and handle complex formats
    analysis.data = extractComplexData(g);
    
    % Detect grouping variables and color scales
    analysis.grouping = extractGroupingInfo(g);
    
    % Extract continuous color options for heatmaps/2D plots
    analysis.continuous_color = extractContinuousColorInfo(g);
end

function aes = extractAesthetics(g)
    aes = struct();
    aes.x = g.aes.x;
    aes.y = g.aes.y;
    
    % Extract additional aesthetics if present
    if isfield(g.aes, 'color')
        aes.color = g.aes.color;
    end
    if isfield(g.aes, 'size')
        aes.size = g.aes.size;
    end
    if isfield(g.aes, 'shape')
        aes.shape = g.aes.shape;
    end
end

function geoms = detectGeomHandles(results)
    geoms = struct();
    
    % Check for all possible geom handles - both _handle and direct field names
    geom_types = {'geom_point_handle', 'geom_line_handle', 'geom_bar_handle', ...
                  'geom_jitter_handle', 'geom_swarm_handle', 'geom_raster_handle', ...
                  'geom_interval_handle', 'geom_abline_handle', 'geom_vline_handle', ...
                  'geom_hline_handle', 'geom_polygon_handle'};
    
    % Also check for direct geom field names (without _handle suffix)
    geom_types_direct = {'geom_point', 'geom_line', 'geom_bar', ...
                        'geom_jitter', 'geom_swarm', 'geom_raster', ...
                        'geom_interval', 'geom_abline', 'geom_vline', ...
                        'geom_hline', 'geom_polygon'};
    
    % Check for _handle versions first
    for i = 1:length(geom_types)
        if isfield(results, geom_types{i})
            geoms.(geom_types{i}) = results.(geom_types{i});
        end
    end
    
    % Check for direct field names and convert to _handle format
    for i = 1:length(geom_types_direct)
        if isfield(results, geom_types_direct{i}) && ~isempty(results.(geom_types_direct{i}))
            handle_name = [geom_types_direct{i} '_handle'];
            geoms.(handle_name) = results.(geom_types_direct{i});
        end
    end
end


function data = extractComplexData(g)
    data = struct();
    data.x = g.aes.x;
    data.y = g.aes.y;
    
    % Handle complex data formats (2D arrays, cell arrays) - placeholder for now
    % This will be expanded in later phases
end

function grouping = extractGroupingInfo(g)
    grouping = struct();
    grouping.hasColorGroup = false;
    grouping.colorData = [];
    
    % Check for color grouping - more comprehensive detection
    if isfield(g.aes, 'color') && ~isempty(g.aes.color)
        % Check if color data has multiple unique values
        unique_colors = unique(g.aes.color);
        if length(unique_colors) > 1
            grouping.hasColorGroup = true;
            grouping.colorData = g.aes.color;
        else
            grouping.colorData = g.aes.color;
        end
    elseif isfield(g.results, 'color') && ~isempty(g.results.color) && length(g.results.color) > 1
        grouping.hasColorGroup = true;
        grouping.colorData = g.aes.color;
    else
        % No color grouping, use default color
        grouping.colorData = repmat('#ff4565', length(g.aes.x), 1);
    end
end

function continuous_color = extractContinuousColorInfo(g)
    continuous_color = struct();
    continuous_color.active = false;
    continuous_color.colormap = [];
    continuous_color.CLim = [];
    
    % Check if continuous color is active in gramm object
    if isfield(g, 'continuous_color_options') && ~isempty(g.continuous_color_options)
        if isfield(g.continuous_color_options, 'active') && g.continuous_color_options.active
            continuous_color.active = true;
            
            % Extract colormap if available
            if isfield(g.continuous_color_options, 'colormap') && ~isempty(g.continuous_color_options.colormap)
                continuous_color.colormap = g.continuous_color_options.colormap;
            end
            
            % Extract color limits if available
            if isfield(g.continuous_color_options, 'CLim') && ~isempty(g.continuous_color_options.CLim)
                continuous_color.CLim = g.continuous_color_options.CLim;
            end
        end
    end
end

function hex_colors = convertColormapToHex(colormap_matrix, num_colors)
    % Convert MATLAB colormap matrix to array of hex color strings
    % colormap_matrix: Nx3 matrix of RGB values (0-1)
    % num_colors: number of colors to sample from the colormap
    
    if isempty(colormap_matrix)
        % Default viridis-like gradient (blue-green-yellow) to match gramm default
        hex_colors = {'#440154', '#482777', '#3f4a8a', '#31678e', '#26838f', '#1f9d8a', '#6cce5a', '#b6de2b', '#fee825'};
        return;
    end
    
    % Sample colors evenly from the colormap
    colormap_size = size(colormap_matrix, 1);
    if num_colors > colormap_size
        num_colors = colormap_size;
    end
    
    indices = round(linspace(1, colormap_size, num_colors));
    sampled_colors = colormap_matrix(indices, :);
    
    % Convert RGB to hex
    hex_colors = cell(num_colors, 1);
    for i = 1:num_colors
        r = round(sampled_colors(i, 1) * 255);
        g = round(sampled_colors(i, 2) * 255);
        b = round(sampled_colors(i, 3) * 255);
        hex_colors{i} = sprintf('#%02x%02x%02x', r, g, b);
    end
end

%% ===== CHART TYPE DETECTION =====

function chart_spec = detectAllChartTypes(analysis, params)
    chart_spec = struct();
    chart_spec.layers = {};
    
    % Get geom field names and handle empty case
    if isempty(analysis.geoms) || ~isstruct(analysis.geoms)
        geom_fields = {};
    else
        geom_fields = fieldnames(analysis.geoms);
    end

    % Process each geom type
    for i = 1:length(geom_fields)
        geom_type = geom_fields{i};
        switch geom_type
            case 'geom_point_handle'
                chart_spec.layers{end+1} = createPointLayer(analysis, params);
            case 'geom_line_handle'
                chart_spec.layers{end+1} = createLineLayer(analysis, params);
            case 'geom_bar_handle'
                chart_spec.layers{end+1} = createBarLayer(analysis, params);
            case 'geom_jitter_handle'
                chart_spec.layers{end+1} = createJitterLayer(analysis, params);
            case 'geom_swarm_handle'
                chart_spec.layers{end+1} = createSwarmLayer(analysis, params);
            case 'geom_raster_handle'
                chart_spec.layers{end+1} = createRasterLayer(analysis, params);
            case 'geom_interval_handle'
                chart_spec.layers{end+1} = createIntervalLayer(analysis, params);
            case 'geom_abline_handle'
                chart_spec.layers{end+1} = createAblineLayer(analysis, params);
            case 'geom_vline_handle'
                chart_spec.layers{end+1} = createVlineLayer(analysis, params);
            case 'geom_hline_handle'
                chart_spec.layers{end+1} = createHlineLayer(analysis, params);
            case 'geom_polygon_handle'
                chart_spec.layers{end+1} = createPolygonLayer(analysis, params);
        end
    end

    
    % If no geom or stat detected, default to point
    if isempty(chart_spec.layers)
        chart_spec.layers{1} = createPointLayer(analysis, params);
        disp('No geom or stat type detected, defaulting to point chart');
    end
end

%% ===== GEOMETRIC OBJECT IMPLEMENTATIONS =====

function layer = createPointLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for points
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis, params);
    
    % Create marks
    marks = struct();
    marks.name = 'points';
    marks.type = 'symbol';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.size = struct('value', 60);
    marks.encode.enter.stroke = struct('value', 'white');
    marks.encode.enter.strokeWidth = struct('value', 1);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    % Add tooltip support
    marks = addTooltipToMark(marks, params, analysis);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createLineLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for lines
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis, params);
    
    % Create marks with proper grouping for multiple lines
    if analysis.grouping.hasColorGroup
        % For multi-color lines, use group with facet
        marks = struct();
        marks.name = 'lines';
        marks.type = 'group';
        marks.from = struct('facet', struct('name', 'series', 'data', 'table', 'groupby', 'color'));
        
        % Define the line mark within the group
        line_mark = struct();
        line_mark.type = 'line';
        line_mark.from = struct('data', 'series');
        line_mark.sort = struct('field', 'x'); % Sort by x-value within each color group
        line_mark.encode = struct();
        line_mark.encode.enter = struct();
        line_mark.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
        line_mark.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
        line_mark.encode.enter.strokeWidth = struct('value', 2);
        line_mark.encode.enter.stroke = struct('scale', 'color', 'field', 'color');
        
        % Add tooltip support to nested line mark
        line_mark = addTooltipToMark(line_mark, params, analysis);
        
        marks.marks = {line_mark};
    else
        % For single-color lines, use simple line mark directly
        marks = struct();
        marks.name = 'lines';
        marks.type = 'line';
        marks.from = struct('data', 'table');
        marks.encode = struct();
        marks.encode.enter = struct();
        marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
        marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
        marks.encode.enter.strokeWidth = struct('value', 2);
        marks.encode.enter.stroke = struct('value', '#ff4565');
        
        % Add tooltip support to simple line mark
        marks = addTooltipToMark(marks, params, analysis);
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createBarLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for bars following official grouped bar pattern
    layer.vegaSpec = createBaseVegaSpec();
    
    % Create scales following the official example pattern (adapted for vertical bars)
    layer.vegaSpec.scales = {};
    
    % X scale (categorical - for bar groups)
    xscale = struct();
    xscale.name = 'xscale';
    xscale.type = 'band';
    xscale.domain = struct('data', 'table', 'field', 'x', 'sort', true);
    xscale.range = 'width';
    xscale.padding = 0.2;
    layer.vegaSpec.scales{end+1} = xscale;
    
    % Y scale (quantitative - for bar heights)
    yscale = struct();
    yscale.name = 'yscale';
    yscale.type = 'linear';
    yscale.domain = struct('data', 'table', 'field', 'y');
    yscale.range = 'height';
    yscale.round = true;
    yscale.zero = true;
    yscale.nice = true;
    layer.vegaSpec.scales{end+1} = yscale;
    
    % Color scale if grouping exists
    if analysis.grouping.hasColorGroup
        colorscale = struct();
        colorscale.name = 'color';
        colorscale.type = 'ordinal';
        colorscale.domain = struct('data', 'table', 'field', 'color');
        colorscale.range = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
        layer.vegaSpec.scales{end+1} = colorscale;
    end
    
    % Add axes
    layer.vegaSpec.axes = {
        struct('orient', 'bottom', 'scale', 'xscale', 'tickSize', 0, 'labelPadding', 4, 'zindex', 1);
        struct('orient', 'left', 'scale', 'yscale')
    };
    
    if analysis.grouping.hasColorGroup
        % For grouped bars, use the official nested group structure
        marks = struct();
        marks.type = 'group';
        marks.from = struct('facet', struct('data', 'table', 'name', 'facet', 'groupby', 'x'));
        
        % Positioning for each group
        marks.encode = struct();
        marks.encode.enter = struct();
        marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
        
        % Add signal for width calculation
        marks.signals = {struct('name', 'width', 'update', 'bandwidth(''xscale'')')};
        
        % Add inner scale for positioning bars within each group
        pos_scale = struct();
        pos_scale.name = 'pos';
        pos_scale.type = 'band';
        pos_scale.range = 'width';
        pos_scale.domain = struct('data', 'facet', 'field', 'color');
        marks.scales = {pos_scale};
        
        % Create the individual bar mark within each group
        bar_mark = struct();
        bar_mark.name = 'bars';
        bar_mark.from = struct('data', 'facet');
        bar_mark.type = 'rect';
        bar_mark.encode = struct();
        bar_mark.encode.enter = struct();
        bar_mark.encode.enter.x = struct('scale', 'pos', 'field', 'color');
        bar_mark.encode.enter.width = struct('scale', 'pos', 'band', 1);
        bar_mark.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
        bar_mark.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
        bar_mark.encode.enter.fill = struct('scale', 'color', 'field', 'color');
        
        % Add tooltip support to nested bar mark
        bar_mark = addTooltipToMark(bar_mark, params, analysis);
        
        marks.marks = {bar_mark};
    else
        % Single bars can use simple rect mark
        marks = struct();
        marks.name = 'bars';
        marks.type = 'rect';
        marks.from = struct('data', 'table');
        
        marks.encode = struct();
        marks.encode.enter = struct();
        marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
        marks.encode.enter.width = struct('scale', 'xscale', 'band', 1);
        marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
        marks.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
        marks.encode.enter.fill = struct('value', '#ff4565');
        
        % Add tooltip support to simple bar mark
        marks = addTooltipToMark(marks, params, analysis);
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createJitterLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for jittered points
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis, params);
    
    % Create marks with jitter transform
    marks = struct();
    marks.name = 'jitteredPoints';
    marks.type = 'symbol';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.update = struct();
    marks.encode.update.x = struct('signal', 'scale(''xscale'', datum.x) + bandwidth(''xscale'')/2 + (random() - 0.5) * bandwidth(''xscale'') * 0.8');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.size = struct('value', 60);
    marks.encode.enter.stroke = struct('value', 'white');
    marks.encode.enter.strokeWidth = struct('value', 1);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    % Add tooltip support
    marks = addTooltipToMark(marks, params, analysis);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createSwarmLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for beeswarm plot using jitter-based approach
    % This preserves Y-value accuracy while creating swarm visual effect
    layer.vegaSpec = createBaseVegaSpec();
    
    % Create scales - force band scale for swarm plots
    scales = {};
    
    % X scale - always use band scale for swarm plots to create discrete groups
    xscale = struct();
    xscale.name = 'xscale';
    xscale.type = 'band';
    xscale.domain = struct('data', 'table', 'field', 'x', 'sort', true);
    xscale.range = 'width';
    scales{end+1} = xscale;
    
    % Y scale - preserves exact Y values from data
    yscale = struct();
    yscale.name = 'yscale';
    yscale.type = 'linear';
    yscale.domain = struct('data', 'table', 'field', 'y');
    yscale.range = 'height';
    yscale.nice = true;
    yscale.zero = true;
    scales{end+1} = yscale;
    
    % Color scale if grouping exists
    if analysis.grouping.hasColorGroup
        colorscale = struct();
        colorscale.name = 'color';
        colorscale.type = 'ordinal';
        colorscale.domain = struct('data', 'table', 'field', 'color');
        colorscale.range = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
        scales{end+1} = colorscale;
    end
    
    layer.vegaSpec.scales = scales;
    
    % Add axes - both X and Y for proper scaling
    layer.vegaSpec.axes = {
        struct('orient', 'bottom', 'scale', 'xscale', 'labelAngle', 0, 'labelFontSize', 12);
        struct('orient', 'left', 'scale', 'yscale')
    };
    
    % Create swarm marks using jitter-based approach that preserves Y values
    marks = struct();
    marks.name = 'swarmPoints';
    marks.type = 'symbol';
    marks.from = struct('data', 'table');
    
    % Encode properties
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.stroke = struct('value', 'white');
    marks.encode.enter.strokeWidth = struct('value', 1);
    marks.encode.enter.size = struct('value', 80);
    
    % CRITICAL: Preserve exact Y values from data - no transformation applied
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    
    % Set color based on grouping
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    % X positioning with simple jitter calculation (same as jitter implementation)
    marks.encode.update = struct();
    marks.encode.update.x = struct('signal', 'scale(''xscale'', datum.x) + bandwidth(''xscale'')/2 + (random() - 0.5) * bandwidth(''xscale'') * 0.8');
    
    % Add tooltip support
    marks = addTooltipToMark(marks, params, analysis);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createRasterLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for raster/tick plots
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales (only x-scale needed for raster)
    scales = createVegaScales(analysis);
    layer.vegaSpec.scales = scales(1); % Only keep x-scale
    
    % Add axes (only x-axis)
    layer.vegaSpec.axes = {struct('orient', 'bottom', 'scale', 'xscale')};
    
    % Create marks
    marks = struct();
    marks.name = 'ticks';
    marks.type = 'rect';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.width = struct('value', 2);
    marks.encode.enter.y = struct('value', 0);
    marks.encode.enter.height = struct('signal', 'height');
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createIntervalLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for error bars/intervals
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis, params);
    
    % Create marks for error bars
    marks = struct();
    marks.name = 'errorbars';
    marks.type = 'rule';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'ymin');
    marks.encode.enter.y2 = struct('scale', 'yscale', 'field', 'ymax');
    marks.encode.enter.strokeWidth = struct('value', 2);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.stroke = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.stroke = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createAblineLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for diagonal reference lines
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis, params);
    
    % Create marks for diagonal line
    marks = struct();
    marks.name = 'abline';
    marks.type = 'line';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.stroke = struct('value', '#808080');
    marks.encode.enter.strokeWidth = struct('value', 2);
    marks.encode.enter.strokeDash = struct('value', [5, 5]);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createVlineLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for vertical reference lines
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis, params);
    
    % Create marks for vertical lines
    marks = struct();
    marks.name = 'vlines';
    marks.type = 'rule';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('value', 0);
    marks.encode.enter.y2 = struct('signal', 'height');
    marks.encode.enter.stroke = struct('value', '#808080');
    marks.encode.enter.strokeWidth = struct('value', 1);
    marks.encode.enter.strokeDash = struct('value', [3, 3]);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createHlineLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for horizontal reference lines
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis, params);
    
    % Create marks for horizontal lines
    marks = struct();
    marks.name = 'hlines';
    marks.type = 'rule';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('value', 0);
    marks.encode.enter.x2 = struct('signal', 'width');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.stroke = struct('value', '#808080');
    marks.encode.enter.strokeWidth = struct('value', 1);
    marks.encode.enter.strokeDash = struct('value', [3, 3]);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createPolygonLayer(analysis, params)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for polygon/area plots
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis, params);
    
    % Create marks for polygon
    marks = struct();
    marks.name = 'polygons';
    marks.type = 'area';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
    marks.encode.enter.fill = struct('value', '#cccccc');
    marks.encode.enter.fillOpacity = struct('value', 0.3);
    
    layer.vegaSpec.marks = {marks};
end


function baseSpec = createBaseVegaSpec()
    baseSpec = struct();
    baseSpec.schema = 'https://vega.github.io/schema/vega/v6.json';
    baseSpec.width = 600;
    baseSpec.height = 400;
    baseSpec.padding = struct('left', 60, 'right', 20, 'top', 20, 'bottom', 60);
    baseSpec.autosize = 'none';
    baseSpec.data = {struct('name', 'table')};
end

function scales = createVegaScales(analysis, forceBandScale, dataSource)
    if nargin < 2
        forceBandScale = false;
    end
    if nargin < 3
        dataSource = 'table';  % Default to 'table' for backward compatibility
    end
    
    scales = {};
    
    % X scale
    xscale = struct();
    xscale.name = 'xscale';
    if forceBandScale || ~isnumeric(analysis.data.x)
        xscale.type = 'band';
        xscale.domain = struct('data', dataSource, 'field', 'x', 'sort', true);
        xscale.padding = 0.1;
    else
        xscale.type = 'linear';
        xscale.domain = struct('data', dataSource, 'field', 'x');
    end
    xscale.range = 'width';
    scales{end+1} = xscale;
    
    % Y scale
    yscale = struct();
    yscale.name = 'yscale';
    if isnumeric(analysis.data.y)
        yscale.type = 'linear';
        yscale.domain = struct('data', dataSource, 'field', 'y');
    else
        yscale.type = 'band';
        yscale.domain = struct('data', dataSource, 'field', 'y', 'sort', true);
        yscale.padding = 0.1;
    end
    yscale.range = 'height';
    yscale.nice = true;
    yscale.zero = true;
    scales{end+1} = yscale;
    
    % Color scale if grouping exists
    if analysis.grouping.hasColorGroup
        colorscale = struct();
        colorscale.name = 'color';
        colorscale.type = 'ordinal';
        colorscale.domain = struct('data', dataSource, 'field', 'color');
        colorscale.range = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
        scales{end+1} = colorscale;
    end
end

function axes = createVegaAxes(analysis, params)
    axes = {};
    
    % X axis
    xaxis = struct();
    xaxis.orient = 'bottom';
    xaxis.scale = 'xscale';
    xaxis.title = params.x_label;
    axes{end+1} = xaxis;
    
    % Y axis
    yaxis = struct();
    yaxis.orient = 'left';
    yaxis.scale = 'yscale';
    yaxis.title = params.y_label;
    axes{end+1} = yaxis;
end

%% ===== ENCODING HELPERS =====

function mark = addTooltipToMark(mark, params, analysis)
    % Add tooltip encoding to a mark if tooltips are enabled
    if ~strcmpi(params.tooltip, 'true')
        return; % Skip if tooltips are disabled
    end
    
    % Ensure mark has update encoding section
    if ~isfield(mark, 'encode')
        mark.encode = struct();
    end
    if ~isfield(mark.encode, 'update')
        mark.encode.update = struct();
    end
    
    % Build tooltip signal expression following tooltip.json pattern
    if analysis.grouping.hasColorGroup
        tooltip_signal = sprintf('''%s: '' + (isNumber(datum.x) ? format(datum.x, ''.3f'') : datum.x) + '', %s: '' + (isNumber(datum.y) ? format(datum.y, ''.3f'') : datum.y) + '', Color: '' + datum.color', ...
                                params.x_label, params.y_label);
    else
        tooltip_signal = sprintf('''%s: '' + (isNumber(datum.x) ? format(datum.x, ''.3f'') : datum.x) + '', %s: '' + (isNumber(datum.y) ? format(datum.y, ''.3f'') : datum.y)', ...
                                params.x_label, params.y_label);
    end
    
    % Add tooltip to update encoding
    mark.encode.update.tooltip = struct('signal', tooltip_signal);
end

function encoding = createBasicEncoding(analysis)
    encoding = struct();
    
    % X encoding
    encoding.x = struct();
    encoding.x.field = 'x';
    if isnumeric(analysis.data.x)
        encoding.x.type = 'quantitative';
    else
        encoding.x.type = 'nominal';
    end
    
    % Y encoding
    encoding.y = struct();
    encoding.y.field = 'y';
    if isnumeric(analysis.data.y)
        encoding.y.type = 'quantitative';
    else
        encoding.y.type = 'nominal';
    end
end

function color_encoding = createColorEncoding(grouping)
    color_encoding = struct();
    color_encoding.field = 'color';
    color_encoding.type = 'nominal';
    
    % Create color scale based on actual data
    color_encoding.scale = struct();
    
    % Get unique color values and convert to strings
    if isnumeric(grouping.colorData)
        unique_colors = unique(grouping.colorData);
        color_encoding.scale.domain = arrayfun(@num2str, unique_colors, 'UniformOutput', false);
    else
        unique_colors = unique(grouping.colorData);
        color_encoding.scale.domain = cellstr(unique_colors);
    end
    
    % Default color palette - extend if needed
    default_colors = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
    num_colors = length(color_encoding.scale.domain);
    color_encoding.scale.range = default_colors(1:min(num_colors, length(default_colors)));
end

%% ===== DATA PROCESSING =====

function vega_data = extractVegaData(analysis)
    x = analysis.data.x;
    y = analysis.data.y;
    colorData = analysis.grouping.colorData;
    hasColorGroup = analysis.grouping.hasColorGroup;
    
    % Handle different data types and clean data
    [x, y, colorData] = cleanAndProcessData(x, y, colorData, hasColorGroup);
    
    % Convert to Vega data format
    vega_data = [];
    for i = 1:length(x)
        dataPoint = struct();
        
        % Handle x values
        if isnumeric(x(i))
            dataPoint.x = x(i);
        else
            dataPoint.x = char(x(i));
        end
        
        % Handle y values
        if isnumeric(y(i))
            dataPoint.y = y(i);
        else
            dataPoint.y = char(y(i));
        end
        
        % Handle color grouping
        if hasColorGroup
            if isnumeric(colorData(i))
                dataPoint.color = num2str(colorData(i));
            else
                dataPoint.color = char(colorData(i));
            end
        end
        
        vega_data = [vega_data; dataPoint];
    end
end

function [x_clean, y_clean, color_clean] = cleanAndProcessData(x, y, colorData, hasColorGroup)
    % Handle different data types
    
    % Convert cell arrays to numeric if they contain numeric data
    if iscell(x) && all(cellfun(@isnumeric, x))
        x = cell2mat(x);
    end
    if iscell(y) && all(cellfun(@isnumeric, y))
        y = cell2mat(y);
    end
    
    if isnumeric(x) && isnumeric(y)
        % Remove NaN and infinite values for numeric data
        validIndices = ~isnan(x) & ~isnan(y) & isfinite(x) & isfinite(y);
        
        % Check if any data was filtered out and warn user
        originalCount = length(x);
        filteredCount = sum(validIndices);
        if filteredCount < originalCount
            warning('gramm:VegaExport:InvalidData', ...
                'Removed %d data points containing NaN or infinite values (%d remaining)', ...
                originalCount - filteredCount, filteredCount);
        end
        
        x_clean = x(validIndices);
        y_clean = y(validIndices);
        if hasColorGroup
            color_clean = colorData(validIndices);
        else
            color_clean = colorData;
        end
    else
        % Convert non-numeric data to strings
        if ~isnumeric(x)
            x = string(x);
        end
        if ~isnumeric(y)
            y = string(y);
        end
        
        % Remove missing values
        validIndices = ~ismissing(x) & ~ismissing(y);
        x_clean = x(validIndices);
        y_clean = y(validIndices);
        if hasColorGroup
            color_clean = colorData(validIndices);
        else
            color_clean = colorData;
        end
    end
end

%% ===== VEGA SPECIFICATION GENERATION =====

function vega_spec = generateVegaSpecification(chart_spec, vega_data, params)
    % All chart layers now use Vega format
    if isempty(chart_spec.layers)
        error('No chart layers found');
    end
    
    % Use the first layer's Vega specification as base
    vega_spec = chart_spec.layers{1}.vegaSpec;
    
    % Update dimensions from params
    vega_spec.width = str2double(params.width);
    vega_spec.height = str2double(params.height);
    
    % Set up main data table with raw data points
    % First ensure we have a "table" data source for the main data
    table_data_index = -1;
    for i = 1:length(vega_spec.data)
        if strcmp(vega_spec.data{i}.name, 'table')
            table_data_index = i;
            break;
        end
    end
    
    if table_data_index == -1
        % No table data source exists, add it at the beginning
        table_data_source = struct('name', 'table', 'values', vega_data);
        vega_spec.data = [{table_data_source}, vega_spec.data];
    else
        % Table data source exists, update its values
        vega_spec.data{table_data_index}.values = vega_data;
    end
    
    % Add title if specified
    if ~strcmp(params.title, 'Untitled')
        vega_spec.title = params.title;
    end
    
    % Update axis titles
    for i = 1:length(vega_spec.axes)
        if strcmp(vega_spec.axes{i}.orient, 'bottom')
            vega_spec.axes{i}.title = params.x_label;
        elseif strcmp(vega_spec.axes{i}.orient, 'left')
            vega_spec.axes{i}.title = params.y_label;
        end
    end
    
    % Handle multi-layer visualizations by combining marks, scales, and data sources
    if length(chart_spec.layers) > 1
        combined_marks = {};
        combined_scales = {};
        combined_data = {vega_spec.data{1}};  % Start with main table data
        
        for i = 1:length(chart_spec.layers)
            layer_spec = chart_spec.layers{i}.vegaSpec;
            
            % Combine marks from all layers
            if isfield(layer_spec, 'marks')
                for j = 1:length(layer_spec.marks)
                    combined_marks{end+1} = layer_spec.marks{j};
                end
            end
            
            % Combine scales (avoiding duplicates)
            if isfield(layer_spec, 'scales')
                for j = 1:length(layer_spec.scales)
                    scale_name = layer_spec.scales{j}.name;
                    exists = false;
                    for k = 1:length(combined_scales)
                        if strcmp(combined_scales{k}.name, scale_name)
                            exists = true;
                            break;
                        end
                    end
                    if ~exists
                        combined_scales{end+1} = layer_spec.scales{j};
                    end
                end
            end
            
            % Combine data sources (avoiding duplicates and main table)
            if isfield(layer_spec, 'data')
                for j = 1:length(layer_spec.data)
                    data_name = layer_spec.data{j}.name;
                    % Skip main table data (already added)
                    if strcmp(data_name, 'table')
                        continue;
                    end
                    
                    % Check if this data source already exists
                    exists = false;
                    for k = 1:length(combined_data)
                        if strcmp(combined_data{k}.name, data_name)
                            exists = true;
                            break;
                        end
                    end
                    if ~exists
                        combined_data{end+1} = layer_spec.data{j};
                    end
                end
            end
        end
        
        vega_spec.marks = combined_marks;
        vega_spec.scales = combined_scales;
        vega_spec.data = combined_data;
    end
    
    % Add legend if color scale exists (multiple colors in data)
    vega_spec = addLegendIfNeeded(vega_spec, vega_data, params);
    
    % Store flag to indicate this is a Vega chart
    vega_spec.isVegaChart = true;
end


function vega_spec = addLegendIfNeeded(vega_spec, vega_data, params)
    % Check if there are multiple colors in the data
    hasMultipleColors = false;
    hasColorScale = false;
    
    % Check if there's a color scale defined
    if isfield(vega_spec, 'scales')
        for i = 1:length(vega_spec.scales)
            if strcmp(vega_spec.scales{i}.name, 'color')
                hasColorScale = true;
                break;
            end
        end
    end
    
    % Check if there are multiple unique color values in the data
    if ~isempty(vega_data) && isstruct(vega_data)
        if length(vega_data) > 1 && isfield(vega_data, 'color')
            % Extract all color values from struct array
            color_values = {vega_data.color};
            % Remove empty values
            color_values = color_values(~cellfun(@isempty, color_values));
            unique_colors = unique(color_values);
            hasMultipleColors = length(unique_colors) > 1;
        elseif isfield(vega_data, 'color') && iscell(vega_data.color)
            % Handle case where color is a cell array
            unique_colors = unique(vega_data.color);
            hasMultipleColors = length(unique_colors) > 1;
        end
    end
    
    % Add legend if we have both a color scale and multiple colors
    if hasColorScale && hasMultipleColors
        % Check if interactive legend is requested
        isInteractive = strcmpi(params.interactive, 'true');
        
        if isInteractive
            % Add interactive legend with signals and data
            vega_spec = addInteractiveLegend(vega_spec);
        else
            % Create standard legend specification
            legend = struct();
            legend.fill = 'color';
            legend.orient = 'right';
            legend.padding = 10;
            legend.cornerRadius = 5;
            legend.strokeColor = '#ddd';
            legend.fillColor = '#fff';
            legend.title = 'Color';
            legend.titlePadding = 5;
            legend.titleFontSize = 12;
            legend.titleFontWeight = 'bold';
            legend.labelFontSize = 11;
            legend.symbolSize = 100;
            legend.symbolType = 'circle';
            
            % Add legend to specification
            vega_spec.legends = {legend};
        end
        
        % Adjust padding to accommodate legend
        if isfield(vega_spec, 'padding')
            vega_spec.padding.right = 120; % Increase right padding for legend
        else
            vega_spec.padding = struct('left', 60, 'right', 120, 'top', 20, 'bottom', 60);
        end
    end
end

function vega_spec = addInteractiveLegend(vega_spec)
    % Add interactive legend functionality based on official Vega pattern
    
    % Add signals for interactive legend
    if ~isfield(vega_spec, 'signals')
        vega_spec.signals = {};
    end
    
    % Clear signal - resets selection when clicking empty space
    clear_signal = struct();
    clear_signal.name = 'clear';
    clear_signal.value = true;
    clear_signal.on = {struct('events', 'pointerup[!event.item]', 'update', 'true', 'force', true)};
    vega_spec.signals{end+1} = clear_signal;
    
    % Shift signal - detects if shift key is held during click
    shift_signal = struct();
    shift_signal.name = 'shift';
    shift_signal.value = false;
    shift_signal.on = {struct('events', '@legendSymbol:click, @legendLabel:click', 'update', 'event.shiftKey', 'force', true)};
    vega_spec.signals{end+1} = shift_signal;
    
    % Clicked signal - captures clicked legend item
    clicked_signal = struct();
    clicked_signal.name = 'clicked';
    clicked_signal.value = [];
    clicked_signal.on = {struct('events', '@legendSymbol:click, @legendLabel:click', 'update', '{value: datum.value}', 'force', true)};
    vega_spec.signals{end+1} = clicked_signal;
    
    % Add selected data for tracking clicked items
    if ~isfield(vega_spec, 'data')
        vega_spec.data = {};
    end
    
    selected_data = struct();
    selected_data.name = 'selected';
    selected_data.on = {
        struct('trigger', 'clear', 'remove', true);
        struct('trigger', '!shift', 'remove', true);
        struct('trigger', '!shift && clicked', 'insert', 'clicked');
        struct('trigger', 'shift && clicked', 'toggle', 'clicked')
    };
    vega_spec.data{end+1} = selected_data;
    
    % Create interactive legend
    legend = struct();
    legend.fill = 'color';
    legend.title = 'Color';
    legend.orient = 'right';
    legend.padding = 10;
    
    % Interactive legend encoding
    legend.encode = struct();
    
    % Interactive symbols
    legend.encode.symbols = struct();
    legend.encode.symbols.name = 'legendSymbol';
    legend.encode.symbols.interactive = true;
    legend.encode.symbols.update = struct();
    legend.encode.symbols.update.fill = struct('value', 'transparent');
    legend.encode.symbols.update.strokeWidth = struct('value', 2);
    legend.encode.symbols.update.opacity = {
        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.value)', 'value', 0.7);
        struct('value', 0.15)
    };
    legend.encode.symbols.update.size = struct('value', 64);
    
    % Interactive labels
    legend.encode.labels = struct();
    legend.encode.labels.name = 'legendLabel';
    legend.encode.labels.interactive = true;
    legend.encode.labels.update = struct();
    legend.encode.labels.update.opacity = {
        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.value)', 'value', 1);
        struct('value', 0.25)
    };
    
    vega_spec.legends = {legend};
    
    % Update marks to be interactive - modify existing marks
    if isfield(vega_spec, 'marks')
        for i = 1:length(vega_spec.marks)
            mark = vega_spec.marks{i};
            
            % Add interactivity to marks that use color encoding
            if isfield(mark, 'encode') && isfield(mark.encode, 'enter')
                if isfield(mark.encode.enter, 'fill') && isfield(mark.encode.enter.fill, 'scale') && strcmp(mark.encode.enter.fill.scale, 'color')
                    % Update fill encoding for interactivity
                    if ~isfield(mark.encode, 'update')
                        mark.encode.update = struct();
                    end
                    
                    mark.encode.update.opacity = {
                        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'value', 0.7);
                        struct('value', 0.15)
                    };
                    
                    mark.encode.update.fill = {
                        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'scale', 'color', 'field', 'color');
                        struct('value', '#ccc')
                    };
                    
                elseif isfield(mark.encode.enter, 'stroke') && isfield(mark.encode.enter.stroke, 'scale') && strcmp(mark.encode.enter.stroke.scale, 'color')
                    % Update stroke encoding for interactivity
                    if ~isfield(mark.encode, 'update')
                        mark.encode.update = struct();
                    end
                    
                    mark.encode.update.opacity = {
                        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'value', 0.7);
                        struct('value', 0.15)
                    };
                    
                    mark.encode.update.stroke = {
                        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'scale', 'color', 'field', 'color');
                        struct('value', '#ccc')
                    };
                end
            end
            
            % Handle nested marks (for grouped charts like bars and lines)
            if isfield(mark, 'marks')
                for j = 1:length(mark.marks)
                    nested_mark = mark.marks{j};
                    if isfield(nested_mark, 'encode') && isfield(nested_mark.encode, 'enter')
                        if ~isfield(nested_mark.encode, 'update')
                            nested_mark.encode.update = struct();
                        end
                        
                        % Handle fill encoding (for bars)
                        if isfield(nested_mark.encode.enter, 'fill') && isfield(nested_mark.encode.enter.fill, 'scale') && strcmp(nested_mark.encode.enter.fill.scale, 'color')
                            nested_mark.encode.update.opacity = {
                                struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'value', 0.7);
                                struct('value', 0.15)
                            };
                            
                            nested_mark.encode.update.fill = {
                                struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'scale', 'color', 'field', 'color');
                                struct('value', '#ccc')
                            };
                        end
                        
                        % Handle stroke encoding (for lines)
                        if isfield(nested_mark.encode.enter, 'stroke') && isfield(nested_mark.encode.enter.stroke, 'scale') && strcmp(nested_mark.encode.enter.stroke.scale, 'color')
                            nested_mark.encode.update.opacity = {
                                struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'value', 0.7);
                                struct('value', 0.15)
                            };
                            
                            nested_mark.encode.update.stroke = {
                                struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'scale', 'color', 'field', 'color');
                                struct('value', '#ccc')
                            };
                        end
                        
                        mark.marks{j} = nested_mark;
                    end
                end
            end
            
            vega_spec.marks{i} = mark;
        end
    end
end

%% ===== FILE OUTPUT =====

function writeVegaFiles(vega_spec, params)
    % Create export directory if it doesn't exist
    if ~isempty(params.export_path) && ~exist(params.export_path, 'dir')
        mkdir(params.export_path);
    end
    
    % Remove the flag before writing JSON (all specs are now Vega)
    if isfield(vega_spec, 'isVegaChart')
        vega_spec = rmfield(vega_spec, 'isVegaChart');
    end
    
    % Convert specification to JSON
    vegaSpecJson = jsonencode(vega_spec);
    
    % Write JSON file
    jsonFile = fullfile(params.export_path, sprintf('%s.json', params.file_name));
    fileID = fopen(jsonFile, 'w+');
    fprintf(fileID, '%s', vegaSpecJson);
    fclose(fileID);
    
    % Write HTML file (always use Vega template now)
    htmlFile = fullfile(params.export_path, sprintf('%s.html', params.file_name));
    htmlContent = createVegaHTMLTemplate(params.file_name);
    
    fileID = fopen(htmlFile, 'w+');
    fprintf(fileID, '%s', htmlContent);
    fclose(fileID);
    
    fprintf('Vega specification successfully written to %s\n', jsonFile);
    fprintf('HTML file successfully written to %s\n', htmlFile);
end

function htmlContent = createVegaHTMLTemplate(file_name)
    % Vega HTML template for all chart types
    htmlContent = sprintf([ ...
        '<!DOCTYPE html>\n', ...
        '<html lang="en">\n', ...
        '<head>\n', ...
        '    <meta charset="UTF-8">\n', ...
        '    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n', ...
        '    <title>Vega Chart</title>\n', ...
        '    <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>\n', ...
        '    <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>\n', ...
        '</head>\n', ...
        '<body>\n', ...
        '    <div id="%s_chart"></div>\n', ...
        '    <script>\n', ...
        '        fetch("%s.json")\n', ...
        '            .then(response => response.json())\n', ...
        '            .then(spec => {\n', ...
        '                console.log("DEBUG: Loaded Vega spec:", spec);\n', ...
        '                console.log("DEBUG: Axes found:", spec.axes);\n', ...
        '                if (spec.axes) {\n', ...
        '                    spec.axes.forEach((axis, i) => {\n', ...
        '                        console.log(`DEBUG: Axis ${i} - Orient: ${axis.orient}, Title: "${axis.title}"`);\n', ...
        '                    });\n', ...
        '                }\n', ...
        '                if (spec.marks) {\n', ...
        '                    spec.marks.forEach((mark, i) => {\n', ...
        '                        if (mark.encode && mark.encode.update && mark.encode.update.tooltip) {\n', ...
        '                            console.log(`DEBUG: Mark ${i} tooltip signal: ${mark.encode.update.tooltip.signal}`);\n', ...
        '                        }\n', ...
        '                    });\n', ...
        '                }\n', ...
        '                vegaEmbed("#%s_chart", spec, {\n', ...
        '                    actions: true,\n', ...
        '                    theme: "default",\n', ...
        '                    renderer: "canvas"\n', ...
        '                });\n', ...
        '            })\n', ...
        '            .catch(error => console.error("Error loading chart:", error));\n', ...
        '    </script>\n', ...
        '</body>\n', ...
        '</html>\n' ...
    ], file_name, file_name, file_name);
end
