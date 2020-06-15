%% Fig_4EF_S4_2AB_summary
%reads in MedPC data (behavioral responses csv), collates into groups, and exports an .xlsx 
clear;
load(getPipelineVarsFilename);

%% Experiment Specifics
folder = FP_RAW_DIRECTORY;

%exp = Figs
exp = 'Fig 4E-F + S4.2A-B';

%mice in each group
eyfpmice = [605 633 643 650 659];
chr2mice = [604 608 640 649 658 662];


%Day labels
daykey = {'PT 1' ; 'PT 2'; 'PT 3'; 'PT 4' ; 'Training 1'; 'Training 2';... 
    'Training 3'; 'Training 4';'Training 5'; 'Training 6';'Training 7'; ...
    'Training 8';'Training 9'; 'Training 10'; 'Training 11'; 'Training 12'; ...
    'Ext 1'; 'Ext 2'; 'Ext 3'};     


%% Import the data
raw = readcell([FP_RAW_DIRECTORY '\' exp '.xlsx']);

%Identify all unique mouse ID numbers and save in variable 
all_mouse_ID = unique(cell2mat(raw([2:end],1)));


eyfpdataindex = 0;
chr2dataindex = 0;

groupdata = {'eyfpdata'; 'chr2data'};
groupdataindex = {'eyfpdataindex','chr2dataindex'};

eyfpmouseorder = [];
chr2mouseorder = [];




%cycle through each mouse
for num = 1:length(all_mouse_ID)
   
           
    %Define mouse_ID number for the run of the for loop
    mouse_ID = all_mouse_ID(num);

    %skip mouse mice not found in group listings
    if sum(mouse_ID == eyfpmice) == 1 || sum(mouse_ID == chr2mice) == 1 
        
        %Cut down raw to just current mouse
        %Remove the header from raw and reset variable to raw_test
        raw_test = raw(2:end,:);

        %Index all rows with mouse_ID and select those rows from raw_test
        raw_mouse = raw_test((cell2mat(raw_test(:,1)) == mouse_ID),:);

        %select group mouse belongs to
        if sum(mouse_ID == eyfpmice) == 1
            group = 1;
            eyfpdataindex = eyfpdataindex + 1;
            eyfpmouseorder(eyfpdataindex) = mouse_ID;
                         
        elseif sum(mouse_ID == chr2mice) == 1
            group = 2; 
            chr2dataindex = chr2dataindex + 1;
            chr2mouseorder(chr2dataindex) = mouse_ID;
            
        end


        %Cycle through all days in a given mouse for each of the 9 variables 
            for row = 1:size(raw_mouse,1)

                %index for placing data into groupdata cells
                variableindex = 1;

                %cycle through variables: inactive, rewards,
                %receptacle, tones,  incorrect, timeouts, stims
                %and grab the data
                for variable = [ 10 11 12 13 15 17 18]
                    
                    %was recorded as individual stims instead of sets of 40 (2 sec of 20 Hz) so divide by 40
                    %to give number of pules trains given
                    if variable == 18
                       raw_mouse{row,variable} = raw_mouse{row,variable}/40;   
                    end
                    
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
%go through all variables that apply to this exp and cat them as: eyfp,chr2, with an extra col of
%NaN's to separate the groups
%then save them in xlsx file
allvariablename = { 'inactive', 'rewards', 'receptacle', 'tones', 'incorrect', 'timeouts', 'stims'};
emptycol = NaN(size(eyfpdata{1,1}(:,1),1),1);
allmouseorder = cat(2,eyfpmouseorder, NaN,chr2mouseorder);
emptydaycell = {NaN};


for allvariable = 1:size(allvariablename,2)
    
    %cat all group data
    eval([num2str(allvariablename{allvariable}),'= cat(2, eyfpdata{' num2str(allvariable), '}, emptycol, chr2data{' num2str(allvariable), '});']);
    %allvariablename{allvariable} = cat(2, eyfpdata{allvariable}, emptycol, chr2data{allvariable})
    

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

