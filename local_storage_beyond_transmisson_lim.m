function [surplus_parks,loc_storage_matrix] = local_storage_beyond_transmisson_lim(parks_beyond,surplus_parks,loc_storage_matrix,cable_power_cap,min_power_out,t) 
    
    % Calculate surplus beyond the cable power cap for affected parks
    surplus_beyond = zeros(size(surplus_parks)); % Initialize with zeros
    surplus_beyond(parks_beyond) = surplus_parks(parks_beyond) - (cable_power_cap - min_power_out);
    
    % Update local storage for the affected parks
    loc_storage_matrix(:, t) = loc_storage_matrix(:, t-1);
    loc_storage_matrix(parks_beyond, t) = loc_storage_matrix(parks_beyond, t) + surplus_beyond(parks_beyond);
    
    % Remove the excess from available distribution for affected parks
    surplus_parks(parks_beyond) = surplus_parks(parks_beyond) - surplus_beyond(parks_beyond);    
end