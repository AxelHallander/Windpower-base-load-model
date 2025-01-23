function [capped_matrix, loss] = CapStorage(storage_matrix, cap)
% This function caps the energy storage and saves the energy cut so
% it can be analyzed later. The inputs are the storage matrix and the cap 
% for the energy storage.

    % Compute excess energy
    excess_energy = max(storage_matrix - cap, 0);
  
    % Apply cap
    capped_matrix = min(storage_matrix, cap);
    
    % Sum the loss over the parks
    loss = sum(excess_energy);

end
