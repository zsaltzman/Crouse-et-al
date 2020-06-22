%% rick_tone_to_poke_heatmaps_by_mouse_plots_v3
%for use with 2020-04 Code


%v2: changing labeling+numbering for publication. Also changing colormap to jet


%built from rick_tone_to_poke_heatmaps_by_mouse_plots_v2.ish
%v3: adding rec to make it tone_poke_rec_heatmaps_by_mouse
%v2: collapse across mice for select days based on behavior
%v1_1: add loading


clear;

exp = '2020-04';
% exp = '2019-06';
codename = 'rick_tone_poke_rec_heatmaps_by_mouse_v4';

%Groups
NBM_BLA = [891 913];
camkii_gcamp = [353 354 361 362 363 365];


%old groups left in to prevent bugs
gad_gcamp = [];
gach = [];
rcamp_gach = [];

%% Set folder/files

% if strcmp(exp,'2019-14')
    
    load('C:\Users\User\Google Drive\2020-04 FP\Doric\MATLAB\MATLAB vars\current_rawtogether_filenames.mat');
    
    outputfolder = 'C:\Users\User\Google Drive\2020-04 FP\Doric\MATLAB\Summary TonetoPoketoRec Heat';
    outputfile = [exp ' App MATLAB tonetopoketorec heat by mouse data'];
    
    %file to skip
    skips = [" "];

% end

%initialize
data_mouse_ID = zeros(size(filenames,1),1);


%% Organize data and Make Heat Map
%transposing for plotting purposes, using '

% if strcmp(exp,'2019-14')
    
    %prep for cut down data to just one mouse
    
    for ii = 1:size(filenames,1)
        data_mouse_ID(ii) = str2double(filenames{ii}(11:14));
    end
    
    all_mouse_ID= unique(data_mouse_ID);
    
    
    
    %for drawing white line
    rew_threshold = [""];
    
    
    %for grabbing specific days for collapsing mice
%     TO_10_rew = ["856 Timeout Day 09"; "860 Timeout Day 09"];
    
    
    
% elseif strcmp(exp,'2018-07')
%     %prep for cut down data to just one mouse
%     
%     for ii = 1:size(filenames,1)
%         data_mouse_ID(ii) = str2double(filenames{ii}(14));
%     end
%     
%     all_mouse_ID= unique(data_mouse_ID);
%     
%     %for drawing white line
%     %     rew_threshold = ["3_Timeout_Day_08"; "4_Timeout_Day_08"; "5 was dud"; "6_Timeout_Day_13"];
%     rew_threshold = ["3_Timeout_Day_08"; "4_Timeout_Day_08"; "6_Timeout_Day_13"];
%     
% end



% for num = [11 12]
for num = 1:size(all_mouse_ID,1)
% for num = [4 5 7 8]
    % for num = 5
    
    
    
    %Define mouse_ID number for the run of the for loop
    mouse_ID = all_mouse_ID(num);
    
    
    
    %What indicator is it?
    %Note: not doing str2double here for indicator checking bc they're
    %already doubles in order to find uniques above
    if any(mouse_ID == gach)
        indicator = 'GACh';
        climits = [-3 7];
        
        
    elseif any(mouse_ID == rcamp_gach)
        indicator = 'RCaMP + GACh';
        climits = [-3 7];
        rcamp_climits = [];
        %         climits = [-3 7];
        %         GAChnum=find(BLA_GACh==mouse_ID);
        
    elseif any(mouse_ID == camkii_gcamp)
           indicator = 'CaMKII-GCaMP';
        climits = [-2 4];
        
        CaMKIInum=find(camkii_gcamp==mouse_ID);
        
    elseif any(mouse_ID == gad_gcamp)
        indicator = 'Gad65-GCaMP';
        climits = [-3 4];
        %         climits = [-3 7];
        %         GAChnum=find(BLA_GACh==mouse_ID);
        
    elseif any(mouse_ID == NBM_BLA)
        indicator = 'NBM-BLA';
        climits = [-2 6];
      
        NBM_BLAnum=find(NBM_BLA==mouse_ID);
        
        
        
    end
    
    %originally had 813's limits lower but not sure why
    %     %come up with something more elegant for changing the climits for
    %     %individual mice if doing this for a lot
    %     if mouse_ID == 813
    %         climits = [-3 6];
    %     end
    %
    
    
    %trim data and filenames to just current mouse
    mousedata = rawtogether((data_mouse_ID(:,1) == mouse_ID),:);
    mousefiles = filenames((data_mouse_ID(:,1) == mouse_ID),:);
    
    %use day_counter to prevent black bar when skipping days
    day_counter = 0;
    
    %     day_align = NaN(611+lat*122+611,size(mousedata,1));
    %     day_align_sem = NaN(611+lat*122+611,size(mousedata,1));
    %
    
    %do just first 19 days
