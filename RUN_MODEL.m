%% APPLYING MODEL

%% READ BIG WIND DATA

path_med = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Meditarian_18-23.grib";
[Wind_Speed_med, geoinfo] = ReadWindData(path_med);

%% READ IN EACH PARK
[wind1,area1] = ParkWindSpeeds([3.35, 3.65, 42.4, 42.24],Wind_Speed_med,geoinfo);      %spain, girone
[wind2,area2] = ParkWindSpeeds([26.35, 26.65, 35.25, 35.08],Wind_Speed_med,geoinfo);   %greece, crete
[wind3,area3] = ParkWindSpeeds([-2.99, -2.75, 36.5, 36.5],Wind_Speed_med,geoinfo);     %spain, adra (-3.05- -2.8: 36.6-36.4)
[wind4,area4] = ParkWindSpeeds([25.5, 25.75, 39.75, 39.5],Wind_Speed_med,geoinfo);     %turkey, ezine
[wind5,area5] = ParkWindSpeeds([24.50, 24.75, 37.8, 37.7],Wind_Speed_med,geoinfo);     %greece, arni
[wind6,area6] = ParkWindSpeeds([25.5, 25.65, 40.3, 40.15],Wind_Speed_med,geoinfo);     %greece, sam

%% SUPPLY POWER CALCULATIONS

%Park and turbine characteristics
Rated_Power = 5; %*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;

%power calc
Sum = true;
power_vec1 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind1,Sum);
power_vec2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind2,Sum);
power_vec3 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind3,Sum);
power_vec4 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind4,Sum);
power_vec5 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind5,Sum);
power_vec6 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind6,Sum);

%% DEMAND POWER CALCULATION

% Define what countries are 
Regions = containers.Map();
Regions('1') = {'SE', 'FI', 'EE', 'LV', 'LT', 'DK', 'DE', 'PL'};
Regions('2') = {'NL', 'BE', 'LU', 'FR', 'IE', 'ES', 'PT'};
Regions('3') = {'AT', 'SI', 'HR', 'HU', 'RS', 'BA', 'ME', 'XK', 'AL', 'GR', 'MK', 'BG', 'MD', 'RO', 'SK', 'CZ', 'IT', 'CH'};

% Find where the electric load CSV is located
ElectricLoads_Vilgot = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\monthly_hourly_load_values_2023.csv";
ElectricLoads_Axel = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\monthly_hourly_load_values_2023.csv";

% Run Baseload function
power_demand_matrix = Baseload([2018,2023], Regions, ElectricLoads_Axel);
power_demand_matrix = power_demand_matrix';

%%
hold on
plot(X,power_demand_matrix)

%% DEFINED PARAMETERS

% Load max and min, all are in GIGA
cable_power_cap = 4;                           
loc_storage_cap = 50;      
loc_storage_low = 10;
base_load_tol_constant = 0.9;   %tolerance too store in local

% Efficiency for storage and transmission
regional_efficiency = 0.99;
across_regions_efficiency = 0.95;
local_storage_efficiency = 0.8;
big_storage_efficiency = 0.9;

% Adjust demand
baseloadsum = mean(power_demand_matrix,"all");
baseload_percentage = 0.07;
power_demand_matrix_adjusted = power_demand_matrix*baseload_percentage;


%% RUN MODEL

power_matrix = [power_vec1; power_vec2; power_vec3; power_vec4; power_vec5; power_vec6];
region = ["2","2","2","3","3","3"];

 [power_out_matrix,loc_storage_matrix,big_storage_vec,curtailment] = master_model(power_matrix, region, ...
    cable_power_cap, power_demand_matrix_adjusted, loc_storage_cap, loc_storage_low, base_load_tol_constant, ...
    regional_efficiency, across_regions_efficiency, local_storage_efficiency, big_storage_efficiency);

 disp(curtailment)

%% PLOT RESULTS
X = 1:length(big_storage_vec);

figure(2)
plot(X,loc_storage_matrix(1,:))
title('Local storage over time')
xlabel('Time (h)')
ylabel('Energy (GWh)')

figure(3)
hold on
plot(X,power_out_matrix(1,:))
plot(X,power_out_matrix(4,:))
title('Power supply out')
xlabel('Time (h)')
ylabel('Power (GW)')
legend('park1','park2')

figure(4)
plot(X,big_storage_vec)
title('Big storage over time')
xlabel('Time (h)')
ylabel('Energy (GWh)')

figure(5)
hold on
plot(X,sum(power_out_matrix))
plot(X,sum(power_demand_matrix))
title('Total power supply vs demand')
xlabel('Time (h)')
ylabel('Power (GW)')
legend('Supply','Demand')

%%
correlation_matrix = corrcoef(power_vec1,power_vec3);    
correlation_coefficient = correlation_matrix(1, 2);

% Display the result
fprintf('Correlation Coefficient: %.2f\n', correlation_coefficient);

scatter(power_vec1, power_vec2);
xlabel('Wind power at Site 1');
ylabel('Wind power at Site 2');
title('Correlation Between Wind Data Sets');
grid on;
%%
%find max discharge from big storage:
T = length(power_vec3);
diff = max(big_storage_vec(1:2:T)-big_storage_vec(2:2:T))

