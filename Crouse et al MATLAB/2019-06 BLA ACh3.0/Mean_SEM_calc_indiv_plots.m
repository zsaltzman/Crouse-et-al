%% mean_SEM_calc_indiv_plots_v3

%4/27/20: modified from pub code to exclude the temp files (those starting
%with ~)

%format for aligning data is insprired by the example
%code by TDT found at https://www.tdt.com/support/matlab-sdk/offline-analysis-examples/licking-bout-epoc-filtering/


clear;
load(getPipelineVarsFilename);

%Groups
BLA_GACh = [813 814 820 827];



%% Set folder/files

folder = FP_COMPILE_DIRECTORY;
outputfolder = FP_MATLAB_VARS;
outputfile = '2019-06 App MATLAB graph data';
timestampfile = FP_TIMESTAMP_FILE;
save_name = FP_INDIVIDUAL_DAY_DATA_FILENAME;

MDIR_DIRECTORY_NAME = outputfolder;
make_directory;

%file to skip
skips = ["827_Timeout_Day_06"; "813_Timeout_Day_12"; "820_Timeout_Day_06"; "814_Timeout_Day_01"; "814_Timeout_Day_07"];


%% read data

%Auto Import Data
C = dir([folder, '\*.xlsx']);
filenames = {C(:).name}.';

%exclude any temp files
filenames = filenames(~startsWith(filenames,'~'));


%initialize
datanames = cell(length(filenames),1);
graphdata = cell(length(filenames),1);

variables = ["correct" "tone" "incorrect" "receptacle" "randrec" "tonehit" "tonemiss" "inactive"];



[ sorted_filenames, ~ ] = sort_nat(filenames);
for ii = 1:length(filenames)
    % Create the full file name and partial filename
    fullname = [folder '\' sorted_filenames{ii}];
    
   
    datanames{ii,1} = sorted_filenames{ii};
    
    %skip bad days (fiber slipping off)
    if any(strcmpi(datanames{ii,1}(8:end-5),skips))
        continue
    else    
    [~,sheets] = xlsfinfo(fullname);
    
        for sheetsidx = 3:size(sheets,2)
            graphdataidx=find(strcmpi(sheets{sheetsidx},variables));
            graphdata{ii,graphdataidx} = xlsread(fullname,sheets{sheetsidx});
        end
    
    end
end

%import timestamp
time = xlsread(timestampfile);

%% Calculate averages and sems

graphmean = cell(size(graphdata));
graphsem = cell(size(graphdata));

%loop for all days
for file = 1:size(graphdata,1)
    if any(strcmpi(datanames{file,1}(8:end-5),skips))  
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
  
save(save_name);