%     for file = 1:19
    for file = 1:size(mousedata,1)
        
        %instead of finding longest latency, standardize to a 4 sec
        %latency
        %use a 1 sec pull for
        %if you want to change the amount you pull, change lat
        lat = 4;
        half_lat = lat*122/2;
        
        rew_lat = 1;
        half_rew_lat = rew_lat*122/2;
        
        divider = 16;
        
        %skip shitters
        if any(strcmpi(mousefiles{file}(11:end-6),skips))
            
            continue
            
            %make sure there's actually something to plot (at least one
            %reward), if not, skips to next
        elseif size(mousedata{file,1},2)==0
            continue
            
            %find mean of each day
        else
            
            %if the day isn't skipped, increase day counter. This will
            %prevent black bars for skipped days
            day_counter = day_counter+1;
            
            %
            %
            %             %create a time vector based on longestlat, with t=0 is tone onset
            %             timevector = mousedata{1,1}{2,2}(1:1710,1)-mousedata{1,1}{2,2}(611,1);
            %             Saved in C:\Users\User\Google Drive\2019-06 NBM-BLA + GACh FP\Doric\Processed\2019-06 App MATLAB\Mouse TonetoPoke Heat
            
            %preallocate aligntogether as NaN
            %doing 5 sec before tone + tone + half_lat + divider + half_lat
            % + poke + half_rew_lat + divider + half_rew_lat + rec + 5 sec
            % after rec
            
            %find number of non empty
            not_empty_rewards = find(~cellfun(@isempty,mousedata{file,1}(1,:)));
            
            aligntogether = NaN(610 + 1 + half_lat + divider + half_lat + 1 + half_rew_lat + divider + half_rew_lat + 1 + 610 ,size(not_empty_rewards,2));
            
            
            align_reward_counter = 0;
            
            %cycle through rewards of mousedata that aren't empty
            for reward = not_empty_rewards
                %using this counter to skip the rewards that didn't
                %have a rec entry following NP within 5 secs (which are
                %empty matrices in rawtogether)
                align_reward_counter = align_reward_counter+1 ;
                
                %grab the index of actions
                tone = find(mousedata{file,1}{1,reward}(:,3) == 2);
                poke = find(mousedata{file,1}{1,reward}(:,3) == 1);
                rec = find(mousedata{file,1}{1,reward}(:,3) == 4);
                
                %determine half of actual latencies
                half_actual_lat = round((poke-tone)/2);
                half_actual_rew_lat= round((rec-poke)/2);
                
                %determine min between actual and default
                min_pull_tone_poke = min(half_actual_lat,half_lat);
                min_pull_poke_rec = min(half_actual_rew_lat,half_rew_lat);
                
                
                stop_insert_tone = 611 + min_pull_tone_poke;
                
                %half_lats used here to skip the max lat before divider
                %also used to determine how shy of half_lat it should start
                %inserting poke
                start_insert_poke = 611 + half_lat + divider + 1 + half_lat - min_pull_tone_poke;
                stop_insert_poke = 611 + half_lat + divider + 1 + half_lat + min_pull_poke_rec;
                
                %plus used here because I call this variable using end - it
                start_insert_rec = 610 + min_pull_poke_rec;
                
                
                %add first bit, 5 sec before tone to half_lat after tone
                aligntogether(1:stop_insert_tone,align_reward_counter)  = mousedata{file,1}{1,reward}(1:stop_insert_tone,2);
                
                %add middle bit
                aligntogether(start_insert_poke:stop_insert_poke,align_reward_counter) = mousedata{file,1}{1,reward}(poke-min_pull_tone_poke:poke+min_pull_poke_rec,2);
                
                %add last bit, half_rew_lat before rec to 5 sec after
                aligntogether(end-start_insert_rec:end,align_reward_counter) = mousedata{file,1}{1,reward}(end-610-min_pull_poke_rec:end,2);
            end
            
            %take the file name
            %Note: the names are going in as columns to reflect how data is
            %being stored
            day_align_filenames{day_counter,1} = mousefiles{file,1};
            
            day_align(:,day_counter) = nanmean(aligntogether,2);
            %take sem if want to plot it later
            day_align_sem(:,day_counter) = nanstd(aligntogether,0,2)/sqrt(size(aligntogether,2));
            
            %take day number for labeling
            day_label{day_counter,1} = mousefiles{file,1}(end-7:end-6);
            %
            %             day_align(:,file) = nanmean(aligntogether,2);
            %             %take sem if want to plot it later
            %             day_align_sem(:,file) = nanstd(aligntogether,0,2)/sqrt(size(aligntogether,2));
            %
        end
        
    end
    
    %% Find start day of phases and threshold days
