%% FP_Compile_2020_04_v1
%To Do: Need to modify the way this code runs to not be so taxing on
%memory. If there's enough files, it crashes. Make it loop through reading
%each file independently 


%v1: modified for 2020-04
    %improved medraw sort to also sort by date

%2019-14 notes
%NOTE: currently running everything with uncorrected signal dff, not
%subtracting out reference due to issues with the new rig

%v3: incorporating RCaMP into plotting individual and grabbing rcamp col
%and putting it into rawtogether

%v2: removed double tapped inactives, other minor things

%Built from Hannah_Rufina_FP_v1
    %built from partially completed Rufina_2019_06_FP_v4

%change exp variable to desired experiment to run a the version of it 


clear;

exp = '2020-04';

codename = 'FP_Compile_2020_04_v1';
load(getPipelineVarsFilename);

%Real folders/files
folder = FP_PROC_DIRECTORY ;


outputfolder = FP_COMPILE_DIRECTORY;
outputfile = [exp ' App MATLAB Output'];

%Pull uncorrected DF/F0
dff0_ref = 'Reference (DF/F0)';
dff0 = 'Ca2+ Signal (DF/F0)';

medpcfile = FP_MEDPC_FILE;
timestampfolder = FP_OUTPUT_DIRECTORY;

MDIR_DIRECTORY_NAME = outputfolder;
make_directory; 

MDIR_DIRECTORY_NAME = FP_MATLAB_VARS;
make_directory;

%% MATLAB var saving options 
%save just rawtogether and names daily
save_name = FP_MATLAB_VARS_FILENAME;

%save just rawtogether and names if doing all at once
% save_name = 'current_rawtogether_filenames';


%% Set the variable letters that you're pulling
%Correct = B, Inactive = D, Receptacle = G, Reward = H, Tone on = K
%Tone off = L, Incorrect = R, Intervals used = S
variable_letters = ["B(" , "D(" , "G(" , "H(" , "K(" , "L(" , "R(" , "S("];


%% Import Doric

%Auto Import Data
C = dir([folder, '\*.csv']);
filenames = {C(:).name}.';

%exclude any temp files
filenames = filenames(~startsWith(filenames,'~'));

raw = cell(length(filenames),1);

