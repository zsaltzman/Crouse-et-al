%% Fig_2B_S2_2A_summary
%reads in MedPC data (behavioral responses csv), collates into groups, and exports an .xlsx 
clear;
load(getPipelineVarsFilename);

%% Experiment Specifics
folder = FP_PARENT_DIRECTORY;

%exp = Figs
exp = 'Fig 2B + S2.2A';

%mice in each group
mice = [827 813 814 820];
%Note: ordered as they are listed in the manuscript: 1-4. 


%Day labels
daykey = {'PT 1' ; 'PT 2'; 'PT 3'; 'PT 4' ; 'PT 5'; 'Training 1'; 'Training 2';... 
    'Training 3'; 'Training 4';'Training 5'; 'Training 6';'Training 7'; ...
    'Training 8';'Training 9'; 'Training 10'; 'Training 11'; 'Training 12'; ...
        'Training 13';'Training 14'; 'Training 15'; 'Training 16'; 'Training 17'; ...
        'Training 18';'Training 19'; 'Training 20'; 'Training 21'; ...
    'Ext 1'; 'Ext 2'; 'Ext 3'; 'Ext 4'};     


%% Import the data
raw = readcell([folder '\2019-06 ' exp '.xlsx']);

%Identify all unique mouse ID numbers and save in variable 
all_mouse_ID = unique(cell2mat(raw([2:end],1)));


miceorder = [];
micedataindex = 0;

groupdata = {'micedata'};
groupdataindex = {'micedataindex'};

%cycle through each mouse
%In the order the mice are in the manuscript [827 813 814 820]. Listed at
%top in same order although this code will grab 813 first based on
%ordering in all_mouse_ID
for num = [4 1 2 3]
          
    %Define mouse_ID number for the run of the for loop
    mouse_ID = all_mouse_ID(num);

    %skip mouse mice not found in group listing
    if sum(mouse_ID == mice) == 1 
        
        %Cut down raw to just current mouse
        %Remove the header from raw and reset variable to raw_test
        raw_test = raw(2:end,:);

        %Index all rows with mouse_ID and select those rows from raw_test
        raw_mouse = raw_test((cell2mat(raw_test(:,1)) == mouse_ID),:);
        
        nan_rows = num2cell(NaN(1,size(raw_mouse,2)));
        
        %add rows of NaNs to align behavior days across mice
        if mouse_ID == 814
           raw_mouse = [raw_mouse(1:25,:) ; nan_rows ; raw_mouse(26:end,:)];   
        else       
           raw_mouse = [raw_mouse; nan_rows]; 
        end

        %select group mouse belongs to
        if sum(mouse_ID == mice) == 1
            group = 1;
            micedataindex = micedataindex + 1;
            miceorder(micedataindex) = mouse_ID;

        end


        %Cycle through all days in a given mouse for each of the 9 variables 
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

end

%% Concat different groups into one array for prism plotting
%go through all variables and cat them as: eyfp,chr2,yoke
%then save them in xlsx file
allvariablename = {'inactive', 'rewards', 'receptacle', 'tones', 'incorrect', 'timeouts'};
allmouseorder = miceorder;
emptydaycell = {NaN};


for allvariable = 1:size(allvariablename,2)
    
    %pull micedata into the variable of the given name. Not strictly
    %necessary but based off of other code that concatenates multiple
    %groups of data so keeping consistent 
    eval([num2str(allvariablename{allvariable}),'= micedata{' num2str(allvariable), '};']);

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
    writecell(eval(allvariablename{allvariable}), [FP_OUTPUT_DIRECTORY '\' exp ' MATLAB Behavior Output.xlsx'], 'Sheet', allvariablename{allvariable})
    
end

%add a sheet with order of mice cat'd
writematrix(allmouseorder, [FP_OUTPUT_DIRECTORY '\' exp ' MATLAB Behavior Output.xlsx'], 'Sheet', 'mouseorder');

        
 