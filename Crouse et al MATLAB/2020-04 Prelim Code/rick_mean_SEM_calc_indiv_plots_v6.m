%% rick_mean_SEM_calc_indiv_plots_v6
% built from rick_mean_SEM_calc_indiv_plots_v5_1_rcamp
%for use with FP_Compile_2020-04



%Previously known as: rick_Smooth_BIN_NEWv4
%changed name bc didn't make any sense. The first half of this program
%organizes all of the excel files with the previx "MATLAB_" and
%calculates means.
%v4 - nanmean and nanstd, like used for 2018-07 reanalysis
%v3 - improve graphs
%v2 - skip days when the fiber came off the head during the session

%reading in MATLAB_... files in 2019-06 App MATLAB folder


clear
close all;

exp = '2020-04';
% exp = '2018-07';

load(getPipelineVarsFilename);

codename = ['rick_mean_SEM' date];

%Groups
NBM_BLA = [890 891 894 907 913 914];
camkii_gcamp = [353 354 361 362 363 365];

%old groups left in to prevent bugs
gad_gcamp = [];
gach = [];
rcamp_gach = [];

%variables
variables = ["correct" "tone" "incorrect" "receptacle" "randrec" "tonehit" "tonemiss" "inactive"];
r_variables = ["r_correct" "r_tone" "r_incorrect" "r_receptacle" "r_randrec" "r_tonehit" "r_tonemiss" "r_inactive"];

% Make some pretty colors for later plotting
% http://math.loyola.edu/~loberbro/matlab/html/colorsInMatlab.html
red = [0.8500, 0.3250, 0.0980];
green = [0.4660, 0.6740, 0.1880];
cyan = [0.3010, 0.7450, 0.9330];
gray1 = [.7 .7 .7 .25];
light_red = [0.9294    0.8196    0.8196 .25];

%% Set folder/files
folder = FP_COMPILE_DIRECTORY ;
outputfolder = FP_INDIVIDUAL_DAY_GRAPH_DIRECTORY;
timestampfile = FP_TIMESTAMP_FILE;
outputfile = '2020-04 App MATLAB graph data';

MDIR_DIRECTORY_NAME = FP_MATLAB_VARS;
make_directory;

MDIR_DIRECTORY_NAME = outputfolder;
make_directory;

%file to skip
skips = [" "];


%% Import timestamp

%import timestamp
time = readmatrix(timestampfile);


%% read data

%Auto Import Data
C = dir([folder, '\*.xlsx']);
filenames = {C(:).name}.';

%exclude any temp files
filenames = filenames(~startsWith(filenames,'~'));


%initialize
datanames = cell(length(filenames),1);
graphdata = cell(length(filenames),1);
r_graphdata = graphdata;

