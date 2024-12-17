function adjusted_output = distribute_demand_by_parks(min_power_out, region, mean_powers)
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

        % Find the mean power output of each park
        %mean_powers = mean(power_matrix,2);

        % Find the total mean power supply of the region
        regional_power_supply = sum(mean_powers(region_indices));

        %disp(mean_powers)
        %disp(regional_power_supply)
        
        % Find the total park area for the region
        %Regional_Park_Area = sum(area_vector(region_indices));
        
        % Adjust the power for each park in this region
        for j = region_indices
            adjusted_output(j) = min_power_out(j) ...
            * mean_powers(j)/regional_power_supply;
        end
    end
end
