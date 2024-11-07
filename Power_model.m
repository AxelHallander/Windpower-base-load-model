function [power_out,loc_storage_vec] = Power_model(power_vec,power_vec2)

%X-vector
X = 1:length(power_vec);

%pre-allocate arrays
loc_storage_vec = zeros(1,length(X));
big_storage_vec = zeros(1,length(X));
power_out = zeros(1,length(X));

%load max and min
cable_power_cap = 4*10^9;
min_power_out = 3*10^9;
loc_storage_cap = 10*10^9; %? It will decrease when adding more parks

%index start 2 to initiate as loop is dependent on i-1
i = 2;
for p = power_vec
    if p >= cable_power_cap                      %if power is bigger than the cable's, store the remainder in storage
        power_diff = p - cable_power_cap;
        loc_storage_vec(i) = loc_storage_vec(i-1) + power_diff;
        power_out(i) = cable_power_cap;
    elseif p < min_power_out                    %if power is lower than min, use storage
        power_diff = min_power_out - p;
        if loc_storage_vec(i-1) > power_diff
           loc_storage_vec(i) = loc_storage_vec(i-1) - power_diff;
           power_out(i) = min_power_out; 
        elseif loc_storage_vec(i-1) < power_diff % if not enough power stored to reach min, empty the storage
            loc_storage_vec(i) = 0;
            power_out(i) = loc_storage_vec(i);
        end
    else
        loc_storage_vec(i) = loc_storage_vec(i-1);      %otherwise, storage reamains the same
        power_out(i) = p;
    end
i = i + 1;
end

%remove first zero-value index.
loc_storage_vec(1) = [];
power_out(1) = [];


end