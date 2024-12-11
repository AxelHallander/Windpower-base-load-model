function [capped_matrix, loss] = cap_storage(matrix, caps)
% This function caps the local storage and saves the energy cut so
% it can be combared later.     

    % Preallocate
    excess_energy = zeros(size(matrix));
    capped_matrix = zeros(size(matrix));

    % Compute excess energy
    for i = 1:length(caps)
        cap = caps(i);
        excess_energy(i,:) = max(matrix(i,:) - cap, 0);
    end

    %excess_energy = max(matrix - cap, 0);
    
    for i = 1:length(caps)
        cap = caps(i);
        capped_matrix(i,:) = min(matrix(i,:), cap);
    end

    % Apply cap
    %capped_matrix = min(matrix, cap);

    % Sum the loss over the parks
    loss = sum(excess_energy);
   
end