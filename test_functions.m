%paths
path_axel = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\test_data.grib";
path_vilgot = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\Windpower-base-load-model\test_data.grib";

%Park and turbine characteristics
Rated_Power = 5*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;


%Read data and windspeeds
Wind_Speed = ReadWindData(path_axel);

%Calculate power
Sum = false;
Power_Values = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed,Sum);

%plot
Y1 = Power_Values(1,1,:);
Y1 = reshape(Y1,1,length(Y1));

Y2 = Power_Values(1,2,:);
Y2 = reshape(Y2,1,length(Y2));

Y3 = Power_Values(2,1,:);
Y3 = reshape(Y3,1,length(Y3));

Y4 = Power_Values(2,2,:);
Y4 = reshape(Y4,1,length(Y4));

X = 1:length(Y1);

figure(1)
hold on
plot(X,Y1)
plot(X,Y2)
plot(X,Y3)
plot(X,Y4)
hold off

figure(2)
plot(X,Y1+Y2+Y3+Y4)

%tot power
power_vec = Y1 + Y2 + Y3 + Y4;

%% Automized section
Sum = true;
power_vec2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed,Sum);
[p,s] = Power_model(power_vec);
plot(X,p)





%%
path_spa = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\spa_gri_18-23.grib";
path_cre = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\grece_crete18-23.grib";

%Read data and windspeeds
Wind_Speed_spa = ReadWindData(path_spa);
Wind_Speed_gre = ReadWindData(path_cre);

%%

%Park and turbine characteristics
Rated_Power = 5; %*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;

%power calc
Sum = true;
power_vec = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_spa,Sum);
power_vec2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_gre,Sum);


%%
tic;
power_matrix = [power_vec; power_vec2];    % Power output data for each park over time
region = ["1","1"]; %regions must be in order, if S and E then it switches order to [E;S], must also only be one letter
regions = unique(region);  % Get unique regions ('S' and 'SE')

%pre-allocate arrays: Initialize power and storage matrices (T x N)
n = 2; %number of parks
X = 1:length(power_vec);
T = length(X); % number of timesteps
loc_storage_matrix = zeros(n,T);
power_out_matrix = zeros(n,T);
big_storage_vec = zeros(1,T);
energy_loss = zeros(1,T);
big_storage_charge = zeros(1,T);

%load max and min, all are in GIGA
cable_power_cap = 4;        
min_power_out = 2;              %rename: power demand
loc_storage_cap = 50;      
loc_storage_low = 10;
base_load_tol = min_power_out*0.9;                  %tolerance too store in local
base_load_tol_diff = min_power_out-base_load_tol;   %diff tolerance

%efficiency for storage and transmission
regional_efficiency = 0.99;
across_regions_efficiency = 0.95;
local_storage_efficiency = 0.8;
big_storage_efficiency = 0.9;

