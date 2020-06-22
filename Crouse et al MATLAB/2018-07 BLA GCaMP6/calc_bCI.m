clear; 
load(getPipelineVarsFilename);

alpha = 1; % Error rate
resamples = 1000; % Number of times to bootstrap
sig = alpha / 100; % percentile alpha given to boot_CI
fs = 122.15; % Close estimation to a sampling frequency that would correspond to 1832 data points for 15 seconds
activity_threshold = 0.7 * fs; % 2018-07 uses a slightly higher activity threshold due to flatter device kinetics (signal gets 'leakily integrated' over time)

% Removed this from release versions, though it can be trivially re-added
% high_salience_timeframe = 0.25;
% high_salience_area_percent = 0.40;

trace_samples = 1832; % Number of timepoints in a 15 second window of the trace
climits = [-2 6]; % Y axis bounds for output graphs

event_dir_path = FP_INDIVIDUAL_DAY_DATA_FILENAME;
output_parent_dir = FP_BCI_PARENT_FOLDER;

MDIR_DIRECTORY_NAME = output_parent_dir;
make_directory;

load(event_dir_path);
event_dir = datanames; % Filenames loaded from the day graph data
% event_variable = 3; 
variable_names = { 'correct' 'tone' 'incorrect' 'receptacle' 'randrec' 'tonehit' 'tonemiss' 'inactive' };
variable_list = [ 1, 3, 4, 5, 6];

for current_var=1:length(variable_list)
    event_variable = variable_list(current_var);
    output_dir_path = join([ output_parent_dir '\' variable_names(variable_list(current_var)) ], '');
    % unwrap output_dir_path if necessary
    if isa(output_dir_path, 'cell')
        output_dir_path = output_dir_path{1};
    end
    
    MDIR_DIRECTORY_NAME = output_dir_path;
    make_directory; 
    
    for fidx=1:length(event_dir)
        fname = event_dir{fidx};
        if isa(fname, 'cell')
            fname = fname{1};
        end
        
        if length(fname) > 6 && strcmp(fname(1:6), 'MATLAB') && ~isempty(graphdata{fidx, event_variable})
            event_sig = graphdata{fidx, event_variable};
            event_null = zeros(size(event_sig, 1), size(event_sig, 2)); % This step isn't necessary for a 'true' null signal (i.e. dF/F = 0), but this may change for different definitions of null in the future    
            event_data_CI = boot_diffCI(transpose(event_sig), transpose(event_null), resamples, sig);
            
            % Narrowness factor correction (remove if unwanted)
            if ~isnan(event_data_CI)
                narrowness_fac = sqrt(size(event_sig, 2) / (size(event_sig, 2) - 1));
                event_data_CI(2, :) = event_data_CI(2,:) + abs((narrowness_fac - 1) * event_data_CI(2, :));
                event_data_CI(1, :) = event_data_CI(1,:) - abs((narrowness_fac - 1) * event_data_CI(1, :));
            end
            
            % Split off 'MATLAB' and the file extension
            save_fname_handle  = split(fname, '.');
            save_fname_handle = split(save_fname_handle{1}, '_');
            save_fname_handle = join(save_fname_handle(2:end));
            
            save_fname = join([ output_dir_path '\' save_fname_handle{1} ' bCI ' variable_names{event_variable} '.xlsx' ], '');
            writematrix(transpose(event_data_CI), save_fname);
            
            
            % Find consecutive indices of activation for the mean
            mean_event_sig = graphmean{fidx, event_variable};
            active_idx = find( event_data_CI(1, :) > 0);
            
            % TODO: Think connected_logical is reduntant with how I rewrote
            % consec_idx? Could probably just remove it from the method
            % signature but I'll leave it for now
            [ ~ , activity_regions ] = consec_idx(active_idx, 1);
            
            
            % Now filter activity regions by regions with at least 0.5 seconds
            % of continuous activation
            filtered_activity_regions = {};
            for r_idx = 1:length(activity_regions)
                if length(activity_regions{r_idx}) > activity_threshold
                    filtered_activity_regions{end + 1} = active_idx(activity_regions{r_idx});
                end
            end
            
            
            timescale = linspace(-5, 10, size(event_sig, 1));
            p = plot(timescale, mean_event_sig);
            ylim(climits);
            xlim([-5 5]); % Limit display to only eleven seconds
            
            yl = climits;
            y1 = yl(1); y2 = yl(2);
            for ridx = 1:length(filtered_activity_regions)
                region = filtered_activity_regions{ridx};
                x1 = timescale(region(1));
                x2 = timescale(region(end));
                vertices = [ x1 y1; x1 y2; x2 y2; x2 y1; ];
                faces = [ 1 2 3 4];
                patch('Vertices', vertices, 'Faces', faces, 'FaceColor', 'green', 'FaceAlpha', 0.3);
            end
            
            title([ 'bCI activation periods for ' save_fname_handle{1} ]);
            xlabel('Time (s)');
            ylabel('Z-Scored dF/F');
            % Save consecutive thresholded plot
            save_fname = join([ output_dir_path '\' save_fname_handle{1} ' plot CT ' variable_names{event_variable} ], '');
            print(save_fname, '-dpng');
        end
    end
end