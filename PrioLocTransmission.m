function [surplus_parks,deficit_parks,region_excess_power,region_deficit_power,loc_storage_matrix,indices_below_limit,loc_power_loss] = PrioLocTransmission(surplus_parks, ...
         deficit_parks,region,regions,regional_efficiency,local_storage_efficiency,loc_storage_low,loc_storage_matrix,base_load_tol_diff,loc_power_loss,loc_power_capacity,t)
    
    % Step 2: (Intra-region) Distribute local exess to parks in the same regions with deficit, prioritzes parks with least storage. If the parks are within the power demand tolerance 
    % and their storage is below the limit then the outout is lowered to store the difference in the local storage. Also, in the case of surplus, transmission occurs to the 
    % parks with storages below the limit and stores energy there. Loops for each region.
    
    % Pre-allocate
    region_excess_power = zeros(1,length(regions));
    region_deficit_power = zeros(1,length(regions));
    
    % Preset indices_below_limit
    indices_below_limit = false;

    %loop for each unique region
    for r = 1:length(regions)
        % Get indices of parks in the current region
        region_Indices = find(region == regions(r));
      
        % Extract regional surplus and deficit
        regional_Surplus = surplus_parks(region_Indices);
        regional_Deficit = deficit_parks(region_Indices);
    
        % Total regional surplus and deficit
        tot_Regional_Surplus = sum(regional_Surplus);
        tot_Regional_Deficit = -sum(regional_Deficit);
        
        % Check if any parks in this region have local storage below the limit (logical array)
        parks_below_limit = loc_storage_matrix(region_Indices, t) < loc_storage_low;

        % If there are parks below this limit:
        if any(parks_below_limit)
            % If any of the parks how low storage, drop power level to store energy
            [loc_storage_matrix,indices_below_limit,loc_power_loss] = LocStorageTolPower(loc_storage_matrix,local_storage_efficiency,loc_power_capacity,base_load_tol_diff,region_Indices,parks_below_limit,loc_power_loss,t,r);
        end
        parks_below_limit = loc_storage_matrix(region_Indices, t) < loc_storage_low;
        
        % Attempt to cover the regional deficit using regional surplus
        if tot_Regional_Surplus >= tot_Regional_Deficit
            
            % Cover the entire regional deficit with regional surplus
            region_excess_power(r) = (tot_Regional_Surplus - tot_Regional_Deficit)*regional_efficiency;
            region_deficit_power(r) = 0;
            % Set the deficit parks to zero
            deficit_parks(region_Indices) = 0;
            
            % If this park-region has excess power, store in local storage if parks are below limit
            if any(parks_below_limit)
                % If any of the parks how low storage, drop power level to store energy
                [loc_storage_matrix,region_excess_power] = LocStorageExcessLowLim(loc_storage_matrix,region_excess_power,loc_storage_low,local_storage_efficiency,region_Indices,parks_below_limit,loc_power_capacity,r,t);
            end

        % Distribute remaining regional surplus to parks with least local storage through transmission 
        else
            % Sort parks by their current local storage (ascending order)
            [~, sortedIndices] = sort(loc_storage_matrix(region_Indices, t), 'ascend');
    
            % Allocate remaining surplus based on sorted order of local storage
            for idx = sortedIndices'
                if tot_Regional_Surplus <= 0
                    break;
                end
                % Determine the amount to allocate to this park
                allocation = min(abs(deficit_parks(region_Indices(idx))), tot_Regional_Surplus);

                % Update the affected parks
                %surplus_parks(region_Indices(idx)) = regional_Surplus(idx) - allocation; %kan vara konstig
                deficit_parks(region_Indices(idx)) = regional_Deficit(idx) + allocation;
                
                % Update the overall balance
                tot_Regional_Surplus = tot_Regional_Surplus - allocation/regional_efficiency;
                tot_Regional_Deficit = tot_Regional_Deficit - allocation/regional_efficiency; 
            end 
            % Update remainging region deficit
            region_deficit_power(r) = tot_Regional_Deficit;
        end
    end
end
