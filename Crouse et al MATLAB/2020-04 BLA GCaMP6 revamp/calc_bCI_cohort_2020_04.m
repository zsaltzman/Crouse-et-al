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

MDIR_DIRECTORY_NAME = output_dir_path;
make_directory;

cohort_dir_path = join([ FP_BCI_PARENT_FOLDER '\cohort' ]);

% day at which each mouse hit the reward threshold
rew_threshold_day_names = [ "353 Timeout Day 04"; "354 Timeout Day 02"; "361 Timeout Day 06"; "362 Timeout Day 05"; "363 Timeout Day 04"; "365 Timeout Day 02" ];
ext_day_names = [ "353 ZExtinction Day 01"; "354 ZExtinction Day 01"; "361 ZExtinction Day 01"; "362 ZExtinction Day 01"; "363 ZExtinction Day 01"; "365 ZExtinction Day 01"];
cued_1_names = [  "353 Cued Day 01"; "354 Cued Day 01"; "361 Cued Day 01"; "362 Cued Day 01"; "363 Cued Day 01"; "365 Cued Day 01"];
cued_4_names = [  "353 Cued Day 04"; "354 Cued Day 04"; "361 Cued Day 04"; "362 Cued Day 04"; "363 Cued Day 04"; "365 Cued Day 04"];
timeout_3_names = [  "353 Timeout Day 03"; "354 Timeout Day 03"; "361 Timeout Day 03"; "362 Timeout Day 03"; "363 Timeout Day 03"; "365 Timeout Day 03"];
timeout_last_names = [  "353 Timeout Day 07"; "354 Timeout Day 07"; "361 Timeout Day 07"; "362 Timeout Day 07"; "363 Timeout Day 07"; "365 Timeout Day 07"];

load(FP_INDIVIDUAL_DAY_DATA_FILENAME);
filenames = datanames;

rew_threshold =  getDays(filenames, rew_threshold_day_names);
ext_day = getDays(filenames, ext_day_names);
cued_1 = getDays(filenames, cued_1_names);
cued_4 = getDays(filenames, cued_4_names);
timeout_3 = getDays(filenames, timeout_3_names);
timeout_last = getDays(filenames, timeout_last_names); 

days_array = [ cued_1; cued_4; timeout_3; rew_threshold; timeout_last; ext_day ];
day_names = { 'Cued Day 01'; 'Cued Day 04'; 'Timeout Day 03'; 'Reward Threshold'; 'Final Timeout'; 'Extinction' };

load(event_dir_path);
event_dir = datanames; % Filenames loaded from the day graph data
event_variables = [ 1, 2, 3, 4, 6]; 
variable_names = { 'correct' 'tone' 'incorrect' 'receptacle' 'randrec' 'tonehit' 'tonemiss' 'inactive' };

for vidx=1:length(event_variables)
    event_variable = event_variables(vidx);
    var_directory = join([ cohort_dir_path '\' variable_names{event_variable} ], '');
    
    MDIR_DIRECTORY_NAME = var_directory; 
    make_directory;
    for fidx=1:size(days_array, 1)

        event_sig = [];
        for didx = 1:size(days_array, 2)
            if days_array(fidx, didx) ~= -1
                event_sig = cat(2, event_sig, graphmean{days_array(fidx, didx), event_variable});
            end
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