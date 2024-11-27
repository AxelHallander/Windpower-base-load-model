function [surplus_parks,deficit_parks,region_excess_power,region_deficit_power] = prioritized_loc_transmission(surplus_parks,deficit_parks,region,regions,regional_efficiency,loc_storage_matrix,t)
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
        % disp(tot_Regional_Surplus)
        %disp(tot_Regional_Deficit)
        % Attempt to cover the regional deficit using regional surplus
        if tot_Regional_Surplus >= tot_Regional_Deficit
            % Cover the entire regional deficit with regional surplus
            region_excess_power(r) = (tot_Regional_Surplus - tot_Regional_Deficit)*regional_efficiency;
            deficit_parks(region_Indices) = 0;
            %disp(region_excess_power(r))
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