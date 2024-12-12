function [capped_matrix, loss] = cap_storage(matrix, caps)
% This function caps the local storage and saves the energy cut so
% it can be combared later.     

    excess_energy = max(matrix - caps, 0);

    % Apply cap
    capped_matrix = min(matrix, caps);

    % Sum the loss over the parks
    loss = sum(excess_energy);
   
end