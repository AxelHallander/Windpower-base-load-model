function [loc_storage_matrix,over_capacity] = LocStorageCharge(loc_storage_matrix,loc_power_cap,loc_storage_capacity,over_capacity,big_storage_efficiency,local_storage_efficiency,regional_efficiency,t)
% Function that stores in local if there are any power available.
% Transmission between parks may occur in this function as it takes the
% available energy as a sum and not the parks themselves and prioritizes
% the least full storage, thus the regional transmission effiency is
% introduced. 

    % Find out how much more all parks can store in local
    loc_allocated_charge = loc_power_cap - (loc_storage_matrix(:, t) - loc_storage_matrix(:, t-1));

    % sort parks according to lowest storage
    [~, sortedIndices] = sort(loc_storage_matrix(:, t), 'ascend');
    
    % Allocate over charge based on sorted order of local storage
    for idx = sortedIndices'
        
        % break when over_capacity is below zero and local storage is full
        if over_capacity <= 0 
            break;
        elseif loc_storage_matrix(idx,t) >= loc_storage_capacity
            break;
        else
            % Decide allocation for this park (regional efficencies has already been applied, reverse this)
            allocation = min(loc_allocated_charge(idx),over_capacity)/big_storage_efficiency;

            % Update local storage for this park and update remaining over capacity
            loc_storage_matrix(idx,t) = loc_storage_matrix(idx,t) + allocation*local_storage_efficiency*regional_efficiency;
            over_capacity = over_capacity - allocation;
        end
    end