%     
    %Find all the days that are Timeout
    timeout_test = strfind(lower(day_align_filenames),lower('Timeout'));
    
    %find the first non-empty cell and set that index to TO
    TO = find(~cellfun(@isempty,timeout_test),1);
    
    TO_Last_day = find(~cellfun(@isempty,timeout_test),1,'last');
    
%     if strcmp(exp,'2019-14')
        %Find all the days that are Ext
        Ext_test = strfind(day_align_filenames,'ZExtinction');
        
%     elseif strcmp(exp,'2018-07')
%         Ext_test = strfind(day_align_filenames,'ZZExt');
%         
%     end
    
    
    %find the first non-empty cell and set that index to Ext
    Ext = find(~cellfun(@isempty,Ext_test),1);
    
    
    
%     %Find the rew_thresh day
%     %indexing by the num of GACh mouse, into the rew_threshold array that
%     %has the full names for the threshold days, similar to above but
%     %looking for a specific day, not just one
%     
% %   
%     


%% No collapsed yet until make a better way to do this for each group

%     
%     if any(mouse_ID == NBM_BLA)
%         rew_thresh_test = strfind(day_align_filenames,rew_threshold(NBM_BLAnum));
%         
%         rew_thresh_day = find(~cellfun(@isempty,rew_thresh_test),1);
%         
%         rew_thresh_all_mice(:,NBM_BLAnum) = day_align(:,rew_thresh_day );
%         
%         %% For collapsing mice
%         
%         %    Cued_day_1
%         Cued_day_1_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(NBM_BLAnum)) ' Cued Day 01']));
%         
%         Cued_day_1_day = find(~cellfun(@isempty,Cued_day_1_test),1);
%         
%         Cued_day_1_all_mice(:,NBM_BLAnum) = day_align(:,Cued_day_1_day);
%         
%         %    Cued_day_5
%         Cued_day_4_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(NBM_BLAnum)) ' Cued Day 04']));
%         
%         Cued_day_4_day = find(~cellfun(@isempty,Cued_day_4_test),1);
%         
%         Cued_day_4_all_mice(:,NBM_BLAnum) = day_align(:,Cued_day_4_day);
%         
%         
% %         %TO_day_01
% %         
% %         TO_day_01_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(NBM_BLAnum)) ' Timeout Day 01']));
% %         
% %         TO_day_01_day = find(~cellfun(@isempty,TO_day_01_test),1);
% %         
% %         TO_day_01_day_all_mice(:,NBM_BLAnum) = day_align(:,TO_day_01_day);
% %         
%         
%           %TO_day_03
%         
%         TO_day_03_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(NBM_BLAnum)) ' Timeout Day 03']));
%         
%         TO_day_03_day = find(~cellfun(@isempty,TO_day_03_test),1);
%         
%         TO_day_03_day_all_mice(:,NBM_BLAnum) = day_align(:,TO_day_03_day);
%         
% %         %    TO_10_rew
% %         
% %         TO_10_rew_test = strfind(lower(day_align_filenames),lower(TO_10_rew(NBM_BLAnum)));
% %         
% %         TO_10_rew_day = find(~cellfun(@isempty,TO_10_rew_test),1);
% %         
% %         TO_10_rew_day_all_mice(:,NBM_BLAnum) = day_align(:,TO_10_rew_day);
%         
% %         
% %         %    TO_day_06
% %         
% %         TO_day_06_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(NBM_BLAnum)) ' Timeout Day 06']));
% %         
% %         TO_day_06_day = find(~cellfun(@isempty,TO_day_06_test),1);
% %         
% %         TO_day_06_day_all_mice(:,NBM_BLAnum) = day_align(:,TO_day_06_day);
% %         
% %         % TO_day_15
% %         
% %         TO_day_15_test = strfind(lower(day_align_filenames),lower([num2str(BLA_GACh(NBM_BLAnum)) '_Timeout_Day_15']));
% %         
% %         TO_day_15_day = find(~cellfun(@isempty,TO_day_15_test),1);
% %         
% %         TO_day_15_day_all_mice(:,NBM_BLAnum) = day_align(:,TO_day_15_day);
%         
%         %Last_TO
%         %simpler than other bc I found last TO day above
%         TO_Last_day_all_mice(:,NBM_BLAnum) = day_align(:,TO_Last_day);
%         
%       
%     elseif any(mouse_ID == camkii_gcamp)
%         
%        rew_thresh_test = strfind(day_align_filenames,rew_threshold(CaMKIInum));
%         
%         rew_thresh_day = find(~cellfun(@isempty,rew_thresh_test),1);
%         
%         rew_thresh_all_mice(:,CaMKIInum) = day_align(:,rew_thresh_day );
%         
%         %% For collapsing mice
%         
%         %    Cued_day_1
%         Cued_day_1_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(CaMKIInum)) ' Cued Day 01']));
%         
%         Cued_day_1_day = find(~cellfun(@isempty,Cued_day_1_test),1);
%         
%         Cued_day_1_all_mice(:,CaMKIInum) = day_align(:,Cued_day_1_day);
%         
%         %    Cued_day_5
%         Cued_day_4_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(CaMKIInum)) ' Cued Day 04']));
%         
%         Cued_day_4_day = find(~cellfun(@isempty,Cued_day_4_test),1);
%         
%         Cued_day_4_all_mice(:,CaMKIInum) = day_align(:,Cued_day_4_day);
%         
%         
% %         %TO_day_01
% %         
% %         TO_day_01_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(CaMKIInum)) ' Timeout Day 01']));
% %         
% %         TO_day_01_day = find(~cellfun(@isempty,TO_day_01_test),1);
% %         
% %         TO_day_01_day_all_mice(:,CaMKIInum) = day_align(:,TO_day_01_day);
% %         
%         
%           %TO_day_03
%         
%         TO_day_03_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(CaMKIInum)) ' Timeout Day 03']));
%         
%         TO_day_03_day = find(~cellfun(@isempty,TO_day_03_test),1);
%         
%         TO_day_03_day_all_mice(:,CaMKIInum) = day_align(:,TO_day_03_day);
%         
% %         %    TO_10_rew
% %         
% %         TO_10_rew_test = strfind(lower(day_align_filenames),lower(TO_10_rew(CaMKIInum)));
% %         
% %         TO_10_rew_day = find(~cellfun(@isempty,TO_10_rew_test),1);
% %         
% %         TO_10_rew_day_all_mice(:,CaMKIInum) = day_align(:,TO_10_rew_day);
%         
% %         
% %         %    TO_day_06
% %         
% %         TO_day_06_test = strfind(lower(day_align_filenames),lower([num2str(NBM_BLA(CaMKIInum)) ' Timeout Day 06']));
% %         
% %         TO_day_06_day = find(~cellfun(@isempty,TO_day_06_test),1);
% %         
% %         TO_day_06_day_all_mice(:,CaMKIInum) = day_align(:,TO_day_06_day);
% %         
% %         % TO_day_15
% %         
% %         TO_day_15_test = strfind(lower(day_align_filenames),lower([num2str(BLA_GACh(CaMKIInum)) '_Timeout_Day_15']));
% %         
% %         TO_day_15_day = find(~cellfun(@isempty,TO_day_15_test),1);
% %         
% %         TO_day_15_day_all_mice(:,CaMKIInum) = day_align(:,TO_day_15_day);
%         
%         %Last_TO
%         %simpler than other bc I found last TO day above
%         TO_Last_day_all_mice(:,CaMKIInum) = day_align(:,TO_Last_day);
%         
%         
%     end


    %% Plot and save
    
     figure
