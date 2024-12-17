function [power_out_matrix,loc_storage_matrix,big_storage_vec,curtailment,reg_power_loss_ratio,loc_power_loss_ratio,tot_effiency,loc_power_loss] = master_model(power_matrix, region, ...
         cable_power_cap, loc_power_cap, reg_power_cap, base_power_demand, loc_storage_cap, loc_storage_low, base_load_tol_constant, ...
         regional_efficiency, across_regions_efficiency, local_storage_efficiency, big_storage_efficiency, park_areas, Rated_Power_area)
% This functions calculates local storage vectors and power out vectors for each wind park in the system as well 
% as the shared regional storage vector and total curtailment of the system. The input is a power matrix where each
% column represent one park, a corresponding region array telling which region the parks belong to in order 
% (eg ["1","2","2","3","3"]), a power cap for the transmission cable, the base power demand for each region as a
% matrix, the local storage capacity, a lower limit for local storage as to prioritize charging, a tolerance factor 
% for deviation from the power demand, and efficiencies for local and regional storage as well as transmission cables. 
%
% - Step 1: (Power beyond cable) it checks all parks if they have excess power beyond the tranmission line, if so it 
%   store this in the local storage. 
% - Step 2: (Intra-region) it tries to balance all the parks within each region with regional surplus. If there is
%   regional surplus it charges local storages if they are below the limit. Also if the parks are below the limit and 
%   there is no surplus, it drops the power out by the tolerance amount to store in local. Lastly regardless surplus, 
%   tranmission occurs from the excess parks to the deficit park, ranking the ones with lowest local storage to be helped first.
% - Step 3: (Inter-regions) Remaining surplus of a region gets send across regions. Transmission prioritizes the parks 
%   with least local storage. Remaining surplus is then charged to the big regional storage.
% - Step 4: (Storage-discharge) If there is still deficit after the transmission described above the local storage discharges, 
%   and if that is not enough the regional storage discharges. 

    tic;

    % Get the size of the power matrix
    [n, T] = size(power_matrix);

    % Preallocate
    loc_storage_matrix = zeros(n,T);
    power_out_matrix = zeros(n,T);
    big_storage_vec = zeros(1,T);
    big_storage_vec(1) = 8000; %some start resorvior storage
    curtailment_loss = zeros(1,T);
    reg_power_loss = zeros(1,T);
    loc_power_loss = zeros(1,T);

    % Create info about the parks
    rated_powers = park_areas'*Rated_Power_area
    mean_rated_power = mean(rated_powers);
    mean_powers = mean(power_matrix,2)
    adjusted_mean_powers = mean_powers*mean_rated_power/mean(mean_powers)
    % Scale by mean power
    loc_storage_caps = adjusted_mean_powers*loc_storage_cap;
    loc_storage_lows = loc_storage_caps*loc_storage_low;
    cable_power_caps = cable_power_cap*adjusted_mean_powers;
    loc_power_caps = loc_storage_caps*loc_power_cap;

    % Differentiate unique regions
    regions = unique(region);

    % Adjust the minpowerout to the same size as the parr power matrix
    min_power_out = expand_demand_matrix(base_power_demand,n,T,region);
    %disp(min_power_out(:,end))
    %disp(sum(unique(min_power_out(:,end))))

    % Loop over each timestep
    for t = 2:T
        % Distriute the demand over all parks in the same region
        distributed_min_power_out = distribute_demand_by_parks(min_power_out(:,t),region, mean_powers);
        %disp(distributed_min_power_out)
        %disp(sum(distributed_min_power_out))

        % Calculate power balance for each park
        power_diff_vec = power_matrix(:, t) - distributed_min_power_out;

        % Calculate base load tolerance and its diff
        base_load_tol = distributed_min_power_out*base_load_tol_constant;  
        base_load_tol_diff = distributed_min_power_out - base_load_tol;   %diff tolerance
        
        % Set the currents big storage to the previous
        big_storage_vec(t) = big_storage_vec(t-1);
        
        % Calculate surplus and deficit values for each park
        surplus_parks = max(power_diff_vec, 0);     %if value>0 it gets stored, otherwise it is zero for that index
        deficit_parks = min(power_diff_vec, 0);    % If vulue<0 it gets stored, otherwise it is zero for that index
        
        % Step 1: handle power beyond caple_power_cap: store in local!

        % Create a logical array for parks exceeding the cable power cap
        parks_beyond = surplus_parks > (cable_power_caps - distributed_min_power_out);

        % If there are no parks with power beyond caple_power_cap, loc_storage remains the same
        if ~any(parks_beyond)
            loc_storage_matrix(:, t) = loc_storage_matrix(:, t-1); % Storage remains unchanged 
        % Else go inside a function that updated loc storage and surplus parks
        else 
            % Pre-allocate
            surplus_beyond = zeros(size(surplus_parks));

            % Get the indices of parks_beyond, Get the regions corresponding to these indices
            %beyond_regions_indices = str2double(region(parks_beyond));

            % calulcate the power beyond transmission cable
            surplus_beyond(parks_beyond) = surplus_parks(parks_beyond) - (cable_power_caps(parks_beyond) - distributed_min_power_out(parks_beyond));

            % Save the uncapped surplus
            uncapped_surplus = surplus_beyond(parks_beyond);
            
            % Apply cap
            surplus_beyond(parks_beyond) = min(uncapped_surplus, loc_power_caps(parks_beyond));
            
            % Save loss
            loc_power_loss(t) = sum(uncapped_surplus - surplus_beyond(parks_beyond));

            % Update local storage for the affected parks
            loc_storage_matrix(:, t) = loc_storage_matrix(:, t-1);
            loc_storage_matrix(parks_beyond, t) = loc_storage_matrix(parks_beyond, t) + surplus_beyond(parks_beyond);
    
            % Remove the excess from available distribution for affected parks
            %surplus_parks(parks_beyond) = surplus_parks(parks_beyond) - surplus_beyond(parks_beyond);  

            % Remove the excess from available distribution for affected
            % parks (improved)
            surplus_parks(parks_beyond) = cable_power_caps(parks_beyond) - distributed_min_power_out(parks_beyond);
    
            % Apply local storage cap and save the enrgy loss
            [loc_storage_matrix(:,t), curtailment_loss(t)] = cap_storage(loc_storage_matrix(:,t), loc_storage_caps);

        end
        
    
        % Step 2: Distribute local exess to parks in the same regions with deficit, prioritzes parks with least storage. Loops for each region.
    
        [surplus_parks,deficit_parks,region_excess_power,region_deficit_power,loc_storage_matrix,low_storage_indicies,loc_power_loss] = prioritized_loc_transmission(surplus_parks,deficit_parks,region,regions,regional_efficiency,local_storage_efficiency,loc_storage_lows,loc_storage_matrix,base_load_tol_diff,loc_power_loss,loc_power_caps,t);
    
        % Step 3: Distribute remaining surplus across/between regions. If there is power remainging (tot_remainging_surplus)
        % then distribute this to other regions, If there is still more, move to another region. 
     
        tot_Remaining_Surplus = sum(region_excess_power);
    
        % If there are any power left within regional transmission, handle it between regions
        if tot_Remaining_Surplus > 0
            
            % Find parks, only for the ones with deficit
            region_index_deficit = region_deficit_power > 0; 
            remaining_regions = regions(region_index_deficit);
            
            % Use function that distributes over all regions. Saves any remainder to big storage. 
            available_power = tot_Remaining_Surplus;
            [surplus_parks,deficit_parks,tot_Remaining_Surplus] = prioritized_reg_transmission(surplus_parks,deficit_parks,region,remaining_regions,across_regions_efficiency,loc_storage_matrix,t,available_power);
      
            % Update remaining surplus
            tot_Remaining_Surplus = sum(deficit_parks) + tot_Remaining_Surplus;
            
            % Charge big storage vector
            if tot_Remaining_Surplus > 0           %if tot balace > 0
                
                % Charge for maximum power 
                if tot_Remaining_Surplus > reg_power_cap
                    
                    % Saves the over capacity
                    over_capacity = tot_Remaining_Surplus - reg_power_cap;
                   
                    % Find out how much more all parks can store in local
                    loc_allocated_charge = loc_power_caps - (loc_storage_matrix(:, t) - loc_storage_matrix(:, t-1));
                    
                    % sort parks according to lowest storage
                    [~, sortedIndices] = sort(loc_storage_matrix(:, t), 'ascend');

                    % Allocate over charge based on sorted order of local storage
                    for idx = sortedIndices'
                        
                        % break when over_capacity is below zero and local storage is full
                        if over_capacity <= 0 
                            break;
                        elseif loc_storage_matrix(idx,t) >= loc_storage_caps(idx)
                            break;
                        else
                            % Decide allocation for this park (regional efficencies has already been applied, reverse this)
                            allocation = min(loc_allocated_charge(idx),over_capacity)/big_storage_efficiency;
                            
                            % Update local storage for this park and update remaining over capacity
                            loc_storage_matrix(idx,t) = loc_storage_matrix(idx,t) + allocation*local_storage_efficiency;
                            over_capacity = over_capacity - allocation;
                            
                        end
                    end
                    
                    % Apply cap 
                    [loc_storage_matrix(:,t),reg_power_loss(t)] = cap_storage(loc_storage_matrix(:,t), loc_storage_caps);

                    % Update remaining over_capacity
                    reg_power_loss(t) = reg_power_loss(t) + over_capacity;
                    
                    % Cap the amount that can be stored
                    tot_Remaining_Surplus = reg_power_cap;
                end
                
                % Update storage
                big_storage_vec(t) = big_storage_vec(t-1) + tot_Remaining_Surplus*big_storage_efficiency;
            end
        end
    
        % Step 4: After possible transmission, this section takes from local
        % storage if it is not empty otherwise from big.
    
        % Remove deficit energy from storage
        currentStorage = loc_storage_matrix(:,t) + deficit_parks;
        
        % Store the negative values, the ones that has not enough energy
        energy_left = currentStorage(currentStorage < 0);
    
        % Handles if the array is empty
        if isempty(energy_left)
            energy_left = 0;
        end
        energy_left = sum(energy_left);
        
        % Then replace all negative values with zeros, as big storage takes takes the capacity the local cannot
        currentStorage(currentStorage < 0) = 0;
    
        % Update local storage
        loc_storage_matrix(:,t) = currentStorage;
    
        % Set power to min as the storages handels the power
        power_out_matrix(:,t) = distributed_min_power_out;

        % Update big storage for the amount the locals cannot handle and Check power cap
        if energy_left > reg_power_cap

            % Calculate power loss and set big storage power to cap
            reg_power_loss(t) = energy_left - reg_power_cap;
            energy_left = reg_power_cap;
            
            % Find deficit park indicies.
            def_index = deficit_parks < 0;

            % Remove the power loss from the power out for deficit parks 
            power_out_matrix(def_index,t) = power_out_matrix(def_index,t) + reg_power_loss(t)/sum(def_index);
        end

        % Update storage vector
        big_storage_vec(t) = big_storage_vec(t) + energy_left;

        % If the storage gets emptied, lower power out for deficit parks
        if big_storage_vec(t) < 0
            
            %calculate deficit power and set storage to zero
            deficit_power = big_storage_vec(t);
            big_storage_vec(t) = 0;

            % Find deficit park indicies.
            def_index = deficit_parks < 0;

            % Remove power from deficit parks corresponding to the deficit
            power_out_matrix(def_index,t) =  power_out_matrix(def_index,t) + deficit_power/sum(def_index);
        end

        % Remove power from the parks below the storage limit
        if  ~(low_storage_indicies == false)  
            
            % Find the regions corresponding to low storage indices
            low_storage_regions = str2double(region(low_storage_indicies));

            % Map regions to their corresponding values in base_load_tol_diff
            adjustment_base_load_tol_diff = zeros(size(low_storage_indicies)); % Initialize adjustment term

            for i = 1:length(low_storage_indicies)
                % Find the region of the current low storage index
                current_region = low_storage_regions(i);

                % Assign the corresponding value from base_load_tol_diff
                adjustment_base_load_tol_diff(i) = base_load_tol_diff(current_region);
            end
            
            % Remove the adjusted base load diff that now has the same dimensions
            power_out_matrix(low_storage_indicies,t) = power_out_matrix(low_storage_indicies,t) - adjustment_base_load_tol_diff';
            
        end
    end

    % Compute the curtailment, power cap loss and total loss
    tot_loss = sum(curtailment_loss,"all");
    tot_power = sum(power_matrix,"all");
    tot_reg_power_loss = sum(reg_power_loss,"all");
    tot_loc_power_loss = sum(loc_power_loss,"all");
    tot_power_out = sum(power_out_matrix,"all");
    

    tot_effiency = (sum(loc_storage_matrix(:,T)) + sum(big_storage_vec(T) + tot_power_out))/tot_power*100;
    reg_power_loss_ratio = tot_reg_power_loss/tot_power*100;
    loc_power_loss_ratio = tot_loc_power_loss/tot_power*100;
    curtailment = tot_loss/tot_power*100;
    fel = 100-tot_effiency-reg_power_loss_ratio-loc_power_loss_ratio-curtailment
    toc;
end
