%% APPLYING MODEL

%% READ WIND DATA
path_spa = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\spa_gri_18-23.grib";
path_cre = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\grece_crete18-23.grib";

%Read data and windspeeds
Wind_Speed_spa = ReadWindData(path_spa);
Wind_Speed_gre = ReadWindData(path_cre);

%% SUPPLY POWER CALCULATIONS

%Park and turbine characteristics
Rated_Power = 5; %*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;

%power calc
Sum = true;
power_vec = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_spa,Sum);
power_vec2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_gre,Sum);

%% DEFINED PARAMETERS

%load max and min, all are in GIGA
cable_power_cap = 4;        
base_power_demand = 2;                  
loc_storage_cap = 50;      
loc_storage_low = 10;
base_power_tol = base_power_demand*0.9;  %tolerance too store in local

%efficiency for storage and transmission
regional_efficiency = 0.99;
across_regions_efficiency = 0.95;
local_storage_efficiency = 0.8;
big_storage_efficiency = 0.9;

%% RUN MODEL
power_matrix = [power_vec; power_vec2];
region = ["1","1"];

 [power_out_matrix,loc_storage_matrix,big_storage_vec,curtailment] = master_model(power_matrix, region, ...
    cable_power_cap, base_power_demand, loc_storage_cap, loc_storage_low, base_power_tol, ...
    regional_efficiency, across_regions_efficiency, local_storage_efficiency, big_storage_efficiency);

%% PLOT RESULTS
X = 1:length(big_storage_vec);

figure(5)
plot(X,loc_storage_matrix(2,:))
figure(6)
plot(X,power_out_matrix(2,:))
figure(7)
plot(X,big_storage_vec)