%     figure('Visible', 'off')
    cf = imagesc(day_align', climits); % not using the actual time since the number
    
    colormap jet
    nanmap = [0 0 0; colormap];
    colormap(nanmap);
    
    
    
    %beforetoneticks includes tone tick
    beforetoneticks = 1+(610/5)*[1 3 5];
    
    
    %latency ticks
    lat_tick = 611 + half_lat + divider/2;
    
    %poke_tick
    poke_tick = 611 + half_lat + divider + half_lat + 1;
    
    %rew_lat_ticks
    rew_lat_tick = 611 + half_lat + divider + half_lat + 1 + half_rew_lat + divider/2;
    
    rec_tick = 611 + half_lat + divider + half_lat + 1 + half_rew_lat + divider + half_rew_lat + 1;
    
    %may needto play around with this
    afterrecticks = size(aligntogether,1)-(122*[3 1]-1);
    
    
    ax = gca;
    
    %too crowded with 0.5/-.5
    %     ax.XTick = [beforetoneticks lat_tick poke_tick rew_lat_tick rec_tick afterrecticks];
    %     ax.XTickLabel = { '-4', '-2',  'Tone', '2 / -2', 'NP','0.5/-.5' ,'Rec', '2',  '4'};
    
    ax.XTick = [beforetoneticks lat_tick poke_tick rec_tick afterrecticks];
    ax.XTickLabel = { '-4', '-2',  'Tone', '2 / -2', 'NP','Rec', '2',  '4'};
    ax.TickDir = 'out';
    ax.XAxis.TickLength = [0.02 0.01];
    ax.XAxis.LineWidth = 1.75;
    
    %TO and Ext change based on when the different phases happened
    %lines to draw/label
        %use this for the interim, add in Ext as we get there and remove
        %ticks and labels later when wanting to publish
    
        %add y ticks and labels, just sep phases
%         ax.YTick = [0.5 TO-0.5];
%         yline(TO-0.5, 'LineWidth', 1.75);
%         ax.YTickLabel = {'Cued', 'TO'};
        
    %add y ticks/labels for just the day
%        ax.YTick = 1:size(day_label,1);
%        ax.YTickLabel = day_label;
%        yline(TO-0.5, 'LineWidth', 1.75);
%        
%        if ~isempty(Ext)
%            yline(Ext-0.5, 'LineWidth', 1.75);
%        end
%        
        
        
        

        %         ax.YTick = [0.5 TO-0.5 rew_thresh_day - 0.5  Ext-0.5];
        yline(TO-0.5, 'LineWidth', 1.75);
        if ~isempty(Ext)
            yline(Ext-0.5, 'LineWidth', 1.75);
        end
        
%         if ~isempty(rew_thresh_day)
%             yline(rew_thresh_day - 0.5 , 'w', 'LineWidth', 1.75);
%         end
%                 ax.YTickLabel = {'Cued', 'TO', 'Acq.','Ext.'};
        
        %lines to draw/label for non-BLA_GACh

    
    set(gca,'YDir','normal')
    
    %remove yticks and yticklabels
    set(gca,'ytick',[])
    set(gca,'yticklabel',[])
    
%     title([indicator ' ' num2str(mouse_ID)],'fontsize',16)
%     ylabel('Training Phase','fontsize',16)
%     xlabel('Seconds','fontsize',16)
    cb = colorbar;
    ylabel(cb, 'Z %\DeltaF/F0' ,'fontsize',16)
    
    
    
    
    
    %Print png version of graph (save)
    print([outputfolder '\' indicator ' ' num2str(mouse_ID) ' Tone_NP_Rec'], '-dtiff', '-r300');
    
    %zoom in
    %     xlim([beforetoneticks(2) afterrecticks(1)])
    %     print([outputfolder '\2 secs\' num2str(mouse_ID) ' ' indicator ' Tone_NP_Rec'], '-dpng');
    %
    
    clear day_align day_align_sem day_align_filenames day_label
    
    
    
    
    %         close figures
    close all
    
    
end


%% plot collapsed 

% if any(mouse_ID == BLA_GACh)
    
%     %% Plot collapsed across mice (expanded collapse days)
%     
%     
% %     climits = [-2 6];
%     
%     mean_Cued_day_1 = nanmean(Cued_day_1_all_mice,2);
%     mean_Cued_day_4 = nanmean(Cued_day_4_all_mice,2);
%     mean_TO_day_03 = nanmean(TO_day_03_day_all_mice,2);
% %     mean_TO_10 = nanmean(TO_10_rew_day_all_mice,2);
%     mean_TO_day_06 = nanmean(TO_day_06_day_all_mice,2);
% %     mean_TO_day_15 = nanmean(TO_day_15_day_all_mice,2);
%     mean_rew_thresh = nanmean(rew_thresh_all_mice,2);
%     mean_TO_Last = nanmean(TO_Last_day_all_mice,2);
%     
%     %spaced out a lot in this vector to make it easier to see separation
%     mean_all_days = [mean_Cued_day_1    mean_Cued_day_4     mean_TO_day_03   mean_TO_day_06   mean_rew_thresh     mean_TO_Last];
%     
%     figure
%     cf = imagesc(mean_all_days', climits); % not using the actual time since the number
%     
%     colormap jet
%     nanmap = [0 0 0; colormap];
%     colormap(nanmap);
%     
%     
%     ax = gca;
%     ax.XTick = [beforetoneticks lat_tick poke_tick rec_tick afterrecticks];
%     ax.XTickLabel = { '-4', '-2',  'Tone', '2 / -2', 'NP','Rec', '2',  '4'};
%     ax.TickDir = 'out';
%     ax.XAxis.TickLength = [0.02 0.01];
%     ax.XAxis.LineWidth = 1.75;
%     
%     %TO and Ext change based on when the different phases happened
%     %     ax.YTick = [1:8];
%     %     ax.YTickLabel = {'Cued 1','Cued 5', 'TO 3', '10 Rew*', 'TO 13', 'TO 15', 'Acq*', 'Last TO'};
%     
%     set(gca,'YDir','normal') % put the trial numbers in order from bot to top on y-axis
%     
%     %remove yticks and yticklabels
%     set(gca,'ytick',[])
%     set(gca,'yticklabel',[])
%     
%     
%     yline(3-0.5, 'LineWidth', 1.75);
%     yline(5 - 0.5 , 'w', 'LineWidth', 1.75);
%     
%     
%     %     title(indicator ,'fontsize',16)
%     %     ylabel('Training Phase','fontsize',16)
%     %     xlabel('Seconds','fontsize',16)
%     cb = colorbar;
%     ylabel(cb, 'Z %\DeltaF/F0' ,'fontsize',16)
%     
%     %Print png version of graph (save)
%     print([outputfolder '\Collapsed+ ' indicator ' Tone_NP_Rec'], '-dpng');
%     
    %zoom in
    %     xlim([beforetoneticks(2) afterrecticks(1)])
    %     print([outputfolder '\2 secs\Collapsed+ ' indicator ' Tone_NP_Rec'], '-dpng');
    
    
%     
% elseif any(mouse_ID == BLA_GCaMP)
%     %% Plot collapsed across mice (expanded collapse days)
%     
%     
%     
%     climits = [-1.5 3.5];
%     
%     mean_Cued_day_1 = nanmean(Cued_day_1_all_mice,2);
%     mean_Cued_day_4 = nanmean(Cued_day_4_all_mice,2);
%     mean_TO_day_03 = nanmean(TO_day_03_day_all_mice,2);
%     mean_rew_thresh = nanmean(rew_thresh_all_mice,2);
%     
%     %spaced out a lot in this vector to make it easier to see separation
%     mean_all_days = [mean_Cued_day_1    mean_Cued_day_4     mean_TO_day_03 mean_rew_thresh];
%     
%     figure
%     cf = imagesc(mean_all_days', climits); % not using the actual time since the number
%     
%     colormap jet
%     nanmap = [0 0 0; colormap];
%     colormap(nanmap);
%     
%     
%     ax = gca;
%     ax.XTick = [beforetoneticks lat_tick poke_tick rec_tick afterrecticks];
%     ax.XTickLabel = { '-4', '-2',  'Tone', '2 / -2', 'NP','Rec', '2',  '4'};
%     ax.TickDir = 'out';
%     ax.XAxis.TickLength = [0.02 0.01];
%     ax.XAxis.LineWidth = 1.75;
%     
%     %TO and Ext change based on when the different phases happened
%     %     ax.YTick = [1:8];
%     %     ax.YTickLabel = {'Cued 1','Cued 5', 'TO 3', '10 Rew*', 'TO 13', 'TO 15', 'Acq*', 'Last TO'};
%     
%     set(gca,'YDir','normal') % put the trial numbers in order from bot to top on y-axis
%     
%     %remove yticks and yticklabels
%     set(gca,'ytick',[])
%     set(gca,'yticklabel',[])
%     
%     
%     yline(3-0.5, 'LineWidth', 1.75);
%     yline(4 - 0.5 , 'w', 'LineWidth', 1.75);
%     
%     
%     %     title(indicator ,'fontsize',16)
%     %     ylabel('Training Phase','fontsize',16)
%     %     xlabel('Seconds','fontsize',16)
%     cb = colorbar;
%     ylabel(cb, 'Z %\DeltaF/F0' ,'fontsize',16)
%     
%     %Print png version of graph (save)
%     print([outputfolder '\Collapsed+ ' indicator ' Tone_NP_Rec'], '-dpng');
%     
%     %zoom in
%     %     xlim([beforetoneticks(2) afterrecticks(1)])
%     %     print([outputfolder '\2 secs\Collapsed+ ' indicator ' Tone_NP_Rec'], '-dpng');
%     
%     
%     
%     
%     
% end




%% Print code version text file


%print the version of the code used
fileID = fopen([outputfolder '\' date 'codeused.txt'],'w');
fprintf(fileID, codename);

close all