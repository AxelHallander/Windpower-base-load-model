function [loc_storage_matrix,indices_below_limit,loc_power_loss] = local_storage_tol_power(loc_storage_matrix,local_storage_efficiency,loc_power_cap,base_load_tol_diff,region_Indices,parks_below_limit,loc_power_loss,t,r)
% Function that stores energy in local storage if the local storage is 
% under the "loc_storage_low" limit. Then it remembers the parks which did
% this and will remove this power from the power_out_matrix in the model
% script. This means that even if a particular park has power deficit it
% will still store in local as it will get power elsewhere. 

    % Get the indices of parks below the limit within the region
    indices_below_limit = region_Indices(parks_below_limit);

    %Loop over the parks indicies below the limit
    for p = indices_below_limit

        %decide how much energy to store:
        stored_energy = base_load_tol_diff(r); 

        % Apply cap for local storage
        capped_stored_energy = min(stored_energy, loc_power_cap);
        
        if stored_energy > capped_stored_energy
            % Save loss
            loc_power_loss(t) = stored_energy-capped_stored_energy;
        end

        %Update storage
        loc_storage_matrix(p, t) = loc_storage_matrix(p, t) + local_storage_efficiency*capped_stored_energy;            
    end     
end