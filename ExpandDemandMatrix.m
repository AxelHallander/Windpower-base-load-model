function min_power_out = expand_demand_matrix(base_power_demand,n,T,region)
% This function expands the demand matrix to make it to equal size as
% the power matrix. It checks for each park which region it belongs to and
% then copies the demandside of that region. 

    % Initialize the min_power_out matrix
    min_power_out = zeros(n, T);

    for i = 1:n
        % Use the numeric region index directly
        region_index = str2double(region(i));  % Region for the current park

        % Assign the corresponding region's power demand to the park
        min_power_out(i, :) = base_power_demand(region_index, :);
    end

end
