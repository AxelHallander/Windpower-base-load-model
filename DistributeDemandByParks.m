function adjusted_output = DistributeDemandByParks(min_power_out,mean_powers, region)
 
    % Number of parks and time steps
    [n, T] = size(min_power_out);
    
    % Initialize the adjusted output matrix
    adjusted_output = zeros(n, T);
    
    % Find unique regions and their counts
    unique_regions = unique(region);
    
    for i = 1:numel(unique_regions)
        % Get the current region
        current_region = unique_regions(i);
        
        % Find indices of parks in this region
        region_indices = find(region == current_region);
        
        % % Number of parks in this region
        % num_parks_in_region = numel(region_indices);
        % 
        % % Adjust the power for each park in this region
        % adjusted_output(region_indices, :) = min_power_out(region_indices, :) / num_parks_in_region;
        
        % Distribute demand by mean power
        regional_power_supply = sum(mean_powers(region_indices));

        for j = region_indices
            adjusted_output(j) = min_power_out(j)*mean_powers(j)/regional_power_supply;
        end

    end
end
