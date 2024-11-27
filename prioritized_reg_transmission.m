function [surplus_parks,deficit_parks] = prioritized_reg_transmission(surplus_parks,deficit_parks,region,regions,regional_efficiency,loc_storage_matrix,t,available_power)
    % Step 2: Distribute power over different regions

    % loop over regions
    for r = 1:length(regions)
        % Get indices of parks in the current region
        region_Indices = find(region == regions(r));
      
        % Extract regional surplus and deficit
        regionalSurplus = surplus_parks(region_Indices);
        regionalDeficit = deficit_parks(region_Indices);
    
        % Total regional surplus and deficit
        tot_Regional_Surplus = sum(regionalSurplus);
        tot_Regional_Deficit = -sum(regionalDeficit);
     
        % Just add excess available power the first runtrough
        if r == 1
            tot_Regional_Surplus = tot_Regional_Surplus + available_power;
        end

        % Attempt to cover the regional deficit using added regional surplus
        if tot_Regional_Surplus >= tot_Regional_Deficit
            % Cover the entire regional deficit with regional surplus
            tot_Regional_Surplus = (tot_Regional_Surplus - tot_Regional_Deficit)*regional_efficiency;
            
            % Set the parks in questions to have no more deficit
            deficit_parks(region_Indices) = 0;
            
        else
            % Distribute remaining regional surplus to parks with least local storage
          
            % Sort parks by their current local storage (ascending order)
            [~, sortedIndices] = sort(loc_storage_matrix(region_Indices, t-1), 'ascend');
    
            % Allocate remaining surplus based on sorted order of local storage
            for idx = sortedIndices'
                if tot_Regional_Surplus <= 0
                    break;
                end
                
                % Determine the amount to allocate to this park
                allocation = abs(deficit_parks(region_Indices(idx)));

                if tot_Regional_Surplus > allocation
                    tot_Regional_Surplus = tot_Regional_Surplus - allocation/regional_efficiency; %remove allocation and the efficiency loss
                else
                    allocation = tot_Regional_Surplus*regional_efficiency; %takes the remainder of power with efficiency loss
                    tot_Regional_Surplus = 0;
                end

                deficit_parks(region_Indices(idx)) = regionalDeficit(idx) + allocation; %

            end 
        end
    end