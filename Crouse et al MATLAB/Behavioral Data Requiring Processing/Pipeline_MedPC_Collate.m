%% Pipeline_MedPC_Collate
%For optogenetic and antagonist studies. Used to collate data from MedPC input excel files and put into MATLAB
%Output files, in which the behavioral responses are organized by group. 

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
FP_PARENT_DIRECTORY = '';

%if FP_PARENT_DIRECTORY wasn't designated, stop script and alert the user
if isempty(FP_PARENT_DIRECTORY)
   fprintf('Please designate FP_PARENT_DIRECTORY in this pipeline and make sure the current folder for MATLAB is pointed in it');
   return
else
    %carry on
end


FP_OUTPUT_DIRECTORY = [ FP_PARENT_DIRECTORY '\generated outputs' ];
FP_RAW_DIRECTORY = [ FP_PARENT_DIRECTORY '\input' ];

save(getPipelineVarsFilename);

MDIR_DIRECTORY_NAME = FP_OUTPUT_DIRECTORY;
make_directory;

Fig_4EF_S4_2AB_summary

Fig_S4_2C_F_summary

Fig_S4_4A_summary

Fig_S4_4C_summary

Fig_5_summary

Fig_6_BC_S6_2AB_summary