%% Fig_4_EF_S4_2AB_summary
%reads in MedPC data (behavioral responses csv), collates into groups, and exports an .xlsx 
clear;
load(getPipelineVarsFilename);

%% Experiment Specifics
folder = FP_RAW_DIRECTORY;

%exp = Figs
exp = 'Fig 5 B-C + S5.2A-B';

%mice in each group
salinemice = [1 5 12 16 19 26 33 37];
mecmice = [2 6 9 13 20 24 27 34 38];
scopmice = [3 10 14 17 21 28 32 35];
mec_scopmice = [4 8 11 18 22 25 29 36 40];



%Day labels
daykey = {'PT 1' ; 'PT 2'; 'PT 3'; 'PT 4' ; 'Training 1'; 'Training 2';...
    'Training 3'; 'Training 4';'Training 5'; 'Training 6';'Training 7'; ...
    'Training 8';'Training 9'; 'Training 10'; 'Training 11'; 'Training 12'; ...
    'Ext 1'; 'Ext 2'; 'Ext 3'};

%% Import the data
raw = readcell([ FP_RAW_DIRECTORY '\' exp '.xlsx']);


%Identify all unique mouse ID numbers and save in variable 
all_mouse_ID = unique(cell2mat(raw([2:end],1)));

salinedataindex = 0;
mecdataindex = 0;
scopdataindex = 0;
mec_scopdataindex = 0;

groupdata = {'salinedata'; 'mecdata'; 'scopdata'; 'mec_scopdata'};
groupdataindex = {'salinedataindex', 'mecdataindex', 'scopdataindex', 'mec_scopdataindex'};



salinemouseorder = [];
mecmouseorder = [];
scopmouseorder = [];
mec_scopmouseorder = [];

%Identify all unique box numbers and save in variable 
all_box_ID = unique(cell2mat(raw([2:end],7)));


%cycle through each mouse
for num = 1:length(all_mouse_ID)
   
           
    %Define mouse_ID number for the run of the for loop
    mouse_ID = all_mouse_ID(num);

    
        %Cut down raw to just current mouse
        %Remove the header from raw and reset variable to raw_test
        raw_test = raw(2:end,:);

        %Index all rows with mouse_ID and select those rows from raw_test
        raw_mouse = raw_test((cell2mat(raw_test(:,1)) == mouse_ID),:);

        %select group mouse belongs to
        if sum(mouse_ID == salinemice) == 1
            group = 1;
            salinedataindex = salinedataindex + 1;
            salinemouseorder(salinedataindex) = mouse_ID;
                         
        elseif sum(mouse_ID == mecmice) == 1
            group = 2; 
            mecdataindex = mecdataindex + 1;
            mecmouseorder(mecdataindex) = mouse_ID;
            
        elseif sum(mouse_ID == scopmice) == 1
            group = 3; 
            scopdataindex = scopdataindex + 1;
            scopmouseorder(scopdataindex) = mouse_ID;
            
        elseif sum(mouse_ID == mec_scopmice) == 1
            group = 4; 
            mec_scopdataindex = mec_scopdataindex + 1;
            mec_scopmouseorder(mec_scopdataindex) = mouse_ID;
            
            
        end
        
        
%         %select group mouse belongs to
%         if strcmp(raw_mouse{1,6},'Saline')
%             group = 1;
%             salinedataindex = salinedataindex + 1;
%             salinemouseorder(salinedataindex) = mouse_ID;
%                          
%         elseif strcmp(raw_mouse{1,6},'Mecamylamine')
%             group = 2; 
%             mecdataindex = mecdataindex + 1;
%             mecmouseorder(mecdataindex) = mouse_ID;
%             
%         elseif strcmp(raw_mouse{1,6},'Scopolamine')
%             group = 3; 
%             scopdataindex = scopdataindex + 1;
%             scopmouseorder(scopdataindex) = mouse_ID;
%             
%         elseif strcmp(raw_mouse{1,6},'Mec+Scop')
%             group = 4; 
%             mec_scopdataindex = mec_scopdataindex + 1;
%             mec_scopmouseorder(mec_scopdataindex) = mouse_ID;
%             
%             
%         end



        %Cycle through all days in a given mouse for each of the variables 
            for row = 1:size(raw_mouse,1)

                %index for placing data into groupdata cells
                variableindex = 1;

                %cycle through variables: inactive, rewards,
                %receptacle, tones, improper, timeouts
                %and grab the data
                for variable = [10 11 12 13 15 17]
                    eval([groupdata{group}, '{1,', num2str(variableindex), '}(', num2str(row), ',', num2str(groupdataindex{group}), ')=raw_mouse{', num2str(row),',', num2str(variable), '};']);
                    %groupdata{group}{1,variableindex}(row,groupdataindex{group}) = raw_mouse{row,variable};
                    variableindex = variableindex + 1;           
                end
                

            end


        %% Add headers, Create unique variable ID for data and clear variables
            cat(1,raw(1,:), raw_mouse);
        
            eval(['summarydata_', num2str(mouse_ID), '= raw_mouse;']);

            clear raw_mouse

    





end


%% Concat different groups into one array for prism plotting
%go through all variables that apply to this exp and cat them as: eyfp,chr2, with an extra col of
%NaN's to separate the groups
%then save them in xlsx file
allvariablename = {'inactive', 'rewards', 'receptacle', 'tones', 'incorrect', 'timeouts'};
emptycol = NaN(size(salinedata{1,1}(:,1),1),1);
allmouseorder = cat(2,salinemouseorder,NaN, mecmouseorder,NaN, scopmouseorder,NaN, mec_scopmouseorder);
emptydaycell = {NaN};


for allvariable = 1:size(allvariablename,2)
     
    %cat all group data
    eval([num2str(allvariablename{allvariable}),'= cat(2, salinedata{' num2str(allvariable), '},emptycol, mecdata{' num2str(allvariable),  '},emptycol, scopdata{' num2str(allvariable), '},emptycol, mec_scopdata{' num2str(allvariable), '});']);
    %allvariablename{allvariable} = cat(2, eyfpdata{allvariable}, chr2data{allvariable})
    
       
    %cat mouse number labels
    eval([num2str(allvariablename{allvariable}),'= cat(1, allmouseorder,', num2str(allvariablename{allvariable}), ');']);
    %allvariablename{allvariable} = cat(1,allmouseorder,allvariablename{allvariable})
    
    %turn cat'd group data into cell
    eval([num2str(allvariablename{allvariable}),'= num2cell(', num2str(allvariablename{allvariable}), ');']);
    
    %make cell with NaN first row + titles of number of days equal to rows - 1 
    days = cat(1, emptydaycell,daykey{1:size(eval(num2str(allvariablename{allvariable})),1)-1});
    
        
    %cat days with variables
    eval([num2str(allvariablename{allvariable}),'= cat(2, days,', num2str(allvariablename{allvariable}), ');']);
    
    
    %write cell to xlsx file
    writecell(eval(allvariablename{allvariable}), [FP_OUTPUT_DIRECTORY '\' exp ' MATLAB Output.xlsx'], 'Sheet', allvariablename{allvariable})
    
end

%add a sheet with order of mice cat'd
writematrix(allmouseorder, [FP_OUTPUT_DIRECTORY '\' exp ' MATLAB Output.xlsx'], 'Sheet', 'mouseorder');



        
 