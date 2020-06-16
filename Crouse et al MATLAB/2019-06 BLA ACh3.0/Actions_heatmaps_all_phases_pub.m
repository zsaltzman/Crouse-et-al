%% Actions_heatmaps_all_phases_v4_pub
%format for aligning data and heatmap structure is insprired by the example
%code by TDT found at https://www.tdt.com/support/matlab-sdk/offline-analysis-examples/licking-bout-epoc-filtering/



%% IMPORTANT NOTE:
% Make sure the variable names specified in your raw files directory are
% zero padded the same way as your input files (e.g. if your MATLAB files
% are named ...Timeout_01_1 make sure the raw filenames here match
% exactly!)

clear;
load(getPipelineVarsFilename);
load(FP_INDIVIDUAL_DAY_DATA_FILENAME);
exp = '2019-06';

codename = 'actions_heatmaps_all_phases_v4_1_pub';
%% Set folder/files

folder = FP_SUMMARY_DIRECTORY;


outputfolder = FP_SUMMARY_DIRECTORY;
timestampfile = FP_TIMESTAMP_FILE;
outputfile = 'MATLAB means+sem for prism';

MDIR_DIRECTORY_NAME = outputfolder;
make_directory;

skips = ["827_Timeout_Day_06"; "820_Timeout_Day_06";"814_Timeout_Day_01"; "814_Timeout_Day_07"; "813_Timeout_Day_12"];
%Excluded 814 TO 01 because there's no reward with receptacle following within
%5 sec, this way will keep consistent with tone_poke_rec plots


%Groups
BLA_GACh = [813 814 820 827];

%file to skip




variables = ["correct" "tone" "incorrect" "receptacle" "randrec" "tonehit" "tonemiss" "inactive"];
prism_variables = ["p_correct" "p_tone" "p_incorrect" "p_receptacle" "p_randrec" "p_tonehit" "p_tonemiss" "p_inactive"];

%import timestamp
time = readmatrix(timestampfile);
graphtime = time;

%initialize
data_mouse_ID = zeros(size(datanames,1),1);

%prep for cut down data to just one mouse

for ii = 1:size(datanames,1)
    data_mouse_ID(ii) = str2double(datanames{ii, 1}(8:10));
end

all_mouse_ID= unique(data_mouse_ID);

%for drawing white line
rew_threshold = ["813_Timeout_Day_20"; "814_Timeout_Day_17"; "820_Timeout_Day_19"; "827_Timeout_Day_18"];

%for grabbing specific days for collapsing mice
TO_10_rew = ["813_Timeout_Day_10"; "814_Timeout_Day_10"; "820_Timeout_Day_10"; "827_Timeout_Day_08"];
Ext_Day = ["813_ZExtinction_Day_03"; "814_ZExtinction_Day_04"; "820_ZExtinction_Day_01"; "827_ZExtinction_Day_02"];




