%% Basic_FP_processing_2020_04

clc;
clear;
load(getPipelineVarsFilename);


%% Change this directory to the folder containing your raw doric files!
directory = FP_RAW_DIRECTORY;
output_directory = FP_PROC_DIRECTORY;
files = dir(directory);

processed_files = dir(output_directory);
processed_files = [ processed_files(:).name ];

MDIR_DIRECTORY_NAME = output_directory;
make_directory


for file = files'
    
    filename = strcat(file.name);
    %only process .csv files, don't process "PROCESSED" files, and don't
    %process any that already have a 'PROCESSED' version in the folder
    if isempty(strfind(filename, '.csv'))==true || isempty(strfind(filename, 'PROCESSED_'))==false || sum(strcmp(strcat('PROCESSED_',filename),{files.name}))>0 || ~isempty(strfind(processed_files, filename))
        fprintf('Skipping %s\n', filename);
        continue
    end
    
    allData = readmatrix([directory,'\' filename]); % 1: skip first two lines line (header); might need to skip more depeding how the file but basically the goal is to scrap the headers.
    firstLine = find(allData(:,1) > 0.1, 1); % Everything before ~100 ms is noise from the lock-in filter calculation; it sounds like this is default in the correction we get wqhen we extract DF/F0
    data = allData(firstLine:end, :);
    
    % Strip nan out of data before processing (do this if all the data ends
    % up as nan). 
    % TODO: Change this to cut the rows
    data(isnan(data)) = 0;
    DIO = data(:, 5); 
    
    correctedSignal = subtractReferenceAndSave(DF_F0, output_directory, filename, DIO);
    
    fprintf('Proccessed %s\n', filename);
end