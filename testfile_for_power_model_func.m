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
region = ['1','2']; %regions must be in order, if S and E then it switches order to [E;S], must also only be one letter
regions = unique(region);  % Get unique regions ('S' and 'SE')

loc_storage_matrix = zeros(n,T);
power_out_matrix = zeros(n,T);
big_storage_vec = zeros(1,T);

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
        big_storage_vec(t) = big_storage_vec(t-1);
    end

    % Remaining surplus and total deficit
    tot_Surplus = sum(surplus_parks);
    tot_Deficit = sum(deficit_parks);
    balance = tot_Surplus + tot_Deficit;
    
    % if balance is exacly zero, all has min_power.
    if balance == 0
        power_out_matrix(:,t) = min_power_out;
        big_storage_vec(t) = big_storage_vec(t-1);
        
    % if balance > 0, all surplus can be distributed evenly for all parks,
    % or store excess locally or in big storage 
    elseif balance > 0 
        %power_out_matrix(:,t) = balance/n + min_power_out;
        %big_storage_vec(t) = big_storage_vec(t-1);

        %store excess in big storage, assumes that suplus distributes to
        %the deficit parks also. Need to Introduce some effeciencies. 
        power_out_matrix(:,t) = min_power_out;
        big_storage_vec(t) = big_storage_vec(t-1) + balance;

        %Do this instead in the next part, in loop for each region. Then we
        %dont need the elseif statements and we introduce the efficiencies

    % if balance < 0, 
    elseif balance < 0
        
        %This should handle a re-distrubution of power

        % Step 1: Distribute local exess to parks in the same regions with
        % deficit, prioritzes parks with least storage. Loops for each region.
        
        region_excess_power = zeros(1,length(regions));
        region_deficit_power = zeros(1,length(regions));
    
        for r = 1:length(regions)
            % Get indices of parks in the current region
            region_Indices = find(region == regions(r));
          
            % Extract regional surplus and deficit
            regional_Surplus = surplus_parks(region_Indices);
            regional_Deficit = deficit_parks(region_Indices);
        
            % Total regional surplus and deficit
            tot_Regional_Surplus = sum(regional_Surplus);
            tot_Regional_Deficit = -sum(regional_Deficit);

            % Attempt to cover the regional deficit using regional surplus
            if tot_Regional_Surplus >= tot_Regional_Deficit
                % Cover the entire regional deficit with regional surplus
                region_excess_power(r) = (tot_Regional_Surplus - tot_Regional_Deficit)*regional_efficiency;
            
            % Distribute remaining regional surplus to parks with least local storage
            else
                % Sort parks by their current local storage (ascending order)
                [~, sortedIndices] = sort(loc_storage_matrix(region_Indices, t-1), 'ascend');
        
                % Allocate remaining surplus based on sorted order of local storage
                for idx = sortedIndices'
                    if tot_Regional_Surplus <= 0
                        break;
                    end
                    % Determine the amount to allocate to this park
                    allocation = min(abs(deficit_parks(region_Indices(idx))), tot_Regional_Surplus);
                    
                    % Update the affected parks
                    surplus_parks(region_Indices(idx)) = regional_Surplus(idx) - allocation; %kan vara konstig
                    deficit_parks(region_Indices(idx)) = regional_Deficit(idx) + allocation;

                    % Update the overall balance
                    tot_Regional_Surplus = tot_Regional_Surplus - allocation/regional_efficiency;
                    tot_Regional_Deficit = tot_Regional_Deficit - allocation/regional_efficiency; % kan tas bort
                end 
            end
            region_deficit_power(r) = tot_Regional_Deficit;
        end
        
    
        % Step 2: Distribute remaining surplus across/between regions. If there is power remainging (tot_remainging_surplus)
        % then distribute this to other regions, If there is still more, move to another region. 
     
        tot_Remaining_Surplus = sum(region_excess_power);
        tot_Remaining_Deficit = sum(region_deficit_power);
        
        % If there are any power left within regional transmission, handle
        % it between regions
        if tot_Remaining_Surplus > 0
    
            %find parks, only for the ones with deficit
            region_index_deficit = find(region_deficit_power > 0);      
            remaining_regions = regions(region_index_deficit);
          
            %Use function that distributes over all regions. Saves any
            %remainder to big storage. 
            available_power = tot_Remaining_Surplus;
    
            [surplus_parks,deficit_parks] = prioritized_transmission(surplus_parks,deficit_parks,region,remaining_regions,across_regions_efficiency,loc_storage_matrix,t,available_power);
           
            tot_Remaining_Surplus = sum(surplus_parks + deficit_parks);
            if tot_Remaining_Surplus > 0           %this wont do anything now... but if we combine the part with balace > 0.
                big_storage_vec(t) = big_storage_vec(t-1) + tot_Remaining_Surplus*across_regions_efficiency;
            end
        end

        % Step 3:After possible transmission, this section takes from local
        % storage if it is not empty otherwise from big.

        %Remove deficit energy from storage
        currentStorage = loc_storage_matrix(:,t-1) + deficit_parks;
      
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
        big_storage_vec(t) = big_storage_vec(t-1) + energy_left;

        %set power to min as the storages handels the power.
        power_out_matrix(:,t) = min_power_out;

    end
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