%Note: this may cause errors, pulling wrong row, if there's an excluded temp
%file not at the end
for ii = 1:length(filenames)
    % Create the full file name and partial filename
    fullname = [folder '\' C(ii).name];
    
    % Read in the data (headers included b/c the
    raw{ii,1} = filenames(ii);
    raw{ii,2} = readcell(fullname);
end

%add file names to data's first col
data = raw(:,1);


%Cycle through each row (session/day)
for row = 1:length(raw)
    
    
    %Cycle through each column/row (without grabbing headers)
    for column = 1:size(raw{row,2},2)
        
        %Grab Time col
        if strcmp(raw{row,2}{1,column}, 'Time')
            data{row,2}(:,1) = raw{row,2}(2:end,column);
        end
        
        %Grab dF/F col
        if ~COMPILE_WITH_REF && strcmp(raw{row,2}{1,column}, dff0)
            data{row,2}(:,2) = raw{row,2}(2:end,column);
        end
        
        if COMPILE_WITH_REF && strcmp(raw{row,2}{1,column}, dff0_ref)
            data{row,2}(:,2) = raw{row,2}(2:end,column);
        end
        
        %Grab Digital input col
        if strcmp(raw{row,2}{1,column}, 'DIO')
            data{row,2}(:,3) = raw{row,2}(2:end,column);
        end
        
           %Grab RCaMP
        if strcmp(raw{row,2}{1,column}, 'DF/F0 RCaMP')
            data{row,2}(:,4) = raw{row,2}(2:end,column);
        end
        
    end
    
end

clear raw

%copy current data into col 3 so the df/f0 there can be overwritten with
%zdf/f0
data(:,3) = data(:,2);

%clear out data{:,2} since it's been copied to data{:,3} for zscoring
%did this to speed up code. Remove this if you need to spot check data
for row = 1:size(data,1)
    data{row,2} = [];
end


%% Read in MedPC Data
%Don't have to iterate this bc everything is the the excel file
%% Import the data
medrawpresort = readcell(medpcfile);
%only imported Cued and CuedTO

%cut off column headings and sort by animal ID, ascending order, use date
%(col 2) for multiple days of same animal
medheadsum = medrawpresort(1,1:16);
medheader = medrawpresort(1,:);
medrawpresort = medrawpresort(2:end,:);

%sort by animal (col 1) and for tie breakers, sort by the date (col 2)   
[~,sortidx] = sortrows(cell2mat(medrawpresort(:,[1 2])), [1 2]);
    
medraw = medrawpresort(sortidx,:);
clear medrawpresort;

%cycle through each mouse
for row = 1:size(medraw,1)
    
    meddata = cell(1,8);
    
    for variable=1:8
        %% Pull the variables from raw into their own rows of cell raw1
        %Find all the days that are the given variable
        array_header = strfind(medheader,variable_letters{variable});
        
        %find the first non-empty cell and set that index to TO
        first = find(~cellfun(@isempty,array_header),1);
        last = find(~cellfun(@isempty,array_header),1, 'last');
        
        raw1 = medraw(row,first:last);
        
        raw1(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw1)) = {''};
        
        %Replace non-numeric cells with NaN
        R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw1); % Find non-numeric cells
        raw1(R) = {NaN}; % Replace non-numeric cells
        
        %Create output variable
        meddata{1,variable}= reshape([raw1{:}],size(raw1));
        
        
        medsum=medraw(row,1:16);
        
        
        %% Clear temporary variables
        clearvars raw1 R ;
        
    end
    
    
    
    
    %% Calculate latency (cue on to Reward(First Proper NP of trial), col 9) and training day mean latency (col 10), and concat to data. Row = training day
    
    %Changed ProperANP to rewards from previous version because ProperANPs now
    %colllect any extra Proper ANPs made (within the 2 sec the tone can still play after the first), not just first one
    
    %this next line should be the size of meddata,
    %
    latency = cell(size(meddata,1),2);
    %probably don't need this loop since it's just 1 row per file. If
    %was looping like before (within a mouse) it'd matter
    for datarow=1:size(meddata,1)
        
        
        for Reward=1:size(meddata{datarow,4},2)
            toneid = find(meddata{datarow,4}(Reward)>meddata{datarow,5},1, 'last');
            if meddata{datarow,4}(Reward) - meddata{datarow,5}(toneid) <= 10
                latency{datarow,1}(Reward) = meddata{datarow,4}(Reward)- meddata{datarow,5}(toneid);
            end
            
        end
        %average latency
        latency{datarow,2} = cellfun(@mean,latency(datarow));
    end
    
    
    %add latency to data cell
    meddata = [meddata latency];
    
    clear datarow toneid Reward latency
    
    %% Reward latency
    rewlatency = cell(size(meddata,1),2);
    
    %probably don't need this loop since it's just 1 row per file. If
    %was looping like before (within a mouse) it'd matter
    for datarow=1:size(meddata,1)
        
        
        for Reward=1:size(meddata{datarow,4},2)
            
            recepidx = find(meddata{datarow,4}(Reward)<meddata{datarow,3},1);
            if meddata{datarow,3}(recepidx)-meddata{datarow,4}(Reward)<10
                rewlatency{datarow,1}(Reward) = meddata{datarow,3}(recepidx) - meddata{datarow,4}(Reward);
            end
        end
        
        %calculate mean of all rewlatencies
        rewlatency{datarow,2} = cellfun(@mean,rewlatency(datarow));
        
        
    end
    
    %add latency to data cell
    meddata = [meddata rewlatency];
    
    clear datarow  recepidx  Reward rewlatency
    %% Add medsum, meddata (including latencies) to overall data
    %Need to make this add to data row instead
    
    
    %medheader and med sum
    medsum = {[medheadsum;medsum]};
    
    %add med sum and meddata to data cell
    data{row,4} = [medsum meddata];
    
    
    %% clear
    clear meddata variable
    
end

%clear for memory
clear raw_mouse medraw