%%
for t = 2:T
    % Calculate power balance for each park
    power_diff_vec = power_matrix(:, t) - min_power_out; 
    
    % Set the currents big storage to the previous
    big_storage_vec(t) = big_storage_vec(t-1);
    
    % Calculate surplus and deficit values for each park
    surplus_parks = max(power_diff_vec, 0);     %if value>0 it gets stored, otherwise it is zero for that index
    deficit_parks = min(power_diff_vec, 0);    % If vulue<0 it gets stored, otherwise it is zero for that index
    diff_parks = surplus_parks + deficit_parks;
    
    
    %Step 1: handle power beyond caple_power_cap: store in local!
    
    % Create a logical array for parks exceeding the cable power cap
    parks_beyond = surplus_parks > (cable_power_cap - min_power_out);
    
    % If there are no parks with power beyond caple_power_cap, loc_storage remains the same
    if ~any(parks_beyond)
        loc_storage_matrix(:, t) = loc_storage_matrix(:, t-1); % Storage remains unchanged 
    % Else go inside a function that updated loc storage and surplus parks
    else 
        % pre-allocate
        surplus_beyond = zeros(size(surplus_parks));

        % calulcate the power beyond transmission cable
        surplus_beyond(parks_beyond) = surplus_parks(parks_beyond) - (cable_power_cap - min_power_out);
        
        % Update local storage for the affected parks
        loc_storage_matrix(:, t) = loc_storage_matrix(:, t-1);
        loc_storage_matrix(parks_beyond, t) = loc_storage_matrix(parks_beyond, t) + surplus_beyond(parks_beyond);

        % Remove the excess from available distribution for affected parks
        surplus_parks(parks_beyond) = surplus_parks(parks_beyond) - surplus_beyond(parks_beyond);  

        [loc_storage_matrix(:,t), energy_loss(t)] = cap_storage(loc_storage_matrix(:,t), loc_storage_cap);
    end
    
    % Remaining surplus and total deficit
    tot_Surplus = sum(surplus_parks);
    tot_Deficit = sum(deficit_parks);
    balance = tot_Surplus + tot_Deficit;

    % Step 2: Distribute local exess to parks in the same regions with
    % deficit, prioritzes parks with least storage. Loops for each region.

    [surplus_parks,deficit_parks,region_excess_power,region_deficit_power,loc_storage_matrix,low_storage_indicies] = prioritized_loc_transmission(surplus_parks,deficit_parks,region,regions,regional_efficiency,local_storage_efficiency,loc_storage_low,loc_storage_matrix,base_load_tol_diff,t);

    % Step 3: Distribute remaining surplus across/between regions. If there is power remainging (tot_remainging_surplus)
    % then distribute this to other regions, If there is still more, move to another region. 
 
    tot_Remaining_Surplus = sum(region_excess_power);
    tot_Remaining_Deficit = sum(region_deficit_power);

    % If there are any power left within regional transmission, handle it between regions
    if tot_Remaining_Surplus > 0
        
        %find parks, only for the ones with deficit
        region_index_deficit = region_deficit_power > 0; 
        remaining_regions = regions(region_index_deficit);
       
        
        %remaining_regions = region_deficit_power > 0; DETTA KAN VARA BRA
        %disp(remaining_regions)
        
        %Use function that distributes over all regions. Saves any remainder to big storage. 
        available_power = tot_Remaining_Surplus;
        [surplus_parks,deficit_parks,tot_Remaining_Surplus] = prioritized_reg_transmission(surplus_parks,deficit_parks,region,remaining_regions,across_regions_efficiency,loc_storage_matrix,t,available_power);
  
        %Update remaining surplus
        tot_Remaining_Surplus = sum(deficit_parks) + tot_Remaining_Surplus;
        big_storage_charge(t) = tot_Remaining_Surplus;
        
        if tot_Remaining_Surplus > 0           %if tot balace > 0
            big_storage_vec(t) = big_storage_vec(t-1) + tot_Remaining_Surplus*big_storage_efficiency;
        end
    end

    % Step 4: After possible transmission, this section takes from local
    % storage if it is not empty otherwise from big.

    %Remove deficit energy from storage
    currentStorage = loc_storage_matrix(:,t) + deficit_parks;
    
    %store the negative values, the ones that has not enough energy
    energy_left = currentStorage(currentStorage < 0);

    if isempty(energy_left)
        energy_left = 0;
    end
    energy_left = sum(energy_left);
    
    %then replace all negative values with zeros, as big storage takes takes the capacity the local cannot
    currentStorage(currentStorage < 0) = 0;

    %update local storage
    loc_storage_matrix(:,t) = currentStorage;

    %update big storage for the amount the locals cannot handle
    big_storage_vec(t) = big_storage_vec(t) + energy_left;

    %set power to min as the storages handels the power
    power_out_matrix(:,t) = min_power_out;
    
    %remove power from the parks below the storage limit
    if  ~(low_storage_indicies == false)  
        power_out_matrix(low_storage_indicies,t) = power_out_matrix(low_storage_indicies,t) - base_load_tol_diff;
    end
end

tot_loss = sum(energy_loss,"all");
tot_power = sum(power_matrix,"all");
curtailment = tot_loss/tot_power*100;
%%
figure(5)
plot(X,loc_storage_matrix(2,:))
figure(6)
plot(X,power_out_matrix(2,:))
figure(7)
plot(X,big_storage_vec)