for file = 1:length(filenames)
    % Create the full file name and partial filename
    fullname = [folder '\' C(file).name];
    
    
    datanames{file,1} = filenames(file);
    
    %skip bad days (fiber slipping off)
    if any(strcmpi(datanames{file}{1}(8:end-5),skips))
        
        %need to add this skip if statement below as well
        continue
        
        % Read in the data
    else
        sheets = sheetnames(fullname);
        
        %loop through all sheets, find the sheets whose name match one of
        %the variables. Pull that sheet and put it in graphdata in the col
        %that matches the idx of the var name in the variable string (e.g.
        %correct is col 1). If an rcamp mouse, pull the r_ sheet and put it
        %in r_graphdata
        for sheetsidx = 1:length(sheets)
            if any(strcmpi(sheets{sheetsidx},variables))
                %fix checking of mouse number, maybe change it to just making
                %a new r_graphdata variable
                
                graphdataidx=find(strcmpi(sheets{sheetsidx},variables));
                graphdata{file,graphdataidx} = readmatrix(fullname, 'Sheet', sheets{sheetsidx});
                
                %if it's an rcamp mouse, grab the corresponding r_ var 8 idx's
                %away
                if str2double(datanames{file,1}{1}(8:11)) == 849 || str2double(datanames{file,1}{1}(8:11)) == 850
                    r_graphdata{file,graphdataidx} = readmatrix(fullname, 'Sheet', ['r_' sheets{sheetsidx}]);
                end
                
            end
        end
        
    end
end




%% Calculate averages and sems

graphmean = cell(size(graphdata));
graphsem = cell(size(graphdata));

r_graphmean = graphmean;
r_graphsem = graphsem;

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
                
                %if a rcamp mouse, make r_vars from r_graphdata
                if str2num(datanames{file,1}{1}(8:11)) == 849 || str2num(datanames{file,1}{1}(8:11)) == 850
                    r_graphmean{file,variable} = nanmean(r_graphdata{file,variable},2);
                    r_graphsem{file,variable} = nanstd(r_graphdata{file,variable},0,2)/sqrt(size(r_graphdata{file,variable},2));
                end
                
                
            end
        end
    end
end

save(FP_INDIVIDUAL_DAY_DATA_FILENAME, 'graphmean', 'graphsem', 'datanames','r_graphmean', 'r_graphsem', '-v7.3');


%% Not plotting 



%% Make a Peri-Event Stimulus Plot and Heat Map
%transposing all variables for plotting purposes, using '

% graphtime = time';
% 
% 
% for file = 1:size(graphdata,1)
%     
%     %skip shitters
%     if any(strcmp(datanames{file}{1}(8:end-5),skips))
%         
%         continue
%         
%         
%         
%     else
%         
%         
%         %determine the day of mice
%         mouse_day = datanames{file,1}{1}(8:end-5);
%         
%         
%         %set mouse_ID
%         mouse_ID = datanames{file,1}{1}(8:11);
%         
%         if any(str2double(mouse_ID) == camkii_gcamp)
%             indicator = 'CaMKII-GCaMP';
%             ylimits = [-3 7];
%  
%         elseif any(str2double(mouse_ID) == NBM_BLA)
%             indicator = 'NBM-BLA';
%             ylimits = [-2 4.5];
%          
%         end
%         
%         %going to try plotting everything together but may need to either
%         %plot them completely separately or have channels sep and maybe a
%         %plot of just means together
%         
%         for action = 1:size(graphdata,2)
%             if ~isempty(graphdata{file,action})
%                 
%                 
%                 %Transpose and grab for plotting
%                 mean_allSignals = graphmean{file,action}';
%                 std_allSignals = graphsem{file,action}';
%                 allSignals = graphdata{file,action}';
%                 
%                 % Make a standard deviation fill for mean signal
%                 xx = [graphtime, fliplr(graphtime)];
%                 yy = [mean_allSignals + std_allSignals,...
%                     fliplr(mean_allSignals - std_allSignals)];
%                 
%                 if any(str2double(mouse_ID) == rcamp_gach)
%                     
%                     %Transpose and grab for plotting
%                     r_mean_allSignals = r_graphmean{file,action}';
%                     r_std_allSignals = r_graphsem{file,action}';
%                     r_allSignals = r_graphdata{file,action}';
%                     
%                     % Make a standard deviation fill for mean signal
%                     r_xx = [graphtime, fliplr(graphtime)];
%                     r_yy = [r_mean_allSignals + r_std_allSignals,...
%                         fliplr(r_mean_allSignals - r_std_allSignals)];
%                     
%                 end
%                 
%                 if any(str2double(mouse_ID) == rcamp_gach)
%                     tiledlayout(2,3)
%                     nexttile
%                 else %use subplot for non-rcamp bc spacing is weird 
%                     figure('Position',[100, 100, 600, 750], 'Visible', 'off')
%                     subplot(2,1,1)
%                 
%                 end
%                 
%                 
%                 
%                 hold on;
%                 
%                 
%                 %use the max of signal for now
%                 % Set specs for min and max value of event line.
%                 % Min and max of either std or one of the signal snip traces
%                 linemin = min(min(min(allSignals)),min(yy));
%                 linemax = max(max(max(allSignals)),max(yy));
%                 
%                 %come back to this after determining limits for groups
%                 %                 linemin = ylimits(1);
%                 %                 linemax = ylimits(2);
%                 
%                 % Plot the signals
%                 p1 = plot(graphtime, allSignals', 'color', gray1);
%                 
%                 
%                 xlim([-5 5]);
%                 %                 ylim(ylimits);
%                 
%                 % Plot the line next
%                 l1 = line([0 0], [linemin, linemax],...
%                     'color','cyan', 'LineStyle', '-', 'LineWidth', 2);
%                 
%                 %plot sem area
%                 h = fill(xx, yy, 'g'); % plot this now for overlay purposes
%                 set(h, 'facealpha', 0.25, 'edgecolor', 'none');
%                 
%                 % Plot the mean signals
%                 p2 = plot(graphtime, mean_allSignals, 'color', green, 'LineWidth', 1);
%                 hold off;
%                 
%               
%                 mouse_day = strrep(mouse_day,'_', ' ');
%                 title([indicator ' ' variables{action} ' ' mouse_day],'fontsize',16);
%                 ylabel('Z %\DeltaF/F0','fontsize',16);
%                 xticks([-5 -4 -3 -2 -1 0 1 2 3 4 5]);
%                 
%                 % Make an invisible colorbar so this plot aligns with one below it
%                 temp_cb = colorbar('Visible', 'off');
%                 
%                 % Heat map
%                 
%                 if any(str2double(mouse_ID) == rcamp_gach)
%                     nexttile(4)
%                 else
%                      subplot(2,1,2)
%                 end
%                 
%                 imagesc(graphtime, 1, allSignals, ylimits);% this is the heatmap
%                 xlim([-5 5]);
%                 
%                 set(gca,'YDir','normal') % put the trial numbers in better order on y-axis
%                 
%                 colormap jet;
%                 nanmap = [0 0 0; colormap];
%                 colormap(nanmap);
%                 
%                 title([num2str(mouse_ID) ' ' variables{action} ' Heat Map'],'fontsize',16)
%                 ylabel('Trial Number','fontsize',16)
%                 xlabel('Seconds from event onset','fontsize',16)
%                 cb = colorbar;
%                 
%                 xticks([-5 -4 -3 -2 -1 0 1 2 3 4 5]);
%                 
%                 if any(str2double(mouse_ID) == rcamp_gach)
%                     
%                     
%                 else
%                     ylabel(cb, 'Z %\DeltaF/F0','fontsize',16)
%                     
%                 end
%                 
%                 %% if rcamp, plot extra stuff
%                 if any(str2double(mouse_ID) == rcamp_gach)
%                     
%                     nexttile(2)
%                     
%                     hold on
%                     
%                     % Plot the signals
%                     r1 = plot(graphtime, r_allSignals', 'color', light_red);
%                     
%                     
%                     xlim([-5 5]);
%                     ylim(r_ylimits);
%                     
%                     % Plot the line next
%                     l1 = line([0 0], [linemin, linemax],...
%                         'color','cyan', 'LineStyle', '-', 'LineWidth', 2);
%                     
%                     %plot sem area
%                     r_h = fill(r_xx, r_yy, 'r'); % plot this now for overlay purposes
%                     set(r_h, 'facealpha', 0.25, 'edgecolor', 'none');
%                     
%                     % Plot the mean signals
%                     r2 = plot(graphtime, r_mean_allSignals, 'color', red, 'LineWidth', 1);
%                     hold off;
%                     
%                    
%                     xticks([-5 -4 -3 -2 -1 0 1 2 3 4 5]);
%                     
%                     % Make an invisible colorbar so this plot aligns with one below it
%                     temp_cb = colorbar('Visible', 'off');
%                     
%                     % Heat map
%                     nexttile(5)
%                     
%                     
%                     
%                     %                 imagesc(graphtime, 1, allSignals); %no ylimits
%                     imagesc(graphtime, 1, r_allSignals, r_ylimits);% this is the heatmap
%                     xlim([-5 5]);
%                     
%                     set(gca,'YDir','normal') % put the trial numbers in better order on y-axis
%                     
%                     colormap jet;
%                     nanmap = [0 0 0; colormap];
%                     colormap(nanmap);
%                     
%                     
%                     
%                     xlabel('Seconds from event onset','fontsize',16)
%                     cb = colorbar;
%                     ylabel(cb, 'Z %\DeltaF/F0','fontsize',16)
%                     xticks([-5 -4 -3 -2 -1 0 1 2 3 4 5]);
%                     
%                     % plot aggregate mean traces
%                     nexttile(3)
%                     
%                     hold on
%                     
%                     xlim([-5 5]);
%                     %                 ylim(ylimits);
%                     
%                     % Plot the line next
%                     l1 = line([0 0], [linemin, linemax],...
%                         'color','cyan', 'LineStyle', '-', 'LineWidth', 2);
%                     
%                     %plot sem area
%                     h = fill(xx, yy, 'g'); % plot this now for overlay purposes
%                     set(h, 'facealpha', 0.25, 'edgecolor', 'none');
%                     
%                     
%                     %plot sem area
%                     r_h = fill(r_xx, r_yy, 'r'); % plot this now for overlay purposes
%                     set(r_h, 'facealpha', 0.25, 'edgecolor', 'none');
%                     
%                     
%                     % Plot the mean signals
%                     p2 = plot(graphtime, mean_allSignals, 'color', green, 'LineWidth', 1);
%                     r2 = plot(graphtime, r_mean_allSignals, 'color', red, 'LineWidth', 1);
%                     hold off;
%                     
%                     % Make an invisible colorbar so this plot aligns with one below it
%                     temp_cb = colorbar('Visible', 'off');
%                     
%                 end
%                 
%                 
%                 
%                 %% save
%                 
%                 if any(str2double(mouse_ID) == rcamp_gach)
%                     set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
%                     print([outputfolder '\' indicator '\' indicator '_both_' mouse_day '_' variables{action}], '-dpng');
%                 else
%                     %Print png version of graph (save)
%                     print([outputfolder '\' indicator '\' indicator '_' mouse_day '_' variables{action}], '-dpng');
%                 end
%                 
%                 %close figure
%                 close all
%                 
%                 
%             end
%             
%         end
%         
%     end
%     
%     
% end


%print the version of the code used
fileID = fopen([outputfolder '\' date 'codeused.txt'],'w');
fprintf(fileID, codename);