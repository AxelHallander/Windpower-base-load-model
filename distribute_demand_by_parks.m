function adjusted_output = distribute_demand_by_parks(min_power_out, region, area_vector)
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
        
        % Find the total park area for the region
        Regional_Park_Area = sum(area_vector(region_indices));
        
        % Adjust the power for each park in this region
        for j = 1:length(region_indices)
            current_park = region_indices(j);
            adjusted_output(current_park, :) = min_power_out(current_park) ...
            * area_vector(current_park)/Regional_Park_Area;
        end
    end
end
