function [surplus_parks,deficit_parks,region_excess_power,region_deficit_power,loc_storage_matrix] = prioritized_loc_transmission(surplus_parks,deficit_parks,region,regions,regional_efficiency,local_storage_efficiency,loc_storage_low,loc_storage_matrix,t)
    
    % Step 1: Distribute local exess to parks in the same regions with
    % deficit, prioritzes parks with least storage. Loops for each region.

    region_excess_power = zeros(1,length(regions));
    region_deficit_power = zeros(1,length(regions));
    
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

        % Attempt to cover the regional deficit using regional surplus
        if tot_Regional_Surplus >= tot_Regional_Deficit
            
            % Cover the entire regional deficit with regional surplus
            region_excess_power(r) = (tot_Regional_Surplus - tot_Regional_Deficit)*regional_efficiency;
            
            % set the deficit parks to zero
            deficit_parks(region_Indices) = 0;


            % step: if this park-region has excess power, store in local storage if they are below limit
            [loc_storage_matrix,region_excess_power] = local_storage_excess_low_lim(loc_storage_matrix,region_excess_power,loc_storage_low,local_storage_efficiency,region_Indices,r,t);

            % % Check if any parks in this region have local storage below the limit (logical array)
            % parks_below_limit = loc_storage_matrix(region_Indices, t) < loc_storage_low;
            % 
            % % If there are parks below this limit:
            % if any(parks_below_limit)
            % 
            %     % Get the indices of parks below the limit within the region
            %     indices_below_limit = region_Indices(parks_below_limit);
            % 
            %     %Loop over the parks below the limit
            %     for p = indices_below_limit
            %         if region_excess_power(r) > 0
            %             %get the amount of storage in this park
            %             current_storage = loc_storage_matrix(p, t);
            % 
            %             %decide how much energy to store:
            %             stored_energy = min(region_excess_power(r), loc_storage_low-current_storage);
            % 
            %             %Update storage
            %             loc_storage_matrix(p, t) = loc_storage_matrix(p, t) + local_storage_efficiency*stored_energy;
            % 
            %             %update the excess power
            %             region_excess_power(r) = region_excess_power(r) - stored_energy;
            % 
            %         end
            %     end     
            % end
            
        % Distribute remaining regional surplus to parks with least local storage
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
                tot_Regional_Deficit = tot_Regional_Deficit - allocation/regional_efficiency; % kan tas bort
            end 
        end
        region_deficit_power(r) = tot_Regional_Deficit;
    end
end