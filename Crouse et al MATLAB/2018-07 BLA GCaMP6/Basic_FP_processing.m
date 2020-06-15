%% Basic_FP_processing
%This is modified from what Doric sent us to calculate corrected df/f0 and
%save/plot corrected files. Not going to actually use the plotting part
%though. 
%main goal here is to batch calculate corrected df/f0's while keeping
%the DIO signal to use for FP analysis of cued app task (2019-06 at
%this point)
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
  
  allData = readmatrix([directory,'\' filename]); % reading in just numeric lines, therefore skipping the headers
  colheader = readcell([directory,'\' filename],'Range', 'A1:Z1'); %read just the first row to get the headers
  firstLine = find(allData(:,1) > 0.1, 1); % Everything before ~100 ms is noise from the lock-in filter calculation; it sounds like this is default in the correction we get wqhen we extract DF/F0
  
  
  %identify cols of interest based on header
  for cols = 1:size(colheader,2)
      if strcmp(colheader{cols}, 'Time(s)')  
          timecol = cols;
           
      elseif strcmp(colheader{cols}, 'DI/O-1')  
          diocol = cols;
         
      elseif strcmp(colheader{cols}, 'AIn-1 - Demodulated(Lock-In)')  
          ch1col = cols;
          
      elseif strcmp(colheader{cols}, 'AIn-2 - Demodulated(Lock-In)')  
          ch2col = cols;
          
      end
  end
  
  %rearrange data array based on id'd cols
  data = allData(firstLine:end, [timecol ch1col ch2col diocol]); 
  
  
  DF_F0 = calculateDF_F0(data);
  
  %find DIO column
  DIO = data(:,4);
  
  
  correctedSignal = subtractReferenceAndSave(DF_F0, output_directory, filename, DIO);
  fprintf('Processed file %s\n', filename);
end
