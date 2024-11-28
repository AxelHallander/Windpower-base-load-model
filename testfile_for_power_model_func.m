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

%% Detta är en bättre approach!! Skippar en for loop, toppen!

% Initialize power and storage matrices (T x N)

%X-vector
X = 1:length(power_vec);

%pre-allocate arrays
n = 2; %number of parks
T = length(X); % number of timesteps

power_matrix = [power_vec; power_vec2];    % Power output data for each park over time
region = ['1','1']; %regions must be in order, if S and E then it switches order to [E;S], must also only be one letter
regions = unique(region);  % Get unique regions ('S' and 'SE')

loc_storage_matrix = zeros(n,T);
power_out_matrix = zeros(n,T);
big_storage_vec = zeros(1,T);
defi = zeros(1,T);
el = zeros(1,T);

%load max and min
cable_power_cap = 4;        %*10^9;
min_power_out = 2;          %*10^9;
loc_storage_cap = 20;       %*10^9; %? It will decrease when adding more parks

%efficiency for storage and transmission
regional_efficiency = 0.99;
across_regions_efficiency = 0.95;

for t = 2:T
    % Calculate power balance for each park
    power_diff_vec = power_matrix(:, t) - min_power_out; 
    
    % Set the currents big storage to the previous
    big_storage_vec(t) = big_storage_vec(t-1);
    
    % Calculate surplus and deficit values for each park
    surplus_parks = max(power_diff_vec, 0);     %if value>0 it gets stored, otherwise it is zero for that index
    deficit_parks = min(power_diff_vec, 0);    % If vulue<0 it gets stored, otherwise it is zero for that index
    diff_parks = surplus_parks + deficit_parks;
  
    
    %First case: handel power beyond caple_power_cap: store in local!
    if max(surplus_parks) > cable_power_cap - min_power_out
        %caculate power beyond cable_power_cap
        surplus_beyond_power_cable = max(surplus_parks - (cable_power_cap - min_power_out),0);
        
        %store the excess
        loc_storage_matrix(:,t) = loc_storage_matrix(:,t-1) + surplus_beyond_power_cable;

        %Remove the excess from available distrubution
        surplus_parks = surplus_parks - surplus_beyond_power_cable;
        
        %Set these parks power_out to cable_power_cap
        surplus_beyond_power_cable(surplus_beyond_power_cable ~= 0) = cable_power_cap; %replace the non zero indicies to max cable out
        power_out_matrix(:,t) = surplus_beyond_power_cable;
    else
        loc_storage_matrix(:,t) = loc_storage_matrix(:,t-1);      %otherwise, storage reamains the same, is not need here when implemented below
    end

    % Remaining surplus and total deficit
    tot_Surplus = sum(surplus_parks);
    tot_Deficit = sum(deficit_parks);
    balance = tot_Surplus + tot_Deficit;

    % Step 1: Distribute local exess to parks in the same regions with
    % deficit, prioritzes parks with least storage. Loops for each region.

    [surplus_parks,deficit_parks,region_excess_power,region_deficit_power] = prioritized_loc_transmission(surplus_parks,deficit_parks,region,regions,regional_efficiency,loc_storage_matrix,t);
    
    % Step 2: Distribute remaining surplus across/between regions. If there is power remainging (tot_remainging_surplus)
    % then distribute this to other regions, If there is still more, move to another region. 
 
    tot_Remaining_Surplus = sum(region_excess_power);
    tot_Remaining_Deficit = sum(region_deficit_power);
    
    % If there are any power left within regional transmission, handle it between regions
    if tot_Remaining_Surplus > 0
        
        %find parks, only for the ones with deficit
        region_index_deficit = find(region_deficit_power > 0);      
        remaining_regions = regions(region_index_deficit);
      
        %Use function that distributes over all regions. Saves any remainder to big storage. 
        available_power = tot_Remaining_Surplus;
        [surplus_parks,deficit_parks,tot_Remaining_Surplus] = prioritized_reg_transmission(surplus_parks,deficit_parks,region,remaining_regions,across_regions_efficiency,loc_storage_matrix,t,available_power);
  
        %Update remaining surplus
        tot_Remaining_Surplus = sum(deficit_parks) + tot_Remaining_Surplus;

        if tot_Remaining_Surplus > 0           %if tot balace > 0
            big_storage_vec(t) = big_storage_vec(t-1) + tot_Remaining_Surplus;
        end
    end

    % Step 3:After possible transmission, this section takes from local
    % storage if it is not empty otherwise from big.

    %Remove deficit energy from storage
    currentStorage = loc_storage_matrix(:,t) + deficit_parks;
    
    %store the negative values, the ones that has not enough energy
    energy_left = currentStorage(currentStorage < 0);

    if isempty(energy_left)
        energy_left = 0;
    end
    energy_left = sum(energy_left);
    
    %then replace all negative values with zeros, as big storage takes
    %takes the capacity the local cannot
    currentStorage(currentStorage < 0) = 0;

    %update local storage
    loc_storage_matrix(:,t) = currentStorage;

    %update big storage for the amount the locals cannot handle
    big_storage_vec(t) = big_storage_vec(t) + energy_left;

    %set power to min as the storages handels the power.
    power_out_matrix(:,t) = min_power_out;
end



%%
%loc_storage_matrix(:,1) = [];
%power_out_matrix(:,1) = [];

figure(5)
plot(X,loc_storage_matrix(1,:))
figure(6)
plot(X,power_out_matrix(1,:))
figure(7)
plot(X,big_storage_vec)
