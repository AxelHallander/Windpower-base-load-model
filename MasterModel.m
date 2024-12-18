function [power_out_matrix,loc_storage_matrix,big_storage_vec,curtailment,reg_power_loss_ratio,loc_power_loss_ratio, ...
         storage_and_tansmission_losses,tot_effiency,downtime,reg_capacity_loss_ratio] = MasterModel(power_matrix, region, ...
         cable_power_cap, loc_power_cap_ch, loc_power_cap_dch, reg_power_cap_ch, reg_power_cap_dch, base_power_demand, ...
         loc_storage_capacity, loc_storage_low, base_load_tol_constant, regional_efficiency, across_regions_efficiency, ...
         local_storage_efficiency, big_storage_efficiency,big_storage_cap)
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
    big_storage_vec(1) = 10000; %some start resorvior storage
    curtailment_loss = zeros(1,T);
    reg_power_loss = zeros(1,T);
    loc_power_loss = zeros(1,T);
    reg_capacity_loss = zeros(1,T);
    downtime = 0;

    
    % Differentiate unique regions
    regions = unique(region);

    % Adjust the minpowerout to the same size as the parr power matrix
    min_power_out = ExpandDemandMatrix(base_power_demand,n,T,region);
    
    % Loop over each timestep
    for t = 2:T
        % Distriute the demand over all parks in the same region
        distributed_min_power_out = DistributeDemandByParks(min_power_out(:,t),region);

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
        parks_beyond = surplus_parks > (cable_power_cap - distributed_min_power_out);

        % If there are no parks with power beyond caple_power_cap, loc_storage remains the same
        if ~any(parks_beyond)
            loc_storage_matrix(:, t) = loc_storage_matrix(:, t-1); % Storage remains unchanged 
        % Else go inside a function that updated loc storage and surplus parks
        else 
            % Pre-allocate
            surplus_beyond = zeros(size(surplus_parks));
             
            % calulcate the power beyond transmission cable
            surplus_beyond(parks_beyond) = surplus_parks(parks_beyond) - (cable_power_cap - distributed_min_power_out(parks_beyond));

            % Save the uncapped surplus
            uncapped_surplus = surplus_beyond(parks_beyond);
            
            % Apply cap
            surplus_beyond(parks_beyond) = min(uncapped_surplus, loc_power_cap_ch);
            
            % Save loss
            loc_power_loss(t) = sum(uncapped_surplus - surplus_beyond(parks_beyond));
            
            % Update local storage for the affected parks
            loc_storage_matrix(:, t) = loc_storage_matrix(:, t-1);
            loc_storage_matrix(parks_beyond, t) = loc_storage_matrix(parks_beyond, t) + surplus_beyond(parks_beyond)*local_storage_efficiency;
            
            % PREVIOUS ERROR: INSTEAD NEXT ROW
            % Remove the excess from available distribution for affected parks 
            % surplus_parks(parks_beyond) = surplus_parks(parks_beyond) - surplus_beyond(parks_beyond);  
            
            % set the affected surplus parks to the cable power cap, adjusted for diff
            surplus_parks(parks_beyond) = cable_power_cap - distributed_min_power_out(parks_beyond);

            % Apply local storage cap and save the enrgy loss
            [loc_storage_matrix(:,t), curtailment_loss(t)] = CapStorage(loc_storage_matrix(:,t), loc_storage_capacity);

        end
        

        % Step 2: Distribute local exess to parks in the same regions with deficit, prioritzes parks with least storage. Loops for each region.
    
        [surplus_parks,deficit_parks,region_excess_power,region_deficit_power,loc_storage_matrix,low_storage_indicies,loc_power_loss] = PrioLocTransmission(surplus_parks,deficit_parks,region,regions,regional_efficiency,local_storage_efficiency,loc_storage_low,loc_storage_matrix,base_load_tol_diff,loc_power_loss,loc_power_cap_ch,t);
    
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
            [surplus_parks,deficit_parks,tot_Remaining_Surplus] = PrioRegTransmission(surplus_parks,deficit_parks,region,remaining_regions,across_regions_efficiency,loc_storage_matrix,t,available_power);

            % Update remaining surplus
            tot_Remaining_Surplus = sum(deficit_parks) + tot_Remaining_Surplus;
            
            % Charge big storage vector
            if tot_Remaining_Surplus > 0           %if tot balace > 0
                
                % Charge for maximum power 
                if tot_Remaining_Surplus > reg_power_cap_ch
                    
                    % Saves the over capacity
                    over_capacity = tot_Remaining_Surplus - reg_power_cap_ch;
                   
                    % Stores in local if there still is some power
                    % available from before (this occurs at the same tame as step 1)
                    [loc_storage_matrix, over_capacity] = LocStorageCharge(loc_storage_matrix,loc_power_cap_ch,loc_storage_capacity,over_capacity,big_storage_efficiency,local_storage_efficiency,regional_efficiency,t);
    
                    % Apply cap 
                    [loc_storage_matrix(:,t),reg_power_loss(t)] = CapStorage(loc_storage_matrix(:,t), loc_storage_capacity);

                    % Update remaining over_capacity
                    reg_power_loss(t) = reg_power_loss(t) + over_capacity;
                    
                    % Cap the amount that can be stored
                    tot_Remaining_Surplus = reg_power_cap_ch;
                end
                
                % Update storage and cap it
                big_storage_vec(t) = big_storage_vec(t) + tot_Remaining_Surplus*big_storage_efficiency;
                [big_storage_vec(t), reg_capacity_loss(t)] = CapStorage(big_storage_vec(t),big_storage_cap);

            end
        end
    
        % Step 4: After possible transmission, this section takes from local
        % storage if it is not empty otherwise from big.
    
        % Compute discharge for local storages  
        discharge = max(deficit_parks,-loc_power_cap_dch);
        
        % Update Currentstorrage after removal of discharge
        currentStorage = loc_storage_matrix(:,t) + discharge;
        
        % Determine how much energy left the big storage needs to handle 
        energy_left = sum(deficit_parks-discharge)+sum(currentStorage(currentStorage < 0));

        % Then replace all negative values with zeros, as big storage takes takes the capacity the local cannot
        currentStorage(currentStorage < 0) = 0;

        % Update local storage
        loc_storage_matrix(:,t) = currentStorage;
    
        % Set power to min as the storages handels the power
        power_out_matrix(:,t) = distributed_min_power_out;

        % Update big storage for the amount the locals cannot handle and Check power cap
        if energy_left > reg_power_cap_dch

            % Calculate power loss and set big storage power to cap
            reg_power_loss(t) = energy_left - reg_power_cap_dch;
            energy_left = reg_power_cap_dch;

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
            downtime = downtime + 1;
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
    tot_reg_capacity_loss = sum(reg_capacity_loss);

    tot_effiency = (sum(loc_storage_matrix(:,T)) + big_storage_vec(T) + tot_power_out - big_storage_vec(1))/tot_power*100;
    reg_power_loss_ratio = tot_reg_power_loss/tot_power*100;
    loc_power_loss_ratio = tot_loc_power_loss/tot_power*100;
    reg_capacity_loss_ratio = tot_reg_capacity_loss/tot_power*100;
    curtailment = tot_loss/tot_power*100;
    storage_and_tansmission_losses = 100 - tot_effiency - reg_power_loss_ratio - loc_power_loss_ratio - curtailment - reg_capacity_loss_ratio;
    toc;

    disp((sum(power_out_matrix,'all')+sum(loc_storage_matrix(:,T))+big_storage_vec(T)- big_storage_vec(1)+ tot_loss+tot_reg_power_loss)/tot_power)
end
