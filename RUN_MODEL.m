%% APPLYING MODEL

%% READ WIND DATA
path_spa = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\spa_gri_18-23.grib";
path_cre = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\grece_crete_18-23.grib";
path_adr = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\spa_adr_18-23.grib";

%Read data and windspeeds
Wind_Speed_spa = ReadWindData(path_spa);
Wind_Speed_gre = ReadWindData(path_cre);
Wind_Speed_adr = ReadWindData(path_adr);



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
power_vec3 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_adr,Sum);

%% BASELOAD CALCULATION

% Define what countries are 
Regions = containers.Map();
Regions('1') = {'SE', 'FI', 'EE', 'LV', 'LT', 'DK', 'NO', 'DE', 'PL'};
Regions('2') = {'NL', 'BE', 'LU', 'FR', 'IE', 'ES', 'PT'};
Regions('3') = {'AT', 'SI', 'HR', 'HU', 'RS', 'BA', 'ME', 'XK', 'AL', 'GR', 'MK', 'BG', 'MD', 'RO', 'SK', 'CZ', 'IT', 'CH'};

% Find where the electric load CSV is located
ElectricLoads_Vilgot = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\monthly_hourly_load_values_2023.csv";

% Run Baseload function
BaseloadMatrix = Baseload(6, Regions, ElectricLoads_Vilgot);

%% DEFINED PARAMETERS

%load max and min, all are in GIGA
cable_power_cap = 4;                           
loc_storage_cap = 50;      
loc_storage_low = 10;
base_load_tol_constant = 0.9;   %tolerance too store in local

d1 = ones(1,t)*6; 
d2 = ones(1,t)*2;
d3 = ones(1,t)*2; 
base_power_demand = [d1;d2;d3];


%efficiency for storage and transmission
regional_efficiency = 0.99;
across_regions_efficiency = 0.95;
local_storage_efficiency = 0.8;
big_storage_efficiency = 0.9;

%% RUN MODEL
t = length(power_vec3);
power_matrix = [power_vec(1:t); power_vec2(1:t); power_vec3];
region = ["1","1","1"];

 [power_out_matrix,loc_storage_matrix,big_storage_vec,curtailment] = master_model(power_matrix, region, ...
    cable_power_cap, base_power_demand, loc_storage_cap, loc_storage_low, base_load_tol_constant, ...
    regional_efficiency, across_regions_efficiency, local_storage_efficiency, big_storage_efficiency);

 disp(curtailment)

%% PLOT RESULTS
X = 1:length(big_storage_vec);

figure(5)
plot(X,loc_storage_matrix(3,:))
figure(6)
plot(X,power_out_matrix(3,:))
figure(7)
plot(X,big_storage_vec)