%% Loop through all data files
%scrub, add timestamp latency, zscore
for file = 1:size(data,1)
    
    
    %% Scrub weird spikes
    %turn weird spikes to NaN
    for datarow=1:size(data{file,3},1)
        if data{file,3}{datarow,2} < -99 || data{file,3}{datarow,2} > 99
            data{file,3}{datarow,2} = NaN;
        end
    end
    
    %if there's an RCaMP col, scrub
    if size(data{file,3},2) > 3
        for datarow=1:size(data{file,3},1)
            if data{file,3}{datarow,4} < -99 || data{file,3}{datarow,4} > 99
                data{file,3}{datarow,4} = NaN;
            end
        end
    end
    
    %% Make zscore cell entry (file,3)
    dffcolumn = cell2mat(data{file,3}(:,2));
    zdff = nanzscore(dffcolumn);
    data{file,3}(:,2) = num2cell(zdff);
    
    %calc zscore for rcamp, but don't add it to 
    if size(data{file,3},2) > 3
        r_dffcolumn = cell2mat(data{file,3}(:,4));
        r_zdff = nanzscore(r_dffcolumn);
        data{file,3}(:,4) = num2cell(r_zdff); 
    end
    
    %% Trim to startpulse
    
    %transfer zscored data cell (w/o latency) to tempdata as matrix
    clear tempdata
    tempdata = cell2mat(data{file,3}(:,1:3));
    
    %put rcamp into col 5 of tempdata, need to insert 
    if size(data{file,3},2) > 3
        tempdata(:,5) = cell2mat(data{file,3}(:,4));
    end
    
    %find the start pulse (first 0 in DIO), align t = 0 to that, and trim
    %tempdata to remove pre-start pulse rows
    starttimeindex = find(tempdata(:,3)<1,1,'first');
    starttime = tempdata(starttimeindex,1);
    tempdata(:,1) = tempdata(:,1)-starttime;
    tempdata = tempdata(starttimeindex:end,:);

    %% Identify actions, put them in col 4 of tempdata, put tempdata into col 5 of data
    
    %add NaN to col 4 (inserting directly into col 4 instead of cat to
    %allow for RCaMP being in 5th col in some mice
    blankcol = NaN(size(tempdata,1),1);
    tempdata(:,4) = blankcol;
    
    %action = place in summary cell | place in timestamp col| action ID
    %correct = 9 | 2 | 1
    %extracorrect = 9 | 2 | 5
    %tone = 14 | 6| 2
    %incorrect = 10 | 8 |  3
    %incorrect not leading to TO (within 5 sec of another incorrect) = 7
    %receptacle 13 | 4| 4
    %   extra rec = 8
    %   rand rec = 9
    %inactive 11 | 3 |  6
    %   extra inactive = 10
    
    %medactiontimecol = column in data{file,4} for given action
    %note, these are +1 what they were assigned earlier bc sum col is first
    medactiontimecol = [2 6 8 4 3];
    
    %index in summary to reference, to get number of actions
    medsumaction = [9 14 10 13 11];
    
    %key for actions
    aidkey = [1 2 3 4 6];
    
    %assign ID for actions
    for variable = 1:5
        for action = 1:data{file,4}{1,1}{2,medsumaction(variable)}
            timestamp = data{file,4}{1,medactiontimecol(variable)}(action);
            
            %find index of closest timestamp
            [~,doricind] = min(abs(tempdata(:,1)-timestamp));
            
            %add aidkey to column 4
            tempdata(doricind,4) = aidkey(variable);
            
            %Change a doubletapped correct to extra correct
            if aidkey(variable) == 1
                [~,testextraind] = min(abs(tempdata(:,1)-(timestamp-2.3)));
                
                if  any(tempdata(testextraind:doricind-1,4)==1)
                    tempdata(doricind,4) = 5;
                end
            end
            
            %Change a non-TO yielding incorrect to 7
            if aidkey(variable) == 3
                [~,testextraimp] = min(abs(tempdata(:,1)-(timestamp-5.08)));
                
                if  any(tempdata(testextraimp:doricind-1,4)==3)
                    tempdata(doricind,4) = 7;
                end
            end
            
            %Weeding out close together rec entries. Not sure how stringent I should be but
            %I'll do the same as incorrect (none 5 sec before) just to be
            %sure. Extra rec = 8
            
            %also going to divide by rec that follows a reward and those
            %that are random = 9
            if aidkey(variable) == 4
                [~,testextrarec] = min(abs(tempdata(:,1)-(timestamp-5.08)));
                
                if  any(tempdata(testextrarec:doricind-1,4)==4) || any(tempdata(testextrarec:doricind-1,4)==9)
                    tempdata(doricind,4) = 8;
                    
                elseif ~any(tempdata(testextrarec:doricind-1,4)==1)
                    tempdata(doricind,4) = 9;  
                end
            end
            
            %Change extra inactives to 10
            if aidkey(variable) == 6
                [~,testextrainact] = min(abs(tempdata(:,1)-(timestamp-5.08)));
                
                if  any(tempdata(testextrainact:doricind-1,4)==6)
                    tempdata(doricind,4) = 10;
                end
            end
            
            
        end
    end
    
    
    %put tempdata into data
    data{file,5} = tempdata;
    
    %clear zscore col bc no longer needed after data{file,5} made
    data{file,3} = [];
     
end

clear tempdata
%% Search through action number column and constuct arrays with zdF/F0

%action = place in summary cell | place in timestamp col| action ID
%correct =  1
%extracorrect = 5
%tone = 2
%incorrect = 3
%incorrect not leading to TO (within 5 sec of another incorrect) = 7
%receptacle = 4
%rand rec = 9
%inactive = 6


%create a variable to let me know how many actions were cut off due to
%different restrictions such as not enough time, etc

%initialize rawtogether
rawtogether = cell(size(data,1),2);

cut_short = [" ";];

for file = 1:size(data,1)
    
    %this file was cut short
    if any(strcmpi(filenames{file},cut_short))
        cutoff = 1745;
    else
        cutoff = 1789.5;
    end
    
    
    
    %preallocate arrays and counters
    correct = zeros(1832,0);
    correctcounter = 0;
    
    tone = zeros(1832,0);
    tonecounter = 0;
    tonehit = zeros(1832,0);
    tonehitcounter =0;
    tonemiss = zeros(1832,0);
    tonemisscounter =0;
    
    incorrect = zeros(1832,0);
    incorrectcounter = 0;
    
    receptacle = zeros(1832,0);
    receptaclecounter = 0;
    
    randrec = zeros(1832,0);
    randreccounter = 0;
    
    
    inactive = zeros(1832,0);
    inactivecounter = 0;
    
    %for rcamp, no counters bc using regular ones for counters
    if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
        r_correct = zeros(1832,0);
      
        r_tone = zeros(1832,0);
        
        r_tonehit = zeros(1832,0);
        
        r_tonemiss = zeros(1832,0);
           
        r_incorrect = zeros(1832,0);
        
        r_receptacle = zeros(1832,0);
        
        r_randrec = zeros(1832,0);

        r_inactive = zeros(1832,0);
    end
    
    
    %rawtogether is where I'm pulling everything from 5 sec before tone to 5
    %sec after rec (or after NP if rec entry didn't happen within 5 sec
    %after NP)

    %latency arrays
    ttp_list = zeros(0);
    ptr_list = zeros(0);

    %find all of the inidices of actions (not NaNs in aid cols)
    [actionind] = find(~isnan(data{file,5}(:,4)));
    
    %added if statements to pull rcamp if 849 or 850. copied it for pulling
    %df/f0 col but using r_ vars and pulling col 5 instead
    
    
    %go through all actions in a given file
    for action=1:size(actionind,1)
        
        %make sure the the action isn't too close to start or end of
        %session
        if data{file,5}(actionind(action),1) > 5.1 && data{file,5}(actionind(action),1) <  cutoff
            
            %correct (reward delivery prop only)
            if data{file,5}(actionind(action),4) == 1
                correctcounter = correctcounter +1;
                correct(1:end,correctcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %rcamp
                if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                    r_correct(1:end,correctcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,5);
                end
                
                %rawtogether
                
                %find the tone that came before this correct NP
                lasttone = find(data{file,5}(1:actionind(action),4)==2, 1,'last');
                
                %find the rec that came immediately after this correct NP
                nextrec = find(data{file,5}(actionind(action):end,4)==4, 1,'first')+actionind(action)-1;
                
                if data{file,5}(nextrec,1) - data{file,5}(actionind(action),1) <= 5.008 %change from 5.08 to 5.008
                    %if there's a rec after correct np within 5 sec, take 5 sec
                    %after that
                    
                    %if rcamp mouse, grab col 5 too
                    if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                        %grab tone - 5 sec : rec + 5 sec
                        rawtogether{file,1}{1,correctcounter} = data{file,5}(lasttone-610:nextrec+610,[1 2 4 5]);
                        
                        %grab just tone - 5 sec : poke + 5 sec
                        rawtogether{file,1}{2,correctcounter} = data{file,5}(lasttone-610:actionind(action)+610,[1 2 4 5]);
                        
                        %grab latency from tone to poke
                        rawtogether{file,1}{3,correctcounter} = rawtogether{file,1}{2,correctcounter}(end-610,1)-rawtogether{file,1}{2,correctcounter}(611,1);
                        
                        %grab rew latency (poke to rec entry)
                        rawtogether{file,1}{4,correctcounter} = data{file,5}(nextrec,1) - data{file,5}(actionind(action),1);

                    %if not rcamp mouse, grab as before
                    else
                       %grab tone - 5 sec : rec + 5 sec
                        rawtogether{file,1}{1,correctcounter} = data{file,5}(lasttone-610:nextrec+610,[1 2 4]);
                        
                        %grab just tone - 5 sec : poke + 5 sec
                        rawtogether{file,1}{2,correctcounter} = data{file,5}(lasttone-610:actionind(action)+610,[1 2 4]);
                        
                        %grab latency from tone to poke
                        rawtogether{file,1}{3,correctcounter} = rawtogether{file,1}{2,correctcounter}(end-610,1)-rawtogether{file,1}{2,correctcounter}(611,1);
                        
                        %grab rew latency (poke to rec entry)
                        rawtogether{file,1}{4,correctcounter} = data{file,5}(nextrec,1) - data{file,5}(actionind(action),1);
                        
                        %if there was no rec entry 5 sec after correct, don't take the
                        %event
                        %note: this means that there will be an empty
                        %column for those rewards that don't meet this
                        %requirement
                        
                    end
                    
                end
                
                %tone
            elseif data{file,5}(actionind(action),4) == 2
                %fancy way to do it is here, but just doing 10 sec by 1221+2 extra cells jic
                %[~,plus10ind] = min(abs(data{file,5}(actionind(action):end,1)-(data{file,5}(actionind(action),1)+10)));
                tonecounter = tonecounter +1;
                tone(1:end, tonecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %rcamp
                if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                    r_tone(1:end, tonecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,5);
                end
                
                %tonehit
                if any(ismember(data{file,5}(actionind(action):actionind(action)+1223,4),1)) == 1
                    tonehitcounter = tonehitcounter +1;
                    tonehit(1:end, tonehitcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                    
                    %rcamp
                    if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                        r_tonehit(1:end, tonehitcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,5);
                    end
                    
                    %tonemiss
                else
                    tonemisscounter = tonemisscounter + 1;
                    tonemiss(1:end, tonemisscounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                    
                    %rcamp
                    if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                        r_tonemiss(1:end, tonemisscounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,5);
                    end
                    
                end
                
                
                %tone to correct latency
                %*come back to this
                
                %incorrect
            elseif data{file,5}(actionind(action),4) == 3
                incorrectcounter = incorrectcounter + 1;
                incorrect(1:end,incorrectcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %rcamp
                if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                    r_incorrect(1:end,incorrectcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,5);
                end
                
                %receptacle
            elseif data{file,5}(actionind(action),4) == 4
                receptaclecounter = receptaclecounter + 1;
                receptacle(1:end,receptaclecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %rcamp
                if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                    r_receptacle(1:end,receptaclecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,5);
                end
                
                %randrec (rec entry not following reward)
            elseif data{file,5}(actionind(action),4) == 9
                randreccounter = randreccounter + 1;
                randrec(1:end,randreccounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %rcamp
                if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                    r_randrec(1:end,randreccounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,5);
                end
                
                %inactive
            elseif data{file,5}(actionind(action),4) == 6
                inactivecounter = inactivecounter + 1;
                inactive(1:end,inactivecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %rcamp
                if str2num(data{file,1}{1}(11:14)) == 849 || str2num(data{file,1}{1}(11:14)) == 850
                    r_inactive(1:end,inactivecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,5);
                end
                
            end
            
            
        else
            %cutoff variable
            
        end
    end
    
    %action counter
    actioncounter = {'correct' 'tone' 'incorrect' 'receptacle' 'randrec' 'tonehit' 'tonemiss' 'inactive'; ...
        correctcounter tonecounter incorrectcounter receptaclecounter randreccounter tonehitcounter tonemisscounter inactivecounter};
    
    %only take means if not an empty cell
    if ~cellfun(@isempty,rawtogether(file,1))
        rawtogether{file,2} = mean(cell2mat(rawtogether{file,1}(3,:)));
        rawtogether{file,3} = mean(cell2mat(rawtogether{file,1}(4,:)));
    end
    
    %write all the zdffdata into an excel sheet for an individual day, assign
    %% Write the tempdata
    %this is the way data was written out when wanting to align to
    %inidividual actions. Now also adding a variable "together"
    outputname = [outputfolder '\MATLAB_' data{file,1}{1}(11:end-6) '.xlsx'];
    
    %     Comment since don't need outputs right now
    
    writecell(actioncounter, outputname, 'Sheet', 'counter');
    
    %if rcamp mouse, write both vars together to save time 
    if str2double(data{file,1}{1}(11:14)) == 849 || str2double(data{file,1}{1}(11:14)) == 850
        
        if correctcounter ~= 0
            writematrix(correct, outputname, 'Sheet', 'correct');
            writematrix(r_correct, outputname, 'Sheet', 'r_correct');
        end
        
        if tonecounter ~= 0
            writematrix(tone, outputname, 'Sheet', 'tone');
            writematrix(r_tone, outputname, 'Sheet', 'r_tone');
        end
        
        if incorrectcounter ~= 0
            writematrix(incorrect, outputname, 'Sheet', 'incorrect');
            writematrix(r_incorrect, outputname, 'Sheet', 'r_incorrect');
        end
        
        if receptaclecounter ~= 0
            writematrix(receptacle, outputname, 'Sheet', 'receptacle');
            writematrix(r_receptacle, outputname, 'Sheet', 'r_receptacle');
        end
        
        if randreccounter ~= 0
            writematrix(randrec, outputname, 'Sheet', 'randrec');
            writematrix(r_randrec, outputname, 'Sheet', 'r_randrec');
        end
        
        if tonehitcounter ~= 0
            writematrix(tonehit, outputname, 'Sheet', 'tonehit');
            writematrix(r_tonehit, outputname, 'Sheet', 'r_tonehit');
        end
        
        if tonemisscounter ~= 0
            writematrix(tonemiss, outputname, 'Sheet', 'tonemiss');
            writematrix(r_tonemiss, outputname, 'Sheet', 'r_tonemiss');
        end
        
        if inactivecounter ~= 0
            writematrix(inactive, outputname, 'Sheet', 'inactive');
            writematrix(r_inactive, outputname, 'Sheet', 'r_inactive');
        end
 
    else %if not rcamp mouse
        
        if correctcounter ~= 0
            writematrix(correct, outputname, "Sheet", 'correct');
        end
        
        if tonecounter ~= 0
            writematrix(tone, outputname, "Sheet", 'tone');
        end
        
        if incorrectcounter ~= 0
            writematrix( incorrect, outputname, "Sheet",'incorrect');
        end
        
        if receptaclecounter ~= 0
            writematrix(receptacle,outputname, "Sheet",'receptacle');
        end
        
        if randreccounter ~= 0
            writematrix(randrec,outputname, "Sheet",'randrec');
        end
        
        if tonehitcounter ~= 0
            writematrix(tonehit,outputname, "Sheet",'tonehit');
        end
        
        if tonemisscounter ~= 0
            writematrix(tonemiss,outputname, "Sheet",'tonemiss');
        end
        
        if inactivecounter ~= 0
            writematrix(inactive,outputname, "Sheet",'inactive');
        end
    end
end

%% Timestamp file
%added from Hannah 2018-07 (shou
%make a timestamp file from the first file's first correct nosepoke
file = 1;

%find the ind of the first correct np
[timeind] = find(data{file,5}(:,4)==1,1,'first');

%correct (reward delivery prop only)

timestampfile = data{file,5}(timeind-610:timeind+1221,1)-data{file,5}(timeind,1);


writematrix(timestampfile, FP_TIMESTAMP_FILE)




%% Save data in file

%save here, edit what you save up top to prevent scrolling a ton
save(FP_MATLAB_VARS_FILENAME, 'rawtogether', 'filenames', '-v7.3');

%% Print code version text file


%print the version of the code used
fileID = fopen([outputfolder '\' date 'codeused.txt'],'w');
fprintf(fileID, [codename ' ' dff0]);

