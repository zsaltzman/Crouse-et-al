%% Pipeline_2018_07
% IMPORTANT NOTES:
%1) Before running this code please make sure that all the
% pipeline scripts are in the same directory, otherwise this isn't
% guaranteed to run! This should be the case if you downloaded everything
% and didn't rearrange anything. 

%2) Make sure MATLAB's current folder is this pipeline's parent folder.
%Don't add all the folders to the path because there are different versions of the same
%script. 

%3) Change the FP_PARENT_DIRECTORY below

%clear everything to prevent issues
clear; 


% Make sure to change this directory to the parent folder of this pipeline.
% e.g.: 'C:\Users\rbc52\Documents\MATLAB\Crouse et al\2019-06'
FP_PARENT_DIRECTORY = 'D:\Picciotto Lab Stuff\Crouse et al v2\Crouse et al v2\Crouse et al MATLAB Outputs and Raw\2018-07 BLA GCaMP6';

%if FP_PARENT_DIRECTORY wasn't designated, stop script and alert the user
if isempty(FP_PARENT_DIRECTORY)
   fprintf('Please designate FP_PARENT_DIRECTORY in this pipeline and make sure the current folder for MATLAB is pointed in it');
   return
end

COMPILE_WITH_REF = 1; % 0 = false, 1 = true. Leave this on 0 unless you want to compile the pipeline to use reference instead of signal 

if COMPILE_WITH_REF
   FP_OUTPUT_DIRECTORY = [FP_PARENT_DIRECTORY '\generated output (reference)'];
else
   FP_OUTPUT_DIRECTORY = [ FP_PARENT_DIRECTORY '\generated output' ];
end

FP_RAW_DIRECTORY = [ FP_PARENT_DIRECTORY '\raw subset' ];
FP_PROC_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated processed' ];
FP_COMPILE_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated individual events by day' ];
FP_COMPILE_REF_SIG_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated individual events by day Reference vs Signal' ];
FP_MEDPC_FILE = [ FP_PARENT_DIRECTORY '\2018-07 MedPC Partial.xlsx' ];
FP_TIMESTAMP_FILE = [ FP_OUTPUT_DIRECTORY '\pipeline_2018_07 timestamps.xlsx' ];

FP_SUMMARY_DIRECTORY =  [ FP_OUTPUT_DIRECTORY '\generated event summary graphs' ];
FP_SUMMARY_TP_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated summary_tone_poke_rec graphs' ];

FP_MATLAB_VARS = [ FP_OUTPUT_DIRECTORY '\MATLAB intermediate variables' ];
FP_MATLAB_VARS_FILENAME = [ FP_MATLAB_VARS '\rawandnamesonly.mat' ];
FP_INDIVIDUAL_DAY_DATA_FILENAME = [ FP_MATLAB_VARS '\individual_day_graph_data.mat' ];

FP_BCI_PARENT_FOLDER = [ FP_OUTPUT_DIRECTORY '\generated bci graphs' ];

% This should be the root folder of your study and this should be the ONLY
% Matlab variable file in the root directory
save(getPipelineVarsFilename); 

MDIR_DIRECTORY_NAME = FP_OUTPUT_DIRECTORY;
make_directory

Fig_3C_S3_2A_summary_2018_07

Basic_FP_processing

FP_Compile_2018_07 

% FP_Compile_2018_07_ref

% FP_Compile_2018_07_sig

Mean_SEM_calc_indiv_plots

% Actions_heatmaps_all_phases_pub

% Tone_poke_rec_heatmaps_by_mouse

calc_bCI

calc_bCI_cohort_2018_07