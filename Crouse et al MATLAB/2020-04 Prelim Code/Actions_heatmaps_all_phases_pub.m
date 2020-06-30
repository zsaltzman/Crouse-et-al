%% Actions_heatmaps_all_phases_v4_2_pub
%format for aligning data and heatmap structure is insprired by the example
%code by TDT found at https://www.tdt.com/support/matlab-sdk/offline-analysis-examples/licking-bout-epoc-filtering/

clear;
load(getPipelineVarsFilename);
codename = 'rick_actions_heatmaps_all_phases_v4_2_pub';
%% Set folder/files
    
load(FP_INDIVIDUAL_DAY_DATA_FILENAME);

outputfolder = FP_SUMMARY_DIRECTORY;
timestampfile = FP_TIMESTAMP_FILE;
outputfile = 'MATLAB means+sem for prism';

MDIR_DIRECTORY_NAME = outputfolder;
make_directory; 

skips = [];

%Groups
%lumped 850 in with gach for this
gcamp6 = [353 354 361 362 363 365];
gcamp7 = [891 913];

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
    data_mouse_ID(ii) = str2double(datanames{ii}{1}(8:11));
end

all_mouse_ID= unique(data_mouse_ID);

%for drawing white line
% TODO: Update reward thresholds and extinction days once I hear from rick
% First row is gcamp7, second is gcamp6
% NOTE: Timeout days for 354 and 365 are dummies, take them out later!
rew_threshold= ["0891 Timeout Day 02" "0913 Timeout Day 05" "" "" "" ""; "353 Timeout Day 04" "354 Timeout Day 02" "361 Timeout Day 06" "362 Timeout Day 05" "363 Timeout Day 04" "365 Timeout Day 02" ];
Ext_Day =["0891 ZExtinction Day 01" "0913 ZExtinction Day 01" "" "" "" ""; "353 ZExtinction Day 01" "354 ZExtinction Day 01" "361 ZExtinction Day 01" "362 ZExtinction Day 01" "363 ZExtinction Day 01" "365 ZExtinction Day 01"];

%set for loop num
nummer = 1:size(all_mouse_ID,1);
for num = nummer
    %Define mouse_ID number for the run of the for loop
    mouse_ID = all_mouse_ID(num);
      
    %What indicator is it?
    if any(mouse_ID == gcamp7)
        indicator = 'NBM-BLA GCaMP7';
        climits = [-3 7];
        gcampnum=find(gcamp7==mouse_ID);
        expidx = 1;
    else
        indicator = 'BLA GCaMP6';
        climits = [-3 7];
        gcampnum=find(gcamp6==mouse_ID);
        expidx = 2;
    end
        
    %Cut down raw to just current mouse
    %Index all rows with mouse_ID and select those rows from graphdata  
    mousemean = graphmean((data_mouse_ID(:,1) == mouse_ID),:);
    mousesem = graphsem((data_mouse_ID(:,1) == mouse_ID),:);
    mousenames = datanames((data_mouse_ID(:,1) == mouse_ID),:)';
    
    %trim to just Cued 1 - Ext end (end-3)
    trimmedmean = mousemean(1:end,:);
    trimmedsem = mousesem(1:end,:);
    trimmednames = mousenames(1,1:end);
 
    %% Make arrays for each mouse, across days
  
    clear correct tone incorrect receptacle randrec tonehit tonemiss inactive day_align_filenames day_label
    
    for action = 1:size(trimmedmean,2)
        
        %use day_counter to prevent black bar when skipping days
        day_counter = 0;
        
        for file = 1:size(trimmedmean,1)
            if any(strcmp(trimmednames{file}{1}(8:end-5),skips))  
                continue
            else
                
                day_counter = day_counter+1;
                
                if action == 1
                    %determine the day of mice
                    day_align_filenames{day_counter,1} = trimmednames{1,file}{1};
                    day_label{day_counter,1} = trimmednames{1,file}{1}(end-6:end-5);
                    p_day_align_filenames{day_counter*2-1,1} = trimmednames{1,file}{1};
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
    
    %% Find start day of phases, for collapsing across mice
    day_align = incorrect;
    
    
    %Find all the days that are Timeout
    timeout_test = strfind(day_align_filenames,'Timeout');
    
    %find the first non-empty cell and set that index to TO
    TO = find(~cellfun(@isempty,timeout_test),1);
    
    TO_Last_day = find(~cellfun(@isempty,timeout_test),1,'last');
    
    %Find all the days that are Ext
    Ext_test = strfind(vertcat(mousenames{:}),'ZExtinction');
    
    %find the first non-empty cell and set that index to TO
    Ext = find(~cellfun(@isempty,Ext_test),1);
    


    
    rew_thresh_test = strfind(day_align_filenames,rew_threshold(expidx, gcampnum));
    
    rew_thresh_day = find(~cellfun(@isempty,rew_thresh_test),1);
    
    rew_thresh_all_mice(:,gcampnum) = day_align(:,rew_thresh_day );
    
    
    Ext_Day_test = strfind(day_align_filenames,Ext_Day(expidx, gcampnum));
    
    Ext_Day_day = find(~cellfun(@isempty,Ext_Day_test),1);
    
    Ext_Day_day_all_mice(:,gcampnum) = day_align(:,Ext_Day_day );
    
    %% For collapsing mice
    
    %    Cued_day_1
    Cued_day_1_test = strfind(lower(day_align_filenames),lower([num2str(gcamp7(gcampnum)) ' Cued Day 01']));
    
    Cued_day_1_day = find(~cellfun(@isempty,Cued_day_1_test),1);
    
    Cued_day_1_all_mice(:,gcampnum) = day_align(:,Cued_day_1_day);
    
    %    Cued_day_5
    Cued_day_4_test = strfind(lower(day_align_filenames),lower([num2str(gcamp7(gcampnum)) ' Cued Day 04']));
    
    Cued_day_4_day = find(~cellfun(@isempty,Cued_day_4_test),1);
    
    Cued_day_4_all_mice(:,gcampnum) = day_align(:,Cued_day_4_day);
    
    %TO_day_02
    
    TO_day_02_test = strfind(lower(day_align_filenames),lower([num2str(gcamp7(gcampnum)) ' Timeout Day 02']));
    
    TO_day_02_day = find(~cellfun(@isempty,TO_day_02_test),1);
    
    TO_day_02_day_all_mice(:,gcampnum) = day_align(:,TO_day_02_day);
    
    
    %Last_TO
    %simpler than other bc I found last TO day above
    TO_Last_day_all_mice(:,gcampnum) = day_align(:,TO_Last_day);
    
    
    

