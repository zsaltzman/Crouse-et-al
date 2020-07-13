% Make sure to change this directory to the parent folder of this pipeline.
% e.g.: 'C:\Users\rbc52\Documents\MATLAB\Crouse et al\2019-06'
FP_PARENT_DIRECTORY = 'D:\Picciotto Lab Stuff\Crouse et al v2\Crouse et al v2\Crouse et al MATLAB Outputs and Raw\2020-04 NBM-BLA GCaMP7';

%if FP_PARENT_DIRECTORY wasn't designated, stop script and alert the user
if isempty(FP_PARENT_DIRECTORY)
   fprintf('Please designate FP_PARENT_DIRECTORY in this pipeline and make sure the current folder for MATLAB is pointed in it');
   return
end


FP_OUTPUT_DIRECTORY = [ FP_PARENT_DIRECTORY '\generated output' ];
FP_RAW_DIRECTORY = [ FP_PARENT_DIRECTORY '\raw' ];
FP_PROC_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated processed' ];
FP_COMPILE_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated individual events by day' ];
FP_COMPILE_REF_SIG_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated individual events by day Reference vs Signal' ];
FP_MEDPC_FILE = [ FP_PARENT_DIRECTORY '\2020-04 MedPC Full.xlsx' ];
FP_TIMESTAMP_FILE = [ FP_OUTPUT_DIRECTORY '\pipeline_2020_04 timestamps.xlsx' ];

FP_INDIVIDUAL_DAY_GRAPH_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated invididual day graphs' ];

FP_SUMMARY_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated event summary graphs' ];
FP_SUMMARY_TP_DIRECTORY = [ FP_OUTPUT_DIRECTORY '\generated summary_tone_poke_rec graphs' ];

FP_MATLAB_VARS = [FP_OUTPUT_DIRECTORY '\MATLAB intermediate variables'];
FP_MATLAB_VARS_FILENAME = [ FP_MATLAB_VARS '\rawandnamesonly.mat'];
FP_INDIVIDUAL_DAY_DATA_FILENAME = [ FP_MATLAB_VARS '\day_graph_data.mat' ];

FP_BCI_PARENT_FOLDER = [ FP_OUTPUT_DIRECTORY '\generated bCI graphs' ];

save(getPipelineVarsFilename);

MDIR_DIRECTORY_NAME = FP_OUTPUT_DIRECTORY;
make_directory

% Basic_FP_processing_2020_04_v1
%     %takes raw files and turns them into processed (calculates corrected df/f0,
%     %while keeping the individual channel ones too)
% 
% FP_Compile_2020_04_v1
%     %integrates MedPC and Doric data. Yields:
%         %1) rawtoghether and filenames saved as .mat file, with options to save
%         %all at once or do it day by day
%         %2)Saves the MATLAB_... .xlsx files with the doric signal 5 sec prior and 
%         %10 sec after actions of interest, separated into sheets. 
%         %3) grabs rcamp col for those mice
%         %Requires:
%             %1) PROCESSED_... excel files from above
%             %2) ... MedPC Full file that was generated from MPC2XL program
%         %Options:
%             %1) Can change it to import corrected or plain signal df/f0 columns
%         %To Do: 
%             %rerun rcamp mice and get the full deal 
% 
% rick_mean_SEM_calc_indiv_plots_v6
% %     %1)makes mean and sem variables from the MATLAB_...xlsx files and saves
% %     %those variables for action heatmaps script
% %     %2)plots the individual traces/heatmaps for each mouse, each day, each
% %     %action
% % 
% 
% 
%Actions_heatmaps_all_phases_pub
%      %makes action summary heatmaps across days and saves excel files for
%      %prism plotting

rick_tone_poke_rec_heatmaps_by_mouse_v4
%     %makes tone_poke_rec heatmaps from rawtogether and filenames
    

% NOTE: calc_bCI uses bootstrapping, which is a statistical process which
% may produce small differences in confidence intervals between runs. This
% is the expected and correct process of bootstrapping. If you want to
% reduce the variance between runs, you may change the number of boots
% within the calc_bCI code. 
%calc_bCI

calc_bCI_cohort_2020_04

