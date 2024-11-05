%Wind Power Model

wind_data

%wind turbine parameter
wind_cut_in = 3 %m/s
wind_rated = 11 %m/s
wind_cut_out = 25 %m/s

power_rated = 2*10^9 %GW



power_vec = zeros(length(wind_data))

i = 1;
for w =wind_data
    if w < wind_cut_in  % if wind is smaller than cut in, power is 0
        power_vec(i) = 0;
    elseif w < wind_rated % if wind is smaller than rated, then cubic approximation
        power_vec(i) = power_rated*(w/wind_rated)^3;
    elseif w >= wind_rated
        power_vec(i) = power_rated; %if wind is equal or greater than rated power, power is rated
    end
end


