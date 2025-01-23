function [loc_storage_matrix,region_excess_power] = LocStorageExcessLowLim(loc_storage_matrix,region_excess_power,loc_storage_low,local_storage_efficiency,region_Indices,parks_below_limit,loc_cap_power,r,t)
% Function that stores energy in local storage if there is excess power
% within the region and if the local storages are below the limit
% "loc_storage_low". 
 
    % Get the indices of parks below the limit within the region
    indices_below_limit = region_Indices(parks_below_limit);
    
    % Loop over the parks below the limit
    for p = indices_below_limit
        if region_excess_power(r) > 0
            % Get the amount of storage in this park
            current_storage = loc_storage_matrix(p, t);

            % Decide how much energy to store:
            stored_energy = min(region_excess_power(r), min(loc_storage_low-current_storage,loc_cap_power));

            % Update storage
            loc_storage_matrix(p, t) = loc_storage_matrix(p, t) + local_storage_efficiency*stored_energy;

            % Update the excess power
            region_excess_power(r) = region_excess_power(r) - stored_energy;
        else
            break
        end   
    end
end