%% cut down data to just one mouse
for num = 1:4
    
    %Define mouse_ID number for the run of the for loop
    mouse_ID = all_mouse_ID(num);
    
    %What indicator is it?
    indicator = 'BLA GACh';
    GAChnum=find(BLA_GACh==mouse_ID);
    
    
    
    %Cut down raw to just current mouse
    %Index all rows with mouse_ID and select those rows from graphdata
    mousemean = graphmean((data_mouse_ID(:,1) == mouse_ID),:);
    mousesem = graphsem((data_mouse_ID(:,1) == mouse_ID),:);
    mousenames = datanames((data_mouse_ID(:,1) == mouse_ID),:)';
    
    %trim to training phase
    trimmedmean = mousemean;
    trimmedsem = mousesem;
    trimmednames = mousenames;
    
    
    %% Make arrays for each mouse, across days
   
    
    clear correct tone incorrect receptacle randrec tonehit tonemiss inactive day_align_filenames
    
    for action = 1:size(trimmedmean,2)
        
        %use day_counter to prevent black bar when skipping days
        day_counter = 0;
        
        for file = 1:size(trimmedmean,1)
            
            if any(strcmp(trimmednames{1,file}(8:end-5),skips))
                continue
            else
                
                day_counter = day_counter+1;
                
                if action == 1
                    %determine the day of mice
                    day_align_filenames{day_counter,1} = trimmednames{1,file};
                    day_label{day_counter,1} = trimmednames{1,file}(end-6:end-5);
                    p_day_align_filenames{day_counter*2-1,1} = trimmednames{1,file};
                    p_day_align_filenames{day_counter*2,1} = [];
                end
                
                %if that action didn't happen that day, just put NaN's
                if isempty(trimmedmean{file,action})
                    eval([variables{action}, '(:,day_counter) = NaN(1832,1);']);
                    eval([prism_variables{action}, '(:,day_counter*2-1) =  NaN(1832,1);']);
                    eval([prism_variables{action}, '(:,day_counter*2) = NaN(1832,1);']);
                    
                else
                    %Fill in mean
                    
                    %e.g. correct(:,file) = ...
                    eval([variables{action}, '(:,day_counter) = trimmedmean{file,action};']);
                    
                    
                    %fill in mean/sem for prism variables
                    eval([prism_variables{action}, '(:,day_counter*2-1) = trimmedmean{file,action};']);
                    
                    %fill with NaNs if SEM is all 0 (meaning only one
                    %trial)
                    if sum(trimmedsem{file,action})==0
                        eval([prism_variables{action}, '(:,day_counter*2) = NaN(1832,1);']);
                    else
                        
                        %fill in SEM
                        eval([prism_variables{action}, '(:,day_counter*2) = trimmedsem{file,action};']);
                    end
                    
                    
                end
                
            end
            
        end
        
    end
    
    %% Find start day of phases and threshold days
    day_align = incorrect;
    
    %Find all the days that are Timeout
    timeout_test = strfind(lower(day_align_filenames),lower('Timeout'));
    
    %find the first non-empty cell and set that index to TO
    TO = find(~cellfun(@isempty,timeout_test),1);
    
    TO_Last_day = find(~cellfun(@isempty,timeout_test),1,'last');
    
    %Find all the days that are Ext
    Ext_test = strfind(day_align_filenames,'ZExtinction');
    
    %find the first non-empty cell and set that index to TO
    Ext = find(~cellfun(@isempty,Ext_test),1);
    
    %Find the rew_thresh day and others
    rew_thresh_test = strfind(day_align_filenames,rew_threshold(GAChnum));
    
    rew_thresh_day = find(~cellfun(@isempty,rew_thresh_test),1);
    
    rew_thresh_all_mice(:,GAChnum) = day_align(:,rew_thresh_day );
    
    %% For collapsing mice
    
    %    Cued_day_1
    Cued_day_1_test = strfind(lower(day_align_filenames),lower([num2str(BLA_GACh(GAChnum)) '_Cued_Day_01']));
    
    Cued_day_1_day = find(~cellfun(@isempty,Cued_day_1_test),1);
    
    Cued_day_1_all_mice(:,GAChnum) = day_align(:,Cued_day_1_day);
    
    %    Cued_day_5
    Cued_day_5_test = strfind(lower(day_align_filenames),lower([num2str(BLA_GACh(GAChnum)) '_Cued_Day_05']));
    
    Cued_day_5_day = find(~cellfun(@isempty,Cued_day_5_test),1);
    
    Cued_day_5_all_mice(:,GAChnum) = day_align(:,Cued_day_5_day);
    
    
    %TO_day_01
    
    TO_day_01_test = strfind(lower(day_align_filenames),lower([num2str(BLA_GACh(GAChnum)) '_Timeout_Day_01']));
    
    TO_day_01_day = find(~cellfun(@isempty,TO_day_01_test),1);
    
    if ~isempty(TO_day_01_day)
        TO_day_01_day_all_mice(:,GAChnum) = day_align(:,TO_day_01_day);
    end
    
    
    
    %TO_day_03
    
    TO_day_03_test = strfind(lower(day_align_filenames),lower([num2str(BLA_GACh(GAChnum)) '_Timeout_Day_03']));
    
    TO_day_03_day = find(~cellfun(@isempty,TO_day_03_test),1);
    
    TO_day_03_day_all_mice(:,GAChnum) = day_align(:,TO_day_03_day);
    
    %    TO_10_rew
    
    TO_10_rew_test = strfind(lower(day_align_filenames),lower(TO_10_rew(GAChnum)));
    
    TO_10_rew_day = find(~cellfun(@isempty,TO_10_rew_test),1);
    
    TO_10_rew_day_all_mice(:,GAChnum) = day_align(:,TO_10_rew_day);
    
    
    %    TO_day_13
    
    TO_day_13_test = strfind(lower(day_align_filenames),lower([num2str(BLA_GACh(GAChnum)) '_Timeout_Day_13']));
    
    TO_day_13_day = find(~cellfun(@isempty,TO_day_13_test),1);
    
    TO_day_13_day_all_mice(:,GAChnum) = day_align(:,TO_day_13_day);
    
    % TO_day_15
    
    TO_day_15_test = strfind(lower(day_align_filenames),lower([num2str(BLA_GACh(GAChnum)) '_Timeout_Day_15']));
    
    TO_day_15_day = find(~cellfun(@isempty,TO_day_15_test),1);
    
    TO_day_15_day_all_mice(:,GAChnum) = day_align(:,TO_day_15_day);
    
    %Last_TO
    %simpler than other bc I found last TO day above
    TO_Last_day_all_mice(:,GAChnum) = day_align(:,TO_Last_day);
    
    %Ext_Day
    Ext_Day_test = strfind(lower(day_align_filenames),lower(Ext_Day(GAChnum)));
    
    Ext_Day_day = find(~cellfun(@isempty,Ext_Day_test),1);
    
    Ext_Day_day_all_mice(:,GAChnum) = day_align(:,Ext_Day_day);
    
    
    
    
    %%  Make heatmap
    
    for idx = 1:size(variables,2)
        %pull out the means into the heatnumbers variable for plotting
        %example: heatnumbers = proper(:,1:2:end)';
        eval(['heatnumbers =' variables{idx} ';']);
        heatnumbers = heatnumbers';
        
        %clims for each individual action
            clims = [-3 7];
  
        
        figure('Visible', 'off')
        cf = imagesc(graphtime,1, heatnumbers, clims);
        
        colormap jet
        nanmap = [0 0 0; colormap];
        colormap(nanmap);
        
        ax = gca;
        xlim([-5 5]);
        ax.TickDir = 'out';
        ax.XAxis.TickLength = [0.02 0.01];
        ax.XAxis.LineWidth = 1.75;
        
         %add y ticks/labels for just the day
        %not included in pub for simplicity
        ax.YTick = 1:size(day_label,1);
        ax.YTickLabel = day_label;
        
        %TO and Ext change based on when the different phases happened
        
        %lines to draw/label

            yline(TO-0.5, 'LineWidth', 1.75);
            yline(Ext-0.5, 'LineWidth', 1.75);
            
            %double line drawing to make it brighter
            yline(rew_thresh_day - 0.5 , 'w', 'LineWidth', 1.75);
            yline(rew_thresh_day - 0.5 , 'w', 'LineWidth', 1.75);
            
            yline(TO_10_rew_day - 0.5 , '--w', 'LineWidth', 1.75);
            yline(TO_10_rew_day - 0.5 , '--w', 'LineWidth', 1.75);
            

        set(gca,'YDir','normal')
        
        %remove yticks and yticklabels
        %usually don't have labels but including here for ease of seeing which
        %days were included and which were not