%%  Make heatmap

for idx = 1:size(variables,2)
    %pull out the means into the heatnumbers variable for plotting
    %example: heatnumbers = proper(:,1:2:end)';
    eval(['heatnumbers =' variables{idx} ';']);
    heatnumbers = heatnumbers';
    


    figure('Visible', 'off')
    cf = imagesc(graphtime,1, heatnumbers, climits);
    
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
    
    %remove yticks and yticklabels
    %usually don't have labels but including here for ease of seeing which
    %days were included and which were not
%     set(gca,'ytick',[])
%     set(gca,'yticklabel',[])
    
    yline(TO-0.5, 'LineWidth', 1.75);
    
    %double line drawing to make it brighter
    yline(rew_thresh_day - 0.5 , 'w', 'LineWidth', 1.75);
    yline(rew_thresh_day - 0.5 , 'w', 'LineWidth', 1.75);
    
    if ~isempty(Ext)
        yline(Ext-0.5, 'LineWidth', 1.75);
    end
 
    set(gca,'YDir','normal')
    
    cb = colorbar;
    ylabel(cb, 'Z %\DeltaF/F0' ,'fontsize',16)
    xticks([-4:2:4]);
    
    print([outputfolder  '\' indicator ' ' num2str(mouse_ID) ' ' variables{idx}], '-dpng');

    close all
end

%write to xlsx file

p_day_align_filenames = p_day_align_filenames';

for idx = 1:size(prism_variables,2)
    eval([prism_variables{idx},' = [p_day_align_filenames; num2cell(', prism_variables{idx}, ')];']);
    writecell(eval(prism_variables{idx}), [outputfolder '\' indicator ' '  num2str(mouse_ID) ' ' outputfile '.xlsx'], 'Sheet', prism_variables{idx});
end

clear day_align correct tone incorrect receptacle randrec tonehit tonemiss inactive day_align_filenames day_label
clear p_correct p_tone p_incorrect p_receptacle p_randrec p_tonehit p_tonemiss p_inactive p_day_align_filenames

end

%% plot collapsed 

% Plot collapsed across mice (expanded collapse days)

mean_Cued_day_1 = nanmean(Cued_day_1_all_mice,2);
mean_Cued_day_4 = nanmean(Cued_day_4_all_mice,2);
mean_TO_day_02 = nanmean(TO_day_02_day_all_mice,2);
mean_rew_thresh = nanmean(rew_thresh_all_mice,2);
mean_TO_Last = nanmean(TO_Last_day_all_mice,2);
mean_Ext = nanmean(Ext_Day_day_all_mice,2);

%spaced out a lot in this vector to make it easier to see separation
mean_all_days = [mean_Cued_day_1    mean_Cued_day_4     mean_TO_day_02 ...
                 mean_rew_thresh     mean_TO_Last   mean_Ext];
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
yline(6-0.5, 'LineWidth', 1.75);
yline(4 - 0.5 , 'w', 'LineWidth', 1.75);

%double line to brighten
yline(4 - 0.5 , 'w', 'LineWidth', 1.75);

cb = colorbar;
ylabel(cb, 'Z %\DeltaF/F0' ,'fontsize',16)

%Print png version of graph (save)
print([outputfolder '\Collapsed by incorrect ' indicator ], '-dpng');

close all

%print the version of the code used
fileID = fopen([outputfolder '\' date 'codeused.txt'],'w');
fprintf(fileID, codename);