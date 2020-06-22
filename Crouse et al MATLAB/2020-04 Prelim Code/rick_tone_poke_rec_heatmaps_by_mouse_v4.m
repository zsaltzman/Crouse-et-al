%% rick_tone_to_poke_heatmaps_by_mouse_plots_v3
%for use with 2020-04 Code


%v2: changing labeling+numbering for publication. Also changing colormap to jet


%built from rick_tone_to_poke_heatmaps_by_mouse_plots_v2.ish
%v3: adding rec to make it tone_poke_rec_heatmaps_by_mouse
%v2: collapse across mice for select days based on behavior
%v1_1: add loading


clear;
load(getPipelineVarsFilename);

exp = '2020-04';
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
    
    load(FP_MATLAB_VARS_FILENAME);
    
    outputfolder = FP_SUMMARY_TP_DIRECTORY;
    outputfile = [exp ' App MATLAB tonetopoketorec heat by mouse data'];
    
    MDIR_DIRECTORY_NAME = outputfolder;
    make_directory; 
    
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
        
    elseif any(mouse_ID == NBM_BLA)
        indicator = 'NBM-BLA';
        climits = [-2 6];
      
        NBM_BLAnum=find(NBM_BLA==mouse_ID);
        
        
        
    end
    
    %trim data and filenames to just current mouse
    mousedata = rawtogether((data_mouse_ID(:,1) == mouse_ID),:);
    mousefiles = filenames((data_mouse_ID(:,1) == mouse_ID),:);
    
    %use day_counter to prevent black bar when skipping days
    day_counter = 0;
    
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
    
    Ext_test = strfind(day_align_filenames,'ZExtinction');
 
    %find the first non-empty cell and set that index to Ext
    Ext = find(~cellfun(@isempty,Ext_test),1);
    
    
%% No collapsed yet until make a better way to do this for each group


    %% Plot and save
    
    figure
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
    ax.XTick = [beforetoneticks lat_tick poke_tick rec_tick afterrecticks];
    ax.XTickLabel = { '-4', '-2',  'Tone', '2 / -2', 'NP','Rec', '2',  '4'};
    ax.TickDir = 'out';
    ax.XAxis.TickLength = [0.02 0.01];
    ax.XAxis.LineWidth = 1.75;
    
   
        

        %         ax.YTick = [0.5 TO-0.5 rew_thresh_day - 0.5  Ext-0.5];
        yline(TO-0.5, 'LineWidth', 1.75);
        if ~isempty(Ext)
            yline(Ext-0.5, 'LineWidth', 1.75);
        end
 
    set(gca,'YDir','normal')
    
    %remove yticks and yticklabels
    set(gca,'ytick',[])
    set(gca,'yticklabel',[])

    cb = colorbar;
    ylabel(cb, 'Z %\DeltaF/F0' ,'fontsize',16)
    
    
    
    
    
    %Print png version of graph (save)
    print([outputfolder '\' indicator ' ' num2str(mouse_ID) ' Tone_NP_Rec'], '-dtiff', '-r300');
   
    clear day_align day_align_sem day_align_filenames day_label
    
    
    
    
    %         close figures
    close all
    
    
end


%% plot collapsed 


%% Print code version text file


%print the version of the code used
fileID = fopen([outputfolder '\' date 'codeused.txt'],'w');
fprintf(fileID, codename);

close all