%         set(gca,'ytick',[])
%         set(gca,'yticklabel',[])
        
        cb = colorbar;
        ylabel(cb, 'Z %\DeltaF/F0' ,'fontsize',16)
        xticks([-4:2:4]);
        
        print([outputfolder '\' num2str(mouse_ID) '_' indicator ' ' variables{idx}], '-dpng');
        
        close all
    end
    
    %write to xlsx file
    
    p_day_align_filenames = p_day_align_filenames';
    
    for idx = 1:size(prism_variables,2)
        eval([prism_variables{idx},' = [p_day_align_filenames; num2cell(', prism_variables{idx}, ')];']);
        writecell(eval(prism_variables{idx}), [outputfolder '\' num2str(mouse_ID) ' ' outputfile '.xlsx'], 'Sheet', prism_variables{idx});
    end
    
    clear day_align day_align_sem day_align_filenames correct tone incorrect receptacle randrec tonehit tonemiss inactive day_align_filenames day_label
    clear p_correct p_tone p_incorrect p_receptacle p_randrec p_tonehit p_tonemiss p_inactive p_day_align_filenames
    
end

    
    %% Plot collapsed across mice (expanded collapse days)
    climits = [-2 6];
    
    mean_Cued_day_1 = nanmean(Cued_day_1_all_mice,2);
    mean_Cued_day_4 = nanmean(Cued_day_5_all_mice,2);
    mean_TO_day_01 = nanmean(TO_day_01_day_all_mice,2);
    mean_TO_day_03 = nanmean(TO_day_03_day_all_mice,2);
    mean_TO_10 = nanmean(TO_10_rew_day_all_mice,2);
    mean_TO_day_13 = nanmean(TO_day_13_day_all_mice,2);
    mean_TO_day_15 = nanmean(TO_day_15_day_all_mice,2);
    mean_rew_thresh = nanmean(rew_thresh_all_mice,2);
    mean_TO_Last = nanmean(TO_Last_day_all_mice,2);
    mean_Ext = nanmean(Ext_Day_day_all_mice,2);
    
    %spaced out a lot in this vector to make it easier to see separation
    mean_all_days = [mean_Cued_day_1    mean_Cued_day_4  mean_TO_day_01   mean_TO_day_03     mean_TO_10    ...
        mean_TO_day_13     mean_TO_day_15     mean_rew_thresh     mean_TO_Last   mean_Ext];
    
    figure('Visible', 'off')
    cf = imagesc(graphtime,1,mean_all_days', climits);
    
    colormap jet
    nanmap = [0 0 0; colormap];
    colormap(nanmap);
    
    
    ax = gca;
    xlim([-5 5]);
    xticks([-4:2:4]);
    ax.TickDir = 'out';
    ax.XAxis.TickLength = [0.02 0.01];
    ax.XAxis.LineWidth = 1.75;
    
    set(gca,'YDir','normal') % put the trial numbers in order from bot to top on y-axis
    
    %remove yticks and yticklabels
    set(gca,'ytick',[])
    set(gca,'yticklabel',[])
    
    
    yline(3-0.5, 'LineWidth', 1.75);
    yline(5 - 0.5 , '--w', 'LineWidth', 1.75);
    yline(8 - 0.5 , 'w', 'LineWidth', 1.75);
    yline(10-0.5, 'LineWidth', 1.75);
    
    %draw white lines again to make brighter)
    yline(5 - 0.5 , '--w', 'LineWidth', 1.75);
    yline(8 - 0.5 , 'w', 'LineWidth', 1.75);
    
    cb = colorbar;
    ylabel(cb, 'Z %\DeltaF/F0' ,'fontsize',16)
    
    %Print png version of graph (save)
    print([outputfolder '\Collapsed incorrect days ' indicator], '-dpng');
    


%print the version of the code used
fileID = fopen([outputfolder '\codeused.txt'],'w');
fprintf(fileID, codename);