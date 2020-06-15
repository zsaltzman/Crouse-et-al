To read this document on the web, use the following link:
https://docs.google.com/document/d/109YVIv3Tm6ry2N0n_-SbdSLvIWKLov8i0y2rrCzDQ_o/edit?usp=sharing
________________




﻿Quick Reference Key For FP Output folders and the data/heatmaps they contain




generated individual events by day
Correct vs Incorrect nose poke plots: Fig 2 C, 2 H, 3 B, S2.5 F-H, S3.1 B
PT Day 4 vs Training Day 1 incorrect nose poke plots: Fig. S2.2 B, S2.4 B, S3.2 B




Note: if you want to plot individual trials within a day, grab the data from the tab in the “Generated individual events by day” folder. If you only care about the mean and SEM and want to plot across days easily, grab from the summary graph .xlsx file in the generated event summary graphs folder. You can find the timestamp (i.e. x-values) for plotting in the output parent folder








generated individual events by day Reference vs Signal
Reference vs Signal correct and incorrect nose poke plots: Fig S2.1 B-C, S2.3 E-F, S3.1 C-D








generated event summary graphs
Incorrect nose poke summary heatmaps by mouse and averaged across mouse: Fig S2.2 C-G, S2.4C-E, S3.2 C-F








generated summary_tone_poke_rec graphs
Combined action heatmaps (tone_poke_rec) by mouse and averaged across mouse: Fig 2 D-E, Fig 2 I-J, Fig 3 D-E, Fig S2.1 D-F, Fig S2.3 G, Fig S3.1 E-F.








Note: All data for non-FP behavior conducted in a MedPC behavioral box is found in the Behavioral Data Requiring Processing output folder. All other behavioral data is found in the Behavioral Data Not Requiring Processing folder. 








________________




Introduction




Inside the ‘Crouse et al’ folder, you will find 5 additional folders corresponding to different data sets. These are broken into two branches: Fiber Photometry (Figures 2-3) and Behavioral Data (Figure 4-6). 




Fiber Photometry consists of folders:
2018-07 BLA GCaMP6
2019-06 BLA ACh3.0
2019-14 NBM-BLA GCaMP7 and GACh3.0+RCaMP
(note: the numbered prefixes here correspond to internal experimental identifiers)




Behavioral Data consists of folders: 
Behavioral Data Not Requiring Processing
Behavioral Data Requiring Processing




The rough steps to run the pipeline are as follows: you will go into the folder corresponding to the data you are interested in, open up the pipeline inside using MATLAB and follow the instructions below to start the automatic process to collate the data and — in the case of the fiber photometry experiments — generate the heatmaps. Note that folder “Behavioral Data Not Requiring Processing”, contains files that do not need to be collated and are named for the figures they correspond to. 




The following section contains additional details on running a pipeline, overviews of the scripts employed, and experimental details pertinent to the analysis.




________________




How to run a pipeline




All that is required to run one of the pipelines to generate the outputs of the experimental data is to open the appropriate ‘Pipeline’ file from within an experiment and click ‘Run’ at the top of the MATLAB editor. This will collate the data that corresponds to the figures in the paper and in the cases of the fiber photometry experiments, generate the heatmaps. The relevant variable for you to change is in a file named “Pipeline_[pipeline name]”, where pipeline name corresponds to one of the experiments below.




There are variables written entirely in upper-case with words separated by underscores in the pipeline file that correspond to directories on your computer that already exist within the Crouse et al folder or will be generated. Following those initiation steps, the scripts that will be called are listed in order. 




You must change the FP_PARENT_DIRECTORY to the parent folder of the pipeline on your machine in order for the code to function properly. The parent folder for each pipeline will be the name of the folder that contains the MATlAB code files.




Once this is done, you should simply be able to run the code and wait for it to finish. Note that these processes are computationally expensive, and may cause interruptions to other processes on your computer while they are running. 2019-06’s pipeline will take the longest as it has the most data files. You will find all outputs in a newly created “output” folder in the parent folder. 




The Behavioral Data Requiring Processing folder’s pipeline (Pipeline_MedPC_Colllate) works in a similar fashion as the Fiber Photometry pipelines, except that it will run very quickly and only deals with behavioral data. The data is collated by groups separated by blank columns. Each behavioral measure will be stored in its own sheet, and will output into .xlsx files named for the figure they contain data for. The individual mouse number will be the heading of each column.




All of the scripts and functions in these pipelines, with the exception of nanzscore, Basic_FP_processing, calculateDF_F0, and subtractReferenceAndSave, were designed to only work with the experiments in this manuscript. These will not work on outside data sets without significant adjustment, though the algorithms inside may provide useful inspiration. The data resulting from these scripts in .xlsx can be plotted in conjunction with the timestamp file for each experiment (details below).




As an additional note, 2018-07 requires Matlab’s Signal Processing Toolbox to run. More information may be found here https://www.mathworks.com/products/signal.html.








________________




Details on Data Structure and Scripts








Raw Data (starting inputs)
The raw data comes in two parts: 1) fiber photometry raw data and 2) MedPC behavioral data:
 
