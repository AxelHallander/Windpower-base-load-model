%% Script for various calculations and plots for further analysis

%% Plot power demand
hold on
plot(X,power_demand_matrix)

%% Ploting the transmission between regions
 b = regional_transmission_surplus(1,:)-regional_transmission_deficit(1,:);
 c = regional_transmission_surplus(2,:)-regional_transmission_deficit(2,:);
 d = regional_transmission_surplus(3,:)-regional_transmission_deficit(3,:);
 y1 = smoothdata(b,'sgolay',100);
 y2 = smoothdata(c,'sgolay',100);
 y3 = smoothdata(d,'sgolay',100);
 
 figure() 
 hold on
 plot(X,y1)
 plot(X,y2)
 plot(X,y3)

%% Correlation matrix
correlation_matrix = corrcoef(power_vec_med1,power_vec_atl1);    
correlation_coefficient = correlation_matrix(1, 2);

% Display the result
fprintf('Correlation Coefficient: %.2f\n', correlation_coefficient);

scatter(power_vec_med1, power_vec_atl1);
xlabel('Wind power at Site 1');
ylabel('Wind power at Site 2');
title('Correlation Between Wind Data Sets');
grid on;



%%
%find max charge/discharge from big storage:
T = length(big_storage_vec);
diff = max(big_storage_vec(1:2:T)-big_storage_vec(2:2:T))

diff = max(loc_storage_matrix(1,1:2:T)-loc_storage_matrix(1,2:2:T))

%%
[winds, geoinfo] = ReadWindData(path_sca_18);
wind = ParkWindSpeeds([5.2  , 5.6  , 58.26, 58.08],winds,geoinfo);
plot(1:length(wind)/6,wind(:,1:2:2*length(wind)/6))
%%
power = PowerCalculations(cut_in,cut_out,rated_wind,rated_power,wind,true);
plot(1:length(power)/6,power(1:length(power)/6))