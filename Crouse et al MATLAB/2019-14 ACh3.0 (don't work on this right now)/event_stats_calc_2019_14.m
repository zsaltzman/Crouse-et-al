%event_stats_calc_2019_14
%v2 (named v2 by Rick)
    %v1 is just event_stats_calc

clear;

load(getPipelineVarsFilename);
load(FP_INDIVIDUAL_DAY_DATA_FILENAME); % intermediate variables produced by Mean_SEM_calc
MDIR_DIRECTORY_NAME = FP_ANALYSIS_DIRECTORY;
make_directory

variable_list = [ 1, 3, 6]; 
variable_names = { 'correct' 'tone' 'incorrect' 'receptacle' 'randrec' 'tonehit' 'tonemiss' 'inactive' };
fs = 122; % Sampling frequency of 122
timescale = [-5 10]; % measurements taken from 5 seconds before spike to 10 seconds after 

%file to skip
skips = [''];
% skips = ["0849 Timeout Day 09"; "0849 Timeout Day 11"; "0856 ZExtinction Day 01"];

% day at which each mouse hit the reward threshold
rew_threshold =  ["MATLAB_0124 Timeout Day 09"; "MATLAB_0129 Timeout Day 03"; "MATLAB_0176 Timeout Day 10"; "MATLAB_0850 Timeout Day 06"; "MATLAB_1012 Timeout Day 03" ];

% extinction days to group in aligned sheet
ext_day = ["MATLAB_0124 ZExtinction Day 01"; "MATLAB_0129 ZExtinction Day 03"; "MATLAB_0176 ZExtinction Day 01"; "MATLAB_0850 ZExtinction Day 01"; "MATLAB_1012 ZExtinction Day 03"];

% unpack cell array if needed (i.e. if the entries of datanames are 1x1
% cells, turn them into character arrays. otherwise leave it)
if isa(datanames{1, 1}, 'cell')
    datanames = vertcat(datanames{:});
end
sorted_datanames = sort_nat(datanames);
subjects = sort_nat(unique(extractBefore(extractAfter(sorted_datanames, 'MATLAB_'), ' '))); % subject numbers, sorted in ascending order

% determine size of stats arrays by the longest length in subject file
subj_len = -1;
for idx=1:length(subjects)
    current_subj_len = length(datanames(contains(datanames, subjects{idx})));
    if current_subj_len > subj_len
        subj_len = current_subj_len;
    end
end

for vidx=1:size(variable_list, 2)
    variable = variable_list(vidx);
    
    % Full sheets for max and SEM (all subjects)
    spikemax = cell(subj_len, length(subjects));
    spikestats = cell(subj_len, length(subjects)); % standard error margin (SEM)
    
    % Partial sheets aligned to threshold day and ten reward day
    aligned_spikemax = cell(6, length(subjects));
    aligned_spikestats = cell(6, length(subjects));
    
    for subj=1:size(subjects)
        subject_datanames = datanames(contains(datanames, subjects{subj}));
        num_ext_days = nnz(contains(subject_datanames, 'ZExtinction'));
        for fidx=1:size(subject_datanames, 1)
            % split file extension off subject name for comparison
            splitname = split(subject_datanames{fidx, 1}, '.');
            
            if ~contains(skips, splitname{1})
                % get index in unsorted datanames using the filename
                unsorted_idx = find(contains(datanames, subject_datanames{fidx,1}));
                graphmeancell = graphmean{unsorted_idx, variable};
                
                % spike should occur between 5 and 6 seconds on the
                % captured event (if there's any data)
                
                if length(graphmeancell) > 0
                    [ maxval, maxidx ] = max(graphmeancell(5*fs:6*fs));
                    maxidx = maxidx + 5*fs - 1; % Adjust maxidx by the start point and adjust for matlab array bounds
                    
                    % now get SEM from the appropriate timepoint
                    semmat = graphsem{unsorted_idx, variable};
                    maxsem = semmat(maxidx, 1);
                else
                    fprintf('Skipping empty day %s for variable %s\n', subject_datanames{fidx, 1}, variable_names{variable});
                    spikemax{fidx, subj} = '';
                    spikestats{fidx, subj} = '';
                end
                
                spikemax{fidx, subj} = maxval;
                spikestats{fidx, subj} = maxsem;
                
                %% Add chosen alignment days to the alignment sheet
                % 10 reward day, threshold day, an extinction day
                % cued days 1 and 5, timeout days 3, 13, 15, and the last
                % day of timeout
                if nnz(contains(rew_threshold, splitname{1})) > 0
                    aligned_spikemax{4, subj} = maxval;
                    aligned_spikestats{4, subj} = maxsem;
                elseif nnz(contains(ext_day, splitname{1})) > 0
                    aligned_spikemax{6, subj} = maxval;
                    aligned_spikestats{6, subj} = maxsem;
                elseif fidx == 1
                    aligned_spikemax{1, subj} = maxval;
                    aligned_spikestats{1, subj} = maxsem;
                elseif fidx == 4
                    aligned_spikemax{2, subj} = maxval;
                    aligned_spikestats{2, subj} = maxsem;
                elseif fidx == 6
                    aligned_spikemax{3, subj} = maxval;
                    aligned_spikestats{3, subj} = maxsem;
                elseif fidx == length(subject_datanames) - num_ext_days % last timeout day
                    aligned_spikemax{5, subj} = maxval;
                    aligned_spikestats{5, subj} = maxsem;
                end
                
                
            end
            
        end
    end
    
    %doesn't work if file name has a . other than file ext
%     split_dataname = split(FP_ANALYSIS_DATASHEET, '.');

    %just divide name by calling all but last 5 chars
    split_dataname = FP_ANALYSIS_DATASHEET(1:end-5);
    
    unalignedsheetname = join([ split_dataname '_' variable_names(variable) '.xlsx']);
    alignedsheetname = join([ split_dataname '_' variable_names(variable) '_aligned.xlsx']);
    
    day_labels = { 'PT1'; 'PT2'; 'PT3'; 'PT4'; 'Training 1'; 'Training 2'; 'Training 3'; 'Training 4'; 'Training 5'; 'Training 6'; 'Training 7'; 'Training 8'; 'Training 9'; 'Training 10'; 'Training 11'; 'Training 12'; 'Ext 1'; 'Ext 2'; 'Ext 3'; };
    aligned_day_labels = { 'PT1'; 'PT4'; 'Training 2'; 'Reward Threshold'; 'Final Training'; 'Extinction' };
    subject_labels = { '' '124' '129' '176' '850' '1012' };
    spikemax = cat(2, day_labels, spikemax);
    spikemax = cat(1, subject_labels, spikemax);
    
    spikestats = cat(2, day_labels, spikestats);
    spikestats = cat(1, subject_labels, spikestats);
    
    aligned_spikemax = cat(2, aligned_day_labels, aligned_spikemax);
    aligned_spikemax = cat(1, subject_labels, aligned_spikemax);
    
    aligned_spikestats = cat(2, aligned_day_labels, aligned_spikestats);
    aligned_spikestats = cat(1, subject_labels, aligned_spikestats);
    
    % Write the peak data to an excel sheet);
    writecell(spikemax, unalignedsheetname{1}, 'Sheet', 'max');
    writecell(spikestats, unalignedsheetname{1}, 'Sheet', 'SEM');
    
    % Now write the aligned sheet
    writecell(aligned_spikemax, alignedsheetname{1}, 'Sheet', 'max');
    writecell(aligned_spikestats, alignedsheetname{1}, 'Sheet', 'SEM');
    
end


