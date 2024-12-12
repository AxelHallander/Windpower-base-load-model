%% APPLYING MODEL

%% READ BIG WIND DATA FOR EACH REGION (Axel)

path_med = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Meditarian_18-23.grib";
path_atl = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Atlantic_18-23.grib";
path_sca = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Scandinavia_18-23.grib";

% Find where the electric load CSV is located
ElectricLoads_path = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\monthly_hourly_load_values_2023.csv";

%% READ BIG WIND DATA FOR EACH REGION (Vilgot)

path_med = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\Meditarian_18-23.grib";
path_atl = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\Atlantic_18-23.grib";
path_sca = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\Scandinavia_18-23.grib";

% Find where the electric load CSV is located
ElectricLoads_path = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\monthly_hourly_load_values_2023.csv";
%%
[Wind_Speed_med, geoinfo_med] = ReadWindData(path_med);
[Wind_Speed_atl, geoinfo_atl] = ReadWindData(path_atl);
[Wind_Speed_sca, geoinfo_sca] = ReadWindData(path_sca);

%% READ IN EACH PARK region meditarian
[wind_med1,area_med1] = ParkWindSpeeds([ 3.35,  3.65, 42.40, 42.24],Wind_Speed_med,geoinfo_med);     %spain, girone
[wind_med2,area_med2] = ParkWindSpeeds([26.35, 26.65, 35.25, 35.08],Wind_Speed_med,geoinfo_med);     %greece, crete
[wind_med3,area_med3] = ParkWindSpeeds([-2.99, -2.75, 36.60, 36.40],Wind_Speed_med,geoinfo_med);     %spain, adra (-3.05- -2.8: 36.6-36.4)
[wind_med4,area_med4] = ParkWindSpeeds([25.50, 25.75, 39.75, 39.50],Wind_Speed_med,geoinfo_med);     %turkey, ezine
[wind_med5,area_med5] = ParkWindSpeeds([24.50, 24.75, 37.80, 37.70],Wind_Speed_med,geoinfo_med);     %greece, arni
[wind_med6,area_med6] = ParkWindSpeeds([25.50, 25.65, 40.30, 40.15],Wind_Speed_med,geoinfo_med);     %greece, sam

%% atlantic
[wind_atl1,area_atl1] = ParkWindSpeeds([-8.65 ,-8.27 , 43.85, 43.70],Wind_Speed_atl,geoinfo_atl);            
[wind_atl2,area_atl2] = ParkWindSpeeds([-11.0 ,-10.60, 51.60, 51.40],Wind_Speed_atl,geoinfo_atl);
[wind_atl3,area_atl3] = ParkWindSpeeds([-7.35 ,-7.0  , 56.84, 56.70],Wind_Speed_atl,geoinfo_atl);
[wind_atl4,area_atl4] = ParkWindSpeeds([-3.83 ,-3.50 , 59.50, 59.30],Wind_Speed_atl,geoinfo_atl);
[wind_atl5,area_atl5] = ParkWindSpeeds([-0.80 ,-0.41 , 56.78, 56.60],Wind_Speed_atl,geoinfo_atl);
[wind_atl6,area_atl6] = ParkWindSpeeds([-11.27,-10.95, 54.30, 54.10],Wind_Speed_atl,geoinfo_atl);

%% Scandinavia
[wind_sca1,area_sca1] = ParkWindSpeeds([5.2  , 5.6  , 58.26, 58.08],Wind_Speed_sca,geoinfo_sca); 
[wind_sca2,area_sca2] = ParkWindSpeeds([4.5  , 4.8  , 62.2 , 61.90],Wind_Speed_sca,geoinfo_sca); 
[wind_sca3,area_sca3] = ParkWindSpeeds([10.66, 11.1 , 65.92, 65.73],Wind_Speed_sca,geoinfo_sca); 
[wind_sca4,area_sca4] = ParkWindSpeeds([20.7 , 20.96, 70.47, 70.27],Wind_Speed_sca,geoinfo_sca); 
[wind_sca5,area_sca5] = ParkWindSpeeds([26.4 , 26.95, 71.35, 71.15],Wind_Speed_sca,geoinfo_sca); 
[wind_sca6,area_sca6] = ParkWindSpeeds([19.0 , 19.4 , 56.9 , 56.70],Wind_Speed_sca,geoinfo_sca); 


%% SUPPLY POWER CALCULATIONS

%Park and turbine characteristics
Rated_Power = 5; %*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;

%power calc
Sum = true;
power_vec_med1 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_med1,Sum);
power_vec_med2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_med2,Sum);
power_vec_med3 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_med3,Sum);
power_vec_med4 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_med4,Sum);
power_vec_med5 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_med5,Sum);
power_vec_med6 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_med6,Sum);

power_vec_atl1 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_atl1,Sum);
power_vec_atl2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_atl2,Sum);
power_vec_atl3 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_atl3,Sum);
power_vec_atl4 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_atl4,Sum);
power_vec_atl5 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_atl5,Sum);
power_vec_atl6 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_atl6,Sum);

