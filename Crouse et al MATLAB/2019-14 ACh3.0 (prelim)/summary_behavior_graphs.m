%% summary_behavior_graphs

%4/29/20 - included sorting from FP_compile to avoid any issues of
%non-ascending date ordered data

%reads in MedPC data (behavioral responses csv), collates into groups, and exports an .xlsx 
clear;
load(getPipelineVarsFilename);

%% Experiment Specifics
folder = FP_PARENT_DIRECTORY;

%exp = Figs
exp = 'MedPC Summary';

%mice in each group
mice = [124 129 176 850 1012];


%Day labels
daykey = {'PT 1' ; 'PT 2'; 'PT 3'; 'PT 4' ; 'Training 1'; 'Training 2';... 
    'Training 3'; 'Training 4';'Training 5'; 'Training 6';'Training 7'; ...
    'Training 8';'Training 9'; 'Training 10'; 'Training 11'; 'Training 12'; ...
    'Ext 1'; 'Ext 2'; 'Ext 3'};     


%% Import the data
raw = readcell([folder '\2019-14 ' exp '.xlsx']);

%Identify all unique mouse ID numbers and save in variable 
all_mouse_ID = unique(cell2mat(raw([2:end],1)));



miceorder = [];
micedataindex = 0;

groupdata = {'micedata'};
groupdataindex = {'micedataindex'};


%cut off column headings and sort by animal ID, ascending order, use date
%(col 2) for multiple days of same animal

%Remove the header from raw and reset variable to raw_test
raw_test_presort = raw(2:end,:);

%sort by animal (col 1) and for tie breakers, sort by the date (col 2)
[~,sortidx] = sortrows(cell2mat(raw_test_presort(:,[1 2])), [1 2]);
raw_test = raw_test_presort(sortidx,:);
    
        
        
        
%cycle through each mouse



%set for loop num
nummer = 1:size(all_mouse_ID,1);
for num = nummer
   
           
    %Define mouse_ID number for the run of the for loop
    mouse_ID = all_mouse_ID(num);

    %skip mouse mice not found in group listing
    if sum(mouse_ID == mice) == 1 
        
      
        
        %Cut down raw_test to just current mouse
        %Index all rows with mouse_ID and select those rows from raw_test
        raw_mouse = raw_test((cell2mat(raw_test(:,1)) == mouse_ID),:);
        

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

        
 