clear;
load(getPipelineVarsFilename);

alpha = 1; % Error rate
resamples = 1000; % Number of times to bootstrap
sig = alpha / 100; % percentile alpha given to boot_CI
fs = 122.15; % Close estimation to a sampling frequency that would correspond to 1832 data points for 15 seconds
activity_threshold = 0.3 * fs;


trace_samples = 1832; % Number of timepoints in a 15 second window of the trace
climits = [-2 6]; % Y axis bounds for output graphs

event_dir_path = FP_INDIVIDUAL_DAY_DATA_FILENAME;
output_dir_path = FP_BCI_PARENT_FOLDER;

load(event_dir_path);
MDIR_DIRECTORY_NAME = output_dir_path;
make_directory;

filenames = datanames;

% Trim the first eight entries out of graphmean (they're cued days for days
% we don't use here) 
graphmean = graphmean(9:end, :);

% day at which each mouse hit the reward threshold
rew_threshold_day_names = ["856 Timeout Day 09"; "860 Timeout Day 09"];
ext_day_names =["856 ZExtinction Day 02"; "860 ZExtinction Day 01"];
cued_1_day_names = [ "856 Cued Day 01"; "860 Cued Day 01" ];
cued_4_day_names = [ "856 Cued Day 04"; "860 Cued Day 04" ];
timeout_3_day_names = [ "856 Timeout Day 03"; "860 Timeout Day 03" ];
timeout_last_day_names = [ "856 Timeout Day 07"; "860 Timeout Day 07" ];

rew_threshold = getDays(filenames, rew_threshold_day_names);
ext_day = getDays(filenames, ext_day_names);
cued_1 = getDays(filenames, cued_1_day_names);
cued_4 = getDays(filenames, cued_4_day_names);
timeout_3 = getDays(filenames, timeout_3_day_names);
timeout_last = getDays(filenames, timeout_last_day_names); 

days_array = [ cued_1; cued_4; timeout_3; rew_threshold; timeout_final; ext_day];
day_names = { 'Cued Day 01'; 'Cued Day 04'; 'Timeout Day 03'; 'Reward Threshold'; 'Final Timeout'; 'Extinction' };

load(event_dir_path);
event_dir = datanames; % Filenames loaded from the day graph data
event_variables = [ 1, 2, 3, 4, 6]; 
variable_names = { 'correct' 'tone' 'incorrect' 'receptacle' 'randrec' 'tonehit' 'tonemiss' 'inactive' };

for vidx=1:length(event_variables)
    event_variable = event_variables(vidx);
    var_directory = join([ output_dir_path '\' variable_names{event_variables} ], '');
    
    MDIR_DIRECTORY_NAME = var_directory; 
    make_directory;
    for fidx=1:size(days_array, 1)

        event_sig = [];
        for didx = 1:size(days_array, 2)
            event_sig = cat(2, event_sig, graphmean{days_array(fidx, didx), event_variable});
        end

        event_null = zeros(size(event_sig, 1), size(event_sig, 2)); % This step isn't necessary for a 'true' null signal (i.e. dF/F = 0), but this may change for different definitions of null in the future

        event_data_CI = boot_diffCI(transpose(event_sig), transpose(event_null), resamples, sig);

        % Narrowness factor correction (remove if unwanted)
        if ~isnan(event_data_CI)
            narrowness_fac = sqrt(size(event_sig, 2) / (size(event_sig, 2) - 1));
            event_data_CI(2, :) = event_data_CI(2,:) + abs((narrowness_fac - 1) * event_data_CI(2, :));
            event_data_CI(1, :) = event_data_CI(1,:) - abs((narrowness_fac - 1) * event_data_CI(1, :));
        end


        save_fname = join([ var_directory '\' day_names{fidx} ' bCI ' variable_names{event_variable} '.xlsx' ], '');
        writematrix(transpose(event_data_CI), save_fname);


        % Find consecutive indices of activation for the mean
        mean_event_sig = mean(event_sig, 2);
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

        title([ 'bCI activation periods for ' day_names{fidx} ]);
        xlabel('Time (s)');
        ylabel('Z-Scored dF/F');
        % Save consecutive thresholded plot
        save_fname = join([ var_directory '\' day_names{fidx} ' plot CT ' variable_names{event_variable} ], '');
        print(save_fname, '-dpng');

    end
end

function days_idx = getDays(fnames, daynames)
    % Unwrap fnames if necessary
    if length(fnames) > 0 && isa(fnames{1,1}, 'cell');
       fnames = vertcat(fnames{:});
    end    
    
    days_idx_arr = zeros(length(daynames), 2);
    for didx=1:length(daynames)
        arr = strfind(fnames, daynames(didx));
        idx = find(~cellfun(@isempty, arr), 1);
        days_idx_arr(1, didx) = idx;
    end
    days_idx = days_idx_arr(1, :);
end
