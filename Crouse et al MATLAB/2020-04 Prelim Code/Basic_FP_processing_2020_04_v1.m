%% Basic_FP_processing_2020_04_v1
%This is modified from what Doric sent us to calculate corrected df/f0 and
%save/plot corrected files. Not going to actually use the plotting part
%though.
%main goal here is to batch calculate corrected df/f0's while keeping
%the DIO signal to use for FP analysis of cued app task (2019-06 at
%this point)

%v4: use 2nd order polynomial for rcamp and NBM-BLA

%To Do:
%Need to allow for 2channel calculation after getting answer from Doric

clc
clear;
close all;

load(getPipelineVarsFilename);

%Designate special cases (here, RCaMP+GACh)
rcamp = [];
nbm_bla = ["0890"; "0891"; "0894"; "0907"; "0913"; "0914"];


%% Change this directory to the folder containing your raw doric files!
directory = FP_RAW_DIRECTORY;
outputdirectory = FP_PROC_DIRECTORY;
files = dir(directory);

MDIR_DIRECTORY_NAME = outputdirectory;
make_directory;

% The next function is not necessarily needed but it is just a way to
% avoid processing files already processed. Keep in mind that to be
% relevant, these functions  will work on data already selected (i.e which time range) which could be
% easily extracted from DNS or processed with something like Rick's code to
% get only 7 seconds around the tone in fear conditonning
for file = files'
    
    filename = strcat(file.name);
    %only process .csv files, don't process "PROCESSED" files, and don't
    %process any that already have a 'PROCESSED' version in the folder
    if isempty(strfind(filename, '.csv'))==true || isempty(strfind(filename, 'PROCESSED_'))==false || sum(strcmp(strcat('PROCESSED_',filename),{files.name}))>0
        continue
    end
    
    
    
    %[~,~,allData{1}] = csvread([directory,'\' filename]);
    allData = readmatrix([directory,'\' filename]); % 1: skip first two lines line (header); might need to skip more depeding how the file but basically the goal is to scrap the headers.
    firstLine = find(allData(:,1) > 0.1, 1); % Everything before ~100 ms is noise from the lock-in filter calculation; it sounds like this is default in the correction we get wqhen we extract DF/F0
    data = allData(firstLine:end, :);
    
    %Actually calculating rcamp signal
    if any(strcmpi(filename(1:4),rcamp))
        
        %use this for comparing different df/f0 calculations
        %         filename = [filename '2ndorder'];
        
        DF_F0 = calculateDF_F0(data);
        DIO = data(:,7);
        
        %calc df_f0 for rcamp, using modified function
        data_rcamp = allData(firstLine:end,[1 5]);
        DF_F0_rcamp = calculateDF_F0_rcamp_2nd_order(data_rcamp);
        
        %trim to just df/f0 col and not the time col used to calc it
        DF_F0_rcamp = DF_F0_rcamp(:,2);
        
        correctedSignal = subtractReferenceAndSave_2019_14_rcamp(DF_F0, outputdirectory, filename, DIO, DF_F0_rcamp);
        
        
    elseif any(strcmpi(filename(1:4),nbm_bla)) %nbm-bla 2nd order
        
        %use this for comparing different df/f0 calculations
        %         filename = [filename '2ndorder'];
        
        DF_F0 = calculateDF_F0_2nd_order(data);
        DIO = data(:,5);
        correctedSignal = subtractReferenceAndSave(DF_F0, outputdirectory, filename, DIO);
  
    else %standard one channel
        DF_F0 = calculateDF_F0(data);
        DIO = data(:,5);
        correctedSignal = subtractReferenceAndSave(DF_F0, outputdirectory, filename, DIO);
   
    end
    
end