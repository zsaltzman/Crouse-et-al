%% behavior_summary_2020_04
%reads in MedPC data (behavioral responses csv), collates into groups, and exports an .xlsx 
clear;


%% Experiment Specifics
folder = 'C:\Users\rbc52\Google Drive\Grad School\Picciotto Lab Data\2020-04 FP\';
outputfolder = 'C:\Users\rbc52\Google Drive\Grad School\Picciotto Lab Data\2020-04 FP\MATLAB Output\';

%exp = Figs
exp = '2020-04 MedPC Summary';

%mice in each group
mice = [353 354 361 362 363 365 891 913];


%Day labels
daykey = {'PT 1' ; 'PT 2'; 'PT 3'; 'PT 4' ; 'Training 1'; 'Training 2';... 
    'Training 3'; 'Training 4';'Training 5'; 'Training 6';'Training 7'; ...
    'Ext 1'};     


%% Import the data
raw = readcell([folder exp '.xlsx']);

%Identify all unique mouse ID numbers and save in variable 
all_mouse_ID = unique(cell2mat(raw([2:end],1)));


miceorder = [];
micedataindex = 0;

groupdata = {'micedata'};
groupdataindex = {'micedataindex'};

%cycle through each mouse
%In the order the mice are in the manuscript [860 856]. Listed at
%top in same order although this code will grab 856 first based on
%ordering in all_mouse_ID
for num = 1:length(all_mouse_ID)
   
           
    %Define mouse_ID number for the run of the for loop
    mouse_ID = all_mouse_ID(num);

    %skip mouse mice not found in group listing
    if sum(mouse_ID == mice) == 1 
        
        %Cut down raw to just current mouse
        %Remove the header from raw and reset variable to raw_test
        raw_test = raw(2:end,:);

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
    writecell(eval(allvariablename{allvariable}), [outputfolder  exp ' Output.xlsx'], 'Sheet', allvariablename{allvariable})
    
end

%add a sheet with order of mice cat'd
writematrix(allmouseorder, [outputfolder  exp ' Output.xlsx'], 'Sheet', 'mouseorder');

        
 