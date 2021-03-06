%% FP_Compile_2019_06_v1


clear;
load(getPipelineVarsFilename);

exp = '2019-06';
 
folder = FP_PROC_DIRECTORY;
outputfolder = FP_COMPILE_DIRECTORY;
outputfile = '2019-06 App MATLAB Output';
medpcfile = FP_MEDPC_FILE;

timestampfolder = FP_TIMESTAMP_FILE;

MDIR_DIRECTORY_NAME = outputfolder;
make_directory

MDIR_DIRECTORY_NAME = FP_MATLAB_VARS;
make_directory

codename = 'FP_Compile_2019_06_v1';

%set the variable letters that you're pulling
%Correct = B, Inactive = D, Receptacle = G, Reward = H, Tone on = K
%Tone off = L, Incorrect = R, Intervals used = S
variable_letters = ["B(" , "D(" , "G(" , "H(" , "K(" , "L(" , "R(" , "S("];


%Auto Import Data
C = dir([folder, '\*.csv']);
filenames = {C(:).name}.';
[ sorted_filenames, ~ ] = sort_nat(filenames);
raw = cell(length(C),1);


for ii = 1:length(C)
    % Create the full file name and partial filename
    fullname = [folder '\' sorted_filenames{ii}];
    
    % Read in the data (headers included b/c the
    raw{ii,1} = sorted_filenames(ii);
    raw{ii,2} = readcell(fullname);
end

%add file names to data's first col
data = raw(:,1);


%Cycle through each row (session/day)
for row = 1:size(raw,1)
    
    
    %Cycle through each column/row (without grabbing headers)
    for column = 1:size(raw{row,2},2)
        
        %Grab Time col
        if strcmp(raw{row,2}{1,column}, 'Time')
            data{row,2}(:,1) = raw{row,2}(2:end,column);
        end
        
        %Grab dF/F col
        if ~COMPILE_WITH_REF && strcmp(raw{row,2}{1,column}, 'Ca2+ Signal (DF/F0)')
            data{row,2}(:,2) = raw{row,2}(2:end,column);
        end
        
        if COMPILE_WITH_REF && strcmp(raw{row,2}{1,column}, 'Reference (DF/F0)')
            data{row,2}(:,2) = raw{row,2}(2:end,column);
        end
        
        %Grab Digital input col
        if strcmp(raw{row,2}{1,column}, 'DIO')
            data{row,2}(:,3) = raw{row,2}(2:end,column);
        end
        
    end
    
end

%clearing raw to free up memory
clear raw

%copy current data into col 3 so the df/f0 there can be overwritten with
%zdf/f0
data(:,3) = data(:,2);

%clear out data{:,2} since it's been copied to data{:,3} for zscoring
%did this to speed up code. Remove this if you need to spot check data
for row = 1:size(data,1)
    data{row,2} = [];
end

%% Import the data
medrawpresort = readcell(medpcfile);
%only imported Cued and CuedTO

%cut off column headings and sort by animal ID, ascending order
%important!: make sure medpc2excel imported by ascending date
%order, can figure out a way to do this in MATLAB if needed
medheadsum = medrawpresort(1,1:16);
medheader = medrawpresort(1,:);
medrawpresort = medrawpresort(2:end,:);

[~,sortidx] = sort(cell2mat(medrawpresort(:,1)));

medraw = medrawpresort(sortidx,:);
uniquesubjects = split(filenames(:), '_');
uniquesubjects = unique(uniquesubjects(:, 2));
medfilt = cell(size(medraw, 1), size(medraw, 2));
filtindex = 1;
for subj=1:length(uniquesubjects)
    found = find( cell2mat(medraw(:, 1)) == str2num(uniquesubjects{subj}));
    if (~isempty(found))
        % subtract one to account for matlab vectors starting at 1
       medfilt(filtindex:length(found) + filtindex - 1, :) = medraw(found(1):found(length(found)), :);
       filtindex = filtindex + length(found);
    end
end
clear medrawpresort;

% filter unused subjects out of medraw and sort by ascending subject number
%cycle through each mouse
medraw = medfilt(1:filtindex-1, :);

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
        
        clearvars raw1 R ;      
    end
    
    %% Calculate latency (cue on to Reward(First Proper NP of trial), col 9) and training day mean latency (col 10), and concat to data. Row = training day
    
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
        if data{file,3}{datarow,2} < -100 || data{file,3}{datarow,2} > 100
            data{file,3}{datarow,2} = NaN;
        end
    end
    
    
    %time stamp latency into 4th column of data{file,2}
    for datarow = 2:size(data{file,3},1)
        data{file,3}{datarow,4} = data{file,3}{datarow,1}-data{file,3}{datarow-1,1};
    end
    
    
    %% Make zscore cell entry (file,3)
    dffcolumn = cell2mat(data{file,3}(:,2));
    zdff = nanzscore(dffcolumn);
    
    data{file,3}(:,2) = num2cell(zdff);
    
    %% Trim to startpulse
    
    %transfer zscored data cell (w/o latency) to tempdata as matrix
    clear tempdata
    tempdata = cell2mat(data{file,3}(:,1:3));
    
    %find the start pulse (first 0 in DIO), align t = 0 to that, and trim
    %tempdata to remove pre-start pulse rows
    starttimeindex = find(tempdata(:,3)<1,1,'first');
    starttime = tempdata(starttimeindex,1);
    tempdata(:,1) = tempdata(:,1)-starttime;
    tempdata = tempdata(starttimeindex:end,:);
    
    
    %% Identify actions, put them in col 4 of tempdata, put tempdata into col 5 of data
    
    %add NaN to col 4
    blankcol = NaN(size(tempdata,1),1);
    tempdata = [tempdata blankcol];
    
    %action = place in summary cell | place in timestamp col| action ID
    %correct = 9 | 2 | 1
    %extracorrect = 9 | 2 | 5
    %tone = 14 | 6| 2
    %incorrect = 10 | 8 |  3
    %incorrect not leading to TO (within 5 sec of another incorrect) = 7
    %receptacle 13 | 4| 4
    %inactive 11 | 3 |  6
    
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
            if variable == 1
                [~,testextraind] = min(abs(tempdata(:,1)-(timestamp-2.3)));
                
                if  any(tempdata(testextraind:doricind-1,4)==1)
                    tempdata(doricind,4) = 5;
                end
            end
            
            %Change a non-TO yielding incorrect to 7
            if variable == 3
                [~,testextraimp] = min(abs(tempdata(:,1)-(timestamp-5.08)));
                
                if  any(tempdata(testextraimp:doricind-1,4)==3)
                    tempdata(doricind,4) = 7;
                end
            end
            
            %also going to divide by rec that follows a reward and those
            %that are random = 9
            if variable == 4
                [~,testextrarec] = min(abs(tempdata(:,1)-(timestamp-5.08)));
                
                if  any(tempdata(testextrarec:doricind-1,4)==4) || any(tempdata(testextrarec:doricind-1,4)==9)
                    tempdata(doricind,4) = 8;
                    
                elseif ~any(tempdata(testextrarec:doricind-1,4)==1)
                    tempdata(doricind,4) = 9;
                    
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
%inactive = 6

%initialize rawtogether
rawtogether = cell(size(data,1),2);

for file = 1:size(data,1)
    
    cutoff = 1789.5;
  
 
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

    %latency arrays
    ttp_list = zeros(0);
    ptr_list = zeros(0);

    %find all of the inidices of actions (not NaNs in aid cols)
    [actionind] = find(~isnan(data{file,5}(:,4)));
    
    %go through all actions in a given file
    for action=1:size(actionind,1)
        
        %make sure the the action isn't too close to start or end of
        %session
        if data{file,5}(actionind(action),1) > 5.1 && data{file,5}(actionind(action),1) <  cutoff
            
            %correct (reward delivery prop only)
            if data{file,5}(actionind(action),4) == 1
                correctcounter = correctcounter +1;
                correct(1:end,correctcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %rawtogether
                
                %find the tone that came before this correct NP
                lasttone = find(data{file,5}(1:actionind(action),4)==2, 1,'last');
                
                %find the rec that came immediately after this correct NP
                nextrec = find(data{file,5}(actionind(action):end,4)==4, 1,'first')+actionind(action)-1;
                
                if data{file,5}(nextrec,1) - data{file,5}(actionind(action),1) <= 5.008 %change from 5.08 to 5.008
                    %if there's a rec after correct np within 5 sec, take 5 sec
                    %after that
                    
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
                
                %tone
            elseif data{file,5}(actionind(action),4) == 2
                %fancy way to do it is here, but just doing 10 sec by 1221+2 extra cells jic
                %[~,plus10ind] = min(abs(data{file,5}(actionind(action):end,1)-(data{file,5}(actionind(action),1)+10)));
                tonecounter = tonecounter +1;
                tone(1:end, tonecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                 
                %tonehit
                if any(ismember(data{file,5}(actionind(action):actionind(action)+1223,4),1)) == 1
                    tonehitcounter = tonehitcounter +1;
                    tonehit(1:end, tonehitcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                    
                    %tonemiss
                else
                    tonemisscounter = tonemisscounter + 1;
                    tonemiss(1:end, tonemisscounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                end
                
                %incorrect
            elseif data{file,5}(actionind(action),4) == 3
                incorrectcounter = incorrectcounter + 1;
                incorrect(1:end,incorrectcounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %receptacle
            elseif data{file,5}(actionind(action),4) == 4
                receptaclecounter = receptaclecounter + 1;
                receptacle(1:end,receptaclecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                %randrec (rec entry not following reward)
            elseif data{file,5}(actionind(action),4) == 9
                randreccounter = randreccounter + 1;
                randrec(1:end,randreccounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
                
                
                
                %inactive
            elseif data{file,5}(actionind(action),4) == 6
                inactivecounter = inactivecounter + 1;
                inactive(1:end,inactivecounter) = data{file,5}(actionind(action)-610:actionind(action)+1221,2);
            end 
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
    outputname = [outputfolder '\MATLAB_' data{file,1}{1}(11:end-6) '.xlsx'];

    
    writecell(actioncounter, outputname, 'Sheet', 'counter');
    
    if correct ~= 0
        writematrix(correct, outputname, 'Sheet', 'correct');
    end
    
    if tone ~= 0
        writematrix(tone, outputname, 'Sheet', 'tone');
    end
    
    if incorrect ~= 0
        writematrix(incorrect, outputname, 'Sheet', 'incorrect');
    end
    
    if receptacle ~= 0
        writematrix(receptacle, outputname, 'Sheet', 'receptacle');
    end
    
    if randrec ~= 0
        writematrix(randrec, outputname, 'Sheet', 'randrec');
    end
    
    if tonehit ~= 0
        writematrix(tonehit, outputname, 'Sheet', 'tonehit');
    end
    
    if tonemiss ~= 0
        writematrix(tonemiss, outputname, 'Sheet', 'tonemiss');
    end
    
    if inactive ~= 0
        writematrix(inactive, outputname, 'Sheet', 'inactive');
    end
end

%% Timestamp file
%make a timestamp file from the first file's first correct nosepoke
file = 1;

%find the ind of the first correct np
[timeind] = find(data{file,5}(:,4)==1,1,'first');
timestampfile = data{file,5}(timeind-610:timeind+1221,1)-data{file,5}(timeind,1);

writematrix(timestampfile, timestampfolder);


%% Save data in file
%just rawtogether and names
save(FP_MATLAB_VARS_FILENAME, 'rawtogether', 'filenames', '-v7.3');

%% Print code version text file

%print the version of the code used
fileID = fopen([outputfolder '\codeused.txt'],'w');
fprintf(fileID, codename);

