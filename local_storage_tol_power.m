function [loc_storage_matrix,indices_below_limit] = local_storage_tol_power(loc_storage_matrix,local_storage_efficiency,base_load_tol_diff,region_Indices,parks_below_limit,t)
% Function that stores energy in local storage if the local storage is 
% under the "loc_storage_low" limit. Then it remembers the parks which did
% this and will remove this power from the power_out_matrix in the model
% script

    % Get the indices of parks below the limit within the region
    indices_below_limit = region_Indices(parks_below_limit);
    
    %Loop over the parks indicies below the limit
    for p = indices_below_limit

        %decide how much energy to store:
        stored_energy = base_load_tol_diff;

        %Update storage
        loc_storage_matrix(p, t) = loc_storage_matrix(p, t) + local_storage_efficiency*stored_energy;            
    end     
end