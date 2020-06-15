%% Mean_SEM_calc_indiv_plots_v5
%format for aligning data is insprired by the example
%code by TDT found at https://www.tdt.com/support/matlab-sdk/offline-analysis-examples/licking-bout-epoc-filtering/


clear
close all;
load(getPipelineVarsFilename);

codename = 'Mean_SEM_v5';

%Groups
rcamp_gach = [850];
NBM_BLA = [856 860];

%variables
variables = ["correct" "tone" "incorrect" "receptacle" "randrec" "tonehit" "tonemiss" "inactive"];
r_variables = ["r_correct" "r_tone" "r_incorrect" "r_receptacle" "r_randrec" "r_tonehit" "r_tonemiss" "r_inactive"];


%% Set folder/files
folder = FP_COMPILE_DIRECTORY;
outputfolder = FP_MATLAB_VARS;
timestampfile = FP_TIMESTAMP_FILE;
save_name = FP_INDIVIDUAL_DAY_DATA_FILENAME;
outputfile = '2019-14 App MATLAB graph data';

MDIR_DIRECTORY_NAME = outputfolder;
make_directory;

%file to skip
skips = ["0849 Timeout Day 09"; "0849 Timeout Day 11"; "0856 ZExtinction Day 01"];

%% Import timestamp
time = xlsread(timestampfile);


%% read data

%Auto Import Data
C = dir([folder, '\*.xlsx']);
filenames = {C(:).name}.';

%exclude any temp files
filenames = filenames(~startsWith(filenames,'~'));


%initialize
datanames = cell(length(filenames),1);
graphdata = cell(length(filenames),1);
r_graphdata = graphdata;

for file = 1:length(filenames)
    % Create the full file name and partial filename
    fullname = [folder '\' C(file).name];
    
    
    datanames{file,1} = filenames(file);
    
    %skip bad days (fiber slipping off)
    if any(strcmpi(datanames{file}{1}(8:end-5),skips))
        
        %need to add this skip if statement below as well
        continue
        
        % Read in the data
    else
        [~,sheets] = xlsfinfo(fullname);
        
        %loop through all sheets, find the sheets whose name match one of
        %the variables. Pull that sheet and put it in graphdata in the col
        %that matches the idx of the var name in the variable string (e.g.
        %correct is col 1). If an rcamp mouse, pull the r_ sheet and put it
        %in r_graphdata
        for sheetsidx = 1:size(sheets,2)
            if any(strcmpi(sheets{sheetsidx},variables))
                %fix checking of mouse number, maybe change it to just making
                %a new r_graphdata variable
                
                graphdataidx=find(strcmpi(sheets{sheetsidx},variables));
                graphdata{file,graphdataidx} = xlsread(fullname,sheets{sheetsidx});
                
                %if it's an rcamp mouse, grab the corresponding r_ var 8 idx's
                %away
                if str2double(datanames{file,1}{1}(8:11)) == 849 || str2double(datanames{file,1}{1}(8:11)) == 850
                    r_graphdata{file,graphdataidx} = xlsread(fullname,['r_' sheets{sheetsidx}]);
                end
                
            end
        end
        
    end
end


%% Calculate averages and sems
graphmean = cell(size(graphdata));
graphsem = cell(size(graphdata));

r_graphmean = graphmean;
r_graphsem = graphsem;

%loop for all days
for file = 1:size(graphdata,1)
    if any(strcmpi(datanames{file}{1}(8:end-5),skips))
        continue
    else
        %loop for all variables
        for variable = 1:size(graphdata,2)
            %only do if cell ~isempty
            if ~isempty(graphdata{file,variable})
                graphmean{file,variable} = nanmean(graphdata{file,variable},2);
                graphsem{file,variable} = nanstd(graphdata{file,variable},0,2)/sqrt(size(graphdata{file,variable},2));
                
                %if a rcamp mouse, make r_vars from r_graphdata
                if str2num(datanames{file,1}{1}(8:11)) == 849 || str2num(datanames{file,1}{1}(8:11)) == 850
                    r_graphmean{file,variable} = nanmean(r_graphdata{file,variable},2);
                    r_graphsem{file,variable} = nanstd(r_graphdata{file,variable},0,2)/sqrt(size(r_graphdata{file,variable},2));
                end
            end
        end
    end
end


% save(save_name, 'graphmean', 'graphsem', 'datanames', '-v7.3');
save(save_name, 'graphmean', 'graphsem', 'datanames', 'graphdata', '-v7.3');

%print the version of the code used
fileID = fopen([outputfolder '\' date 'codeused.txt'],'w');
fprintf(fileID, codename);