1) A ~30 minute long fiber photometry recording for each behavioral session for each mouse. These are .csv’s that consist of columns with the timestamps in seconds, demodulated reference and signal channel(s) listing changes in voltage, and the digital input/output channel (a binary TTL pulse that synchronizes the MedPC behavioral software). The TTL pulse is “on” when the value is 0. The first string of zeros in the file signals the start of the behavioral program, and additional strings of zeros with different latencies that correspond to events in the task as a redundancy because timestamp values are taken from the MedPC file. These extraneous files can found in the “raw” folder of each experiment. For example, in 2019-06, the “raw” folder is located here: ‘C:\Users\rbc52\Documents\MATLAB\Crouse et al\2019-06 BLA ACh3.0\raw and one of the filenames is 813_Cued_Day_01_1.csv, where 813 is the mouse number, Cued is the phase of training (see notes below for details on the phase names), Day_01 is the day of training phase, and _1 is the Doric software’s automatic file indexing, which can be ignored.




2) One Excel file for the entire experiment that has all of the responses recorded from the MedPC behavioral computer. Each row of data is an individual behavioral session for one mouse. The columns are headed with the value that is recorded. There are summary columns that report final values at the end of a session, e.g. how many rewards were earned that session. The bulk of the columns are arrays that hold the timestamps for each action recorded, e.g. Reward 1 was earned at 65.123 sec. The mapping for these variables can be found in the FP_Compile code.This MedPC file is in the parent directory of the experiment folder, e.g. C:\Users\rbc52\Documents\MATLAB\Crouse et al\2019-06 BLA ACh3.0. The file will be named after the date of the experiment and contain the phrase ‘MedPC Full’. 








Basic FP Processing
The raw FP files must be processed to yield the dF/F0 values from the demodulated voltage values. This script and the two functions called by it were provided by Doric Lenses and were modified as needed. Details of the method used are listed in the methods but a brief description is as follows: a least mean squares regression is used to calculate a baseline fluorescence and the difference in fluorescence for each timepoint is calculated and multiplied by 100 to give dF/F0 (calculateDF_F0.m script). This is done independently for the reference and signal channels. A “corrected” DF_F0 is also calculated by subtracting the reference DF_F0 from the signal DF_F0 (though this is not used) and the time, reference dF/F0, signal dF/F0, and DIO columns are saved in a file with the prefix “PROCESSED_” (subtractReferenceAndSave.m) in the “generated processed” folder. The filename for the previous example would be PROCESSED_813_Cued_Day_01_1.csv. Note that a second order regression is used for the NBM-BLA terminal fiber recordings (both GCaMP7 and and RCaMP) in 2019-14. The RCaMP signal is an additional column for mice 849 and 850 that is calculated in the same way as above. 












FP_Compile
After processing the FP files, the corresponding rows from the MedPC file are brought together with their FP files. The DF/F0 column is scrubbed for any electric artifacts (signals below or above -100 or 100, respectively), z-scored for the entire 30 min session (nanzscore.m), and trimmed to the start pulse in the DIO column. Then for each of the variables (listed below), the closest FP timestamp to the MedPC timestamp of a given event is found and an Action ID is added to the matrix in a new column. Events that happen within rapid succession within each other, such as if a mouse nose poked twice in rapid succession, are filtered so as to only grab the initial response for analysis. Receptacle entries are further divided by those that follow reward receipt and those that do not (designated random receptacle entries). After Action ID’s have been assigned, these are used to index the FP data to pull 5 sec before and 10 sec after an event so that each event instance within a behavioral session can be aligned to event onset. When the correct nose poke/reward delivery events are collated in this way, data is also collated for 5 sec before tone onset to 5 sec after receptacle entry (reward retrieval) and stored in the rawtogether variable (more on this later). After collating the trials for each event, an .xlsx file with the prefix “MATLAB_”  is saved for each day file with separate sheets for each event in the generated individual events by day folder. Each column is the z-scored DF/F0 for that trial and the rows range from 5 sec before to 10 sec after the event. There is also a “counter” sheet that indicates the number of trials for each event. A timestamp file is also saved as a separate excel file (e.g. pipeline_2019_06 timestamps.xlsx) that is used for x-values when plotting later, as well as if one wants to plot the data in a program such as prism. The rawtogether variable is also saved as an intermediate variable to be used in the last step when plotting the combined action heatmaps. 




FP_Compile collates the following variables: 
correct nose poke: pokes into the active port during tone presentation, which is also the time of reward delivery
tone onset: onset of the auditory tone, both tonehit and tonemiss
incorrect nose poke: not preceded by another within 5 seconds
receptacle entry: presumed reward retrieval following a reward delivery
random receptacle entry: randrec, receptacle entry not following reward delivery
tonehit: tones that were eventually followed by reward
tonemiss: tones that were not followed by reward, i.e. the animal “missed” that reward opportunity
inactive nose pokes: pokes into the inactive port, not to be confused with incorrect nose pokes




Note: for the RCaMP mice, there are additional sheets for the RCaMP signal, aligned to the same action, with the prefix “r_” e.g. “r_correct”




Note: 2018-07 requires resampling of the data before compiling because the timestamp latency varied intermittently and unpredictably. Later experiments did not have this issue after the software was patched by Doric.




Note: FP_Compile is repeated twice, with the suffix “ref” and “sig”. These refer to taking either the reference or signal channel column during the compiling and not z-scoring the data. This was done to investigate possible movement artifacts. The outputs are the same as the standard FP_compile, except you will have one .xlsx file for reference and one for signal in the “generated individual events by day Reference vs Signal” folder. 
The default for these scripts is to only run for the example mouse shown in the manuscript because FP_Compile takes the longest time to run. Inside the script, if you want this done for all mice, comment “how_many_mice = 'selection';” and uncomment “how_many_mice = 'all';”












Mean_SEM_cal_indiv_plots
Enables easier plotting of mean events across days. Reads in the individual trials in the sheets from  “MATLAB_” files and generates means and standard errors (SEM) for each day. These values are saved as an intermediate .mat file (day_graph_data.mat) to allow for heatmap plotting in the next script. Days with acquisition issues are excluded here.












Actions_heatmaps_all_phases
The intermediate day_graph_data.mat file is loaded and the means are collated and plotted as a summary heatmap for each mouse and each event, with 5 sec before and after event onset plotted on the x-axis and each row corresponding to the average of all trials within a day. One heatmap is generated for each event (e.g. 813_Correct.png). These individual mouse heatmaps have Y labels for the day of each phase of training listed, which differs from the way it is displayed in the manuscript for simplicity. The mean and SEM are combined side by side for each day and saved as an .xlsx file in case plotting in a different manner is desired. A heatmap for incorrect nose pokes collapsed across animals is also constructed for the key days used in the combined action heatmaps (see tone_poke_rec heatmaps). The resulting files are found in the generated event summary graphs folder. 












Tone_poke_rec_heatmaps_by_mouse
The intermediate variable rawandnamesonly.mat containing rawtogether and the filenames for each row is loaded to generate the combined action heatmaps. Because there are variable latencies between tone onset, nose poke, and receptacle entry, a simple 5 sec before and after heatmap would not be able to effectively see trends in signal fluctuation aligned to these events across trials and days. Therefore, heatmaps are constructed by aligning in the following fashion:




5 sec before tone
Tone onset
2 sec after tone onset (at most)
2 sec before correct nose poke (at most)
Correct nose poke
0.5 sec after correct nose poke (at most)
0.5 sec before receptacle entry (at most)
Receptacle entry
5 sec after receptacle entry
(Note: if the latency was shorter than the intervals listed above, NaNs were inserted for proper alignment)




For each animal, a heatmap is constructed and aligned on the X-axis as noted above, with each row signifying a day. These individual mouse heatmaps have Y labels for the day of each phase of training listed, which differs from the way it is displayed in the manuscript. The key days identified for each experiment are also found and kept in a variable to plot as a collapsed heatmap, which happens at the end of this script.








Behavioral Summary
The remaining .xlsx file in the parent directory for each experiment (e.g. 2019-06 Fig 2B + S2.2A.xlsx) is used to generate an .xlsx file with the summary behavioral responses for each animal across days to facilitate easy plotting. The resulting file is in the output folder (e.g. Fig 2B + S2.2A MATLAB Behavior Output) and is named to reflect which figures it corresponds to. 








Other scripts of note
All the scripts above use a script named make_directory, the purpose of which is to create  directories that will contain the outputs of all the steps above. 




As well, each of these pipelines relies on a script named getPipelineVarsFilename, which will retrieve the location on disk of a Matlab variables file (.mat) containing the names of each of the directories specified at the beginning of the pipeline (more on this below). This is done for technical reasons and should not be changed. 




Many of the scripts above use a small script called sort_nat, which is used to ensure that the mouse filenames are sorted in order (MATLAB defaults to sorting e.g. timeout_10 before timeout_2, and this script will revert that to the expected order).








General Experimental Notes
The Pre-Training phase is internally called “Cued” and the Training phase is internally called “Timeout” or “TO”. Extinction is named “ZExt” or ”ZZExt” to facilitate proper alphabetical/chronological organizing.




Correct nose pokes and incorrect nose pokes were previously known as proper and improper nose pokes, respectively. The code may refer to them as such in some places.




________________












Experimental Key
2018-07 (BLA GCaMP6s Fig 3)
Mouse key
1: HB03
2: HB04
3: HB06
NOTE: We only use the first 19 mins of TO Day 13 for Mouse 3 (HB06) because of fiber loosening on its head after that point. 








2019-06 (BLA ACh3.0 Fig 2)
Mouse key:
1: 827
2: 813
3: 814
4: 820




 
2019-14 (NBM-BLA tf Fig 2 + ACh3.0/RCaMP Fig S2.5)
Mouse key
NBM-BLA
1: 860
2: 856
ACh3.0/RCaMP
        849: ACh3.0 + RCaMP
        850: ACh3.0 + RCaMP Sham
NOTE: Analysis for RCaMP mice stop after mean_SEM_calc_indiv_plots, only 856 and 860 continue for the two steps listed below. Heatmaps will not be generated for 849 and 850.