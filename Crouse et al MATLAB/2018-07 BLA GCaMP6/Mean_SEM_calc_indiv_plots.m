%% mean_SEM_calc_indiv_plots_v3
%format for aligning data is insprired by the example
%code by TDT found at https://www.tdt.com/support/matlab-sdk/offline-analysis-examples/licking-bout-epoc-filtering/

clear;
load(getPipelineVarsFilename);
codename = 'rick_mean_SEM_v3';

% Groups
BLA_GCaMP = [3 4 6];


%% Set folder/files   
folder = FP_COMPILE_DIRECTORY;
outputfolder = FP_MATLAB_VARS;
timestampfile = FP_TIMESTAMP_FILE;
save_name = FP_INDIVIDUAL_DAY_DATA_FILENAME;
outputfile = '2018-07 App MATLAB graph data';

MDIR_DIRECTORY_NAME = outputfolder;
make_directory

%file to skip
skips = ["HB03_Timeout_Day_12"; "HB04_Timeout_Day_11"; "HB04_Timeout_Day_13"; "HB05_Timeout_Day_09"; "HB06_Timeout_Day_09";  "HB06_Timeout_Day_11"; "HB08_Timeout_Day_12"];


%% read data

%Auto Import Data
C = dir([folder, '\*.xlsx']);
filenames = {C(:).name}.';
datanames = cell(length(C),1);
graphdata = cell(length(C),1);

variables = ["correct" "tone" "incorrect" "receptacle" "randrec" "tonehit" "tonemiss" "inactive"];


for ii = 1:length(C)
    % Create the full file name and partial filename
    fullname = [folder '\' C(ii).name];
    
   
    datanames{ii,1} = filenames(ii);
    
    %skip bad days (fiber slipping off)
    if any(strcmpi(datanames{ii}{1}(8:end-5),skips))
       
        %need to add this skip if statement below as well
        continue
    
    % Read in the data
    else    
    sheets = sheetnames(fullname);
    
        for sheetsidx = 2:length(sheets)
            graphdataidx=find(strcmpi(sheets{sheetsidx},variables));
            graphdata{ii,graphdataidx} = readmatrix(fullname, 'Sheet', sheets{sheetsidx});
        end
    
    end
end



%import timestamp
time = readmatrix(timestampfile);

%% Calculate averages and sems

graphmean = cell(size(graphdata));
graphsem = cell(size(graphdata));

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

save(save_name, 'graphmean', 'graphsem', 'datanames', '-v7.3');

% print the version of the code used
fileID = fopen([outputfolder '\' date 'codeused.txt'],'w');
fprintf(fileID, codename);