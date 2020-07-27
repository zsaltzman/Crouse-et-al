%% Mean_SEM_calc_indiv_plots
%format for aligning data is insprired by the example
%code by TDT found at https://www.tdt.com/support/matlab-sdk/offline-analysis-examples/licking-bout-epoc-filtering/


clear
close all;
load(getPipelineVarsFilename);

codename = 'Mean_SEM';

%Groups
rcamp_gach = [850];
NBM_BLA = [856 860];

%variables
variables = ["correct" "tone" "incorrect" "receptacle" "randrec" "tonehit" "tonemiss" "inactive"];


%% Set folder/files
folder = FP_COMPILE_DIRECTORY;
outputfolder = FP_MATLAB_VARS;
timestampfile = FP_TIMESTAMP_FILE;
save_name = FP_INDIVIDUAL_DAY_DATA_FILENAME;
outputfile = '2020-04 App MATLAB graph data';

MDIR_DIRECTORY_NAME = outputfolder;
make_directory;

%file to skip
skips = [];

%% Import timestamp
time = readmatrix(timestampfile);


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
        sheets = sheetnames(fullname);
        
        %loop through all sheets, find the sheets whose name match one of
        %the variables. Pull that sheet and put it in graphdata in the col
        %that matches the idx of the var name in the variable string (e.g.
        %correct is col 1). If an rcamp mouse, pull the r_ sheet and put it
        %in r_graphdata
        for sheetsidx = 1:length(sheets)
            if any(strcmpi(sheets{sheetsidx},variables))
                %fix checking of mouse number, maybe change it to just making
                %a new r_graphdata variable
                
                graphdataidx=find(strcmpi(sheets{sheetsidx},variables));
                graphdata{file,graphdataidx} = xlsread(fullname,sheets{sheetsidx});
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
            end
        end
    end
end


% save(save_name, 'graphmean', 'graphsem', 'datanames', '-v7.3');
save(save_name, 'graphdata', 'graphmean', 'graphsem', 'datanames', 'graphdata', '-v7.3');

%print the version of the code used
fileID = fopen([outputfolder '\' date 'codeused.txt'],'w');
fprintf(fileID, codename);