power_vec_sca1 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_sca1,Sum);
power_vec_sca2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_sca2,Sum);
power_vec_sca3 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_sca3,Sum);
power_vec_sca4 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_sca4,Sum);
power_vec_sca5 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_sca5,Sum);
power_vec_sca6 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,wind_sca6,Sum);

%% DEMAND POWER CALCULATION

% Define what countries are part of each region
Regions = containers.Map();
Regions('1') = {'SE', 'FI', 'EE', 'LV', 'LT', 'DK', 'DE', 'PL'};
Regions('2') = {'NL', 'BE', 'LU', 'FR', 'IE', 'ES', 'PT'};
Regions('3') = {'AT', 'SI', 'HR', 'HU', 'RS', 'BA', 'ME', 'XK', ... 
                'AL', 'GR', 'MK', 'BG', 'MD', 'RO', 'SK', 'CZ', 'IT', 'CH'};

% Run Baseload function
power_demand_matrix = Baseload([2018,2023], Regions, ElectricLoads_path);
power_demand_matrix = power_demand_matrix';

%%
hold on
plot(X,power_demand_matrix)

%% DEFINED PARAMETERS

% Load max and min, all are in GIGA
cable_power_cap = 4;                           
loc_storage_cap = 100;      
loc_storage_low = 10;

loc_power_cap = 1;
reg_power_cap = 10;
base_load_tol_constant = 0.95;   %tolerance too store in local

% Efficiency for storage and transmission
regional_efficiency = 1;
across_regions_efficiency = 1;
local_storage_efficiency = 1;
big_storage_efficiency = 1;

% Adjust demand
baseloadsum = mean(power_demand_matrix,"all");
baseload_percentage = 0.19; %[0.2,0.2,0.2]';
power_demand_matrix_adjusted = power_demand_matrix.*baseload_percentage;


%% RUN MODEL

power_matrix = [power_vec_sca1; power_vec_sca2; power_vec_sca3; power_vec_sca4; power_vec_sca5; power_vec_sca6;
                power_vec_atl1; power_vec_atl2; power_vec_atl3; power_vec_atl4; power_vec_atl5; power_vec_atl6;
                power_vec_med1; power_vec_med2; power_vec_med3; power_vec_med4; power_vec_med5; power_vec_med6];
region = ["1","1","1","1","1","1", ...
          "2","2","2","2","2","2", ...
          "3","3","3","3","3","3"];


 [power_out_matrix,loc_storage_matrix,big_storage_vec,curtailment,reg_power_cap_loss,loc_power_cap_loss,tot_effiency,storage_and_tansmission_losses,loc_power_loss] = master_model(power_matrix, region, ...
    cable_power_cap, loc_power_cap, reg_power_cap, power_demand_matrix_adjusted, loc_storage_cap, loc_storage_low, base_load_tol_constant, ...
    regional_efficiency, across_regions_efficiency, local_storage_efficiency, big_storage_efficiency);
 
 disp('/////          System characteristics          \\\\\')
 disp(['Total system efficency:             ', num2str(round(tot_effiency,2)),'%']);
 disp(['Curtailment:                        ', num2str(round(curtailment,2)),'%']);
 disp(['Regional Power cap loss:            ', num2str(round(reg_power_cap_loss,2)),'%']);
 disp(['Local Power cap loss:               ', num2str(round(loc_power_cap_loss,2)),'%']);
 disp(['Storage and transmission losses:    ', num2str(round(storage_and_tansmission_losses,2)),'%']);

%% PLOT RESULTS
X = 1:length(big_storage_vec);

figure(2)
subplot(1, 3, 1)
plot(X,loc_storage_matrix(1,:))
title('Example region 1')
xlabel('Time (h)')
ylabel('Energy (GWh)')
grid on 
grid minor

subplot(1, 3, 2)
plot(X,loc_storage_matrix(7,:))
title('Example region 2')
xlabel('Time (h)')
ylabel('Energy (GWh)')
grid on 
grid minor

subplot(1, 3, 3)
plot(X,loc_storage_matrix(13,:))
title('Example region 3')
xlabel('Time (h)')
ylabel('Energy (GWh)')
grid on 
grid minor
sgtitle('Local storage over time')

figure(3)
hold on
plot(X,power_out_matrix(1,:))
plot(X,power_out_matrix(7,:))
plot(X,power_out_matrix(13,:))
title('Power supply out')
xlabel('Time (h)')
ylabel('Power (GW)')
legend('park1','park2','park3')
grid on 
grid minor

figure(4)
plot(X,big_storage_vec)
title('Big storage over time')
xlabel('Time (h)')
ylabel('Energy (GWh)')
grid on 
grid minor

figure(5)
hold on
plot(X,sum(power_out_matrix))
plot(X,sum(power_demand_matrix))
title('Total power supply vs demand')
xlabel('Time (h)')
ylabel('Power (GW)')
legend('Supply','Demand')
grid on 
grid minor

%%
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