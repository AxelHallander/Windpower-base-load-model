function [capped_matrix, loss] = CapStorage(matrix, cap)
% This function caps the local storage and saves the energy cut so
% it can be combared later.   

    % Compute excess energy
    excess_energy = max(matrix - cap, 0);
  
    % Apply cap
    capped_matrix = min(matrix, cap);
    
    % Sum the loss over the parks
    loss = sum(excess_energy);

end
