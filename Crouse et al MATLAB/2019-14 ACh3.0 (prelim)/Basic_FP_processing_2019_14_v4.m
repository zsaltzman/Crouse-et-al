%% Basic_FP_processing_2019_14_v4

clc;
clear;
load(getPipelineVarsFilename);

%Designate special cases (here, RCaMP+GACh)
rcamp = ["0849"; "0850"];
gach = [];
nbm_bla = [];


%% Change this directory to the folder containing your raw doric files!
directory = FP_RAW_DIRECTORY;
output_directory = FP_PROC_DIRECTORY;
files = dir(directory);

MDIR_DIRECTORY_NAME = output_directory;
make_directory


for file = files'
    
    filename = strcat(file.name);
    %only process .csv files, don't process "PROCESSED" files, and don't
    %process any that already have a 'PROCESSED' version in the folder
    if isempty(strfind(filename, '.csv'))==true || isempty(strfind(filename, 'PROCESSED_'))==false || sum(strcmp(strcat('PROCESSED_',filename),{files.name}))>0
        fprintf('Skipping %s\n', filename);
        continue
    end
    
    allData = csvread([directory,'\' filename],2,0); % 1: skip first two lines line (header); might need to skip more depeding how the file but basically the goal is to scrap the headers.
    firstLine = find(allData(:,1) > 0.1, 1); % Everything before ~100 ms is noise from the lock-in filter calculation; it sounds like this is default in the correction we get wqhen we extract DF/F0
    data = allData(firstLine:end, :);
    
    %Actually calculating rcamp signal
    if any(strcmpi(filename(1:4),rcamp))
        
        DF_F0 = calculateDF_F0(data);
        DIO = data(:,7);
        
        %calc df_f0 for rcamp, using modified function
        data_rcamp = allData(firstLine:end,[1 5]);
        DF_F0_rcamp = calculateDF_F0_rcamp_2nd_order(data_rcamp);
        
        %trim to just df/f0 col and not the time col used to calc it
        DF_F0_rcamp = DF_F0_rcamp(:,2);
        
        correctedSignal = subtractReferenceAndSave_2019_14_rcamp(DF_F0, output_directory, filename, DIO, DF_F0_rcamp);
        
        
    elseif any(strcmpi(filename(1:4),nbm_bla)) %nbm-bla 2nd order
        DF_F0 = calculateDF_F0_2nd_order(data);
        DIO = data(:,5);
        correctedSignal = subtractReferenceAndSave(DF_F0, output_directory, filename, DIO);
   
    else %standard one channel
        DF_F0 = calculateDF_F0(data);
        DIO = data(:,5);
        correctedSignal = subtractReferenceAndSave(DF_F0, output_directory, filename, DIO);
    end
    
    fprintf('Proccessed %s\n', filename);
end