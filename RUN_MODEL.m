%% APPLYING MODEL

%% READ BIG WIND DATA FOR EACH REGION (Axel)

path_med_06 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Meditarian_06-11.grib";
path_atl_06 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Atlantic_06-11.grib";
path_sca_06 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Scandinavia_06-11.grib";

path_med_12 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Meditarian_12-17.grib";
path_atl_12 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Atlantic_12-17.grib";
path_sca_12 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Scandinavia_12-17.grib";

path_med_18 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Meditarian_18-23.grib";
path_atl_18 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Atlantic_18-23.grib";
path_sca_18 = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\Scandinavia_18-23.grib";


% Find where the electric load CSV is located
ElectricLoads_path = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\data\monthly_hourly_load_values_2023.csv";

%% READ BIG WIND DATA FOR EACH REGION (Vilgot)

path_med_18 = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\Meditarian_18-23.grib";
path_atl_18 = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\Atlantic_18-23.grib";
path_sca_18 = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\Scandinavia_18-23.grib";

% Find where the electric load CSV is located
ElectricLoads_path = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\monthly_hourly_load_values_2023.csv";



%% READ IN EACH PARK region meditarian
tic
%Park and turbine characteristics
rated_power = 5;    %*10^9; 
rated_wind = 10.5;
cut_in = 3;
cut_out = 25;

coordinates_med = [ 3.35,  3.65, 42.40, 42.24;
                   26.35, 26.65, 35.25, 35.08;
                   -2.99, -2.75, 36.60, 36.40;
                   25.50, 25.75, 39.75, 39.50;
                   24.50, 24.75, 37.80, 37.70;
                   25.50, 25.65, 40.30, 40.15];

wind_parks_power_med06 = READDATA(path_med_06,coordinates_med,rated_power,rated_wind,cut_in,cut_out);

wind_parks_power_med12 = READDATA(path_med_12,coordinates_med,rated_power,rated_wind,cut_in,cut_out);

[wind_parks_power_med18, park_areas_med] = READDATA(path_med_18,coordinates_med,rated_power,rated_wind,cut_in,cut_out);

wind_parks_power_med = [wind_parks_power_med06,wind_parks_power_med12,wind_parks_power_med18];

% atlantic
coordinates_atl = [-8.65 ,-8.27 , 43.85, 43.70;
                   -11.0 ,-10.60, 51.60, 51.40;
                   -7.35 ,-7.0  , 56.84, 56.70;
                   -3.83 ,-3.50 , 59.50, 59.30;
                   -0.80 ,-0.41 , 56.78, 56.60;
                   -11.27,-10.95, 54.30, 54.10];

wind_parks_power_atl06 = READDATA(path_atl_06,coordinates_atl,rated_power,rated_wind,cut_in,cut_out);

wind_parks_power_atl12 = READDATA(path_atl_12,coordinates_atl,rated_power,rated_wind,cut_in,cut_out);

[wind_parks_power_atl18, park_areas_atl] = READDATA(path_atl_18,coordinates_atl,rated_power,rated_wind,cut_in,cut_out);

wind_parks_power_atl = [wind_parks_power_atl06,wind_parks_power_atl12,wind_parks_power_atl18];

% Scandinavia
coordinates_sca = [5.2  , 5.6  , 58.26, 58.08;
                   4.5  , 4.8  , 62.2 , 61.90;
                   10.66, 11.1 , 65.92, 65.73;
                   20.7 , 20.96, 70.47, 70.27;
                   26.4 , 26.95, 71.35, 71.15;
                   19.0 , 19.4 , 56.9 , 56.70];

wind_parks_power_sca06 = READDATA(path_sca_06,coordinates_sca,rated_power,rated_wind,cut_in,cut_out);

wind_parks_power_sca12 = READDATA(path_sca_12,coordinates_sca,rated_power,rated_wind,cut_in,cut_out);

[wind_parks_power_sca18,park_areas_sca] = READDATA(path_sca_18,coordinates_sca,rated_power,rated_wind,cut_in,cut_out);

wind_parks_power_sca = [wind_parks_power_sca06,wind_parks_power_sca12,wind_parks_power_sca18];
toc
%%
power_matrix = [wind_parks_power_sca; wind_parks_power_atl; wind_parks_power_med];


%% DEMAND POWER CALCULATION

% Define what countries are part of each region
Regions = containers.Map();
Regions('1') = {'SE', 'FI', 'EE', 'LV', 'LT', 'DK', 'DE', 'PL'};
Regions('2') = {'NL', 'BE', 'LU', 'FR', 'IE', 'ES', 'PT'};
Regions('3') = {'AT', 'SI', 'HR', 'HU', 'RS', 'BA', 'ME', 'XK', ... 
                'AL', 'GR', 'MK', 'BG', 'MD', 'RO', 'SK', 'CZ', 'IT', 'CH'};

% Run Baseload function
amp = 2;
power_demand_matrix = Baseload([2006,2023], Regions, ElectricLoads_path, amp);
power_demand_matrix = power_demand_matrix';

%%
hold on
plot(X,power_demand_matrix)

%% DEFINED PARAMETERS

% Load max and min, all are in GIGA
cable_power_cap = 5;                           
loc_storage_capacity = 2.5;      
loc_storage_low = 0.5;

loc_power_cap_ch = 0.5;
loc_power_cap_dch = 0.5;
reg_power_cap_ch = 10;
reg_power_cap_dch = 20;
big_storage_cap = 25000;

base_load_tol_constant = 0.95;   %tolerance too store in local

% Efficiency for storage and transmission
regional_efficiency = 0.97;
across_regions_efficiency = 0.95;
local_storage_efficiency = 0.7;
big_storage_efficiency = 0.8;

% Adjust demand
baseloadsum = mean(power_demand_matrix,"all");
baseload_percentage = 0.2015; %[0.2,0.2,0.2]';
power_demand_matrix_adjusted = power_demand_matrix.*baseload_percentage;

%% RUN MODEL

region = ["1","1","1","1","1","1", ...
          "2","2","2","2","2","2", ...
          "3","3","3","3","3","3"];

 [power_out_matrix,loc_storage_matrix,big_storage_vec,curtailment,reg_power_cap_loss,loc_power_cap_loss, ...
  storage_and_tansmission_losses,tot_effiency,downtime,reg_capacity_loss_ratio,regional_transmission_surplus,regional_transmission_deficit] = MasterModel(power_matrix, ...
     region, cable_power_cap, loc_power_cap_ch, loc_power_cap_dch, reg_power_cap_ch, reg_power_cap_dch, ...
     power_demand_matrix_adjusted, loc_storage_capacity,loc_storage_low, base_load_tol_constant, ...
     regional_efficiency, across_regions_efficiency, local_storage_efficiency, big_storage_efficiency,big_storage_cap);
 
 disp('/////      System Performance      \\\\\')
 disp(['Total system efficency:               ', num2str(round(tot_effiency,2)),'%']);
 disp(['Curtailment:                          ', num2str(round(curtailment,2)),'%']);
 disp(['Large central storage power cap loss: ', num2str(round(reg_power_cap_loss,2)),'%']);
 disp(['Local Power cap loss:                 ', num2str(round(loc_power_cap_loss,2)),'%']);
 disp(['Large central storage capacity loss:  ', num2str(round(reg_capacity_loss_ratio,2)),'%']);
 disp(['Storage and transmission losses:      ', num2str(round(storage_and_tansmission_losses,2)),'%']);
 disp(['Downtime:                             ', num2str(downtime),'h']);
 disp(['Baseload/Installed Power Ratio:       ', num2str(round(sum(mean(power_out_matrix,2))*100/(rated_power*size(power_matrix,1)),2)),'%']);
 disp(['Mean Baseload Power out:              ', num2str(round((sum(mean(power_out_matrix,2))),2)),'GW']);


%% Economics 

cost_CAES_power = 1089*10^6; %GWh
cost_CAES_energy = 109*10^6; %GW
cost_PHS_power = 2202*10^6;
cost_PHS_energy = 75*10^3;    % or 5.67      %220*10^6;    40*10^6;%
cost_wind_power = 1500*10^6;      %GW
cost_cable_power = 140*1.27*10^6; %kW

wind_cost = rated_power*size(power_matrix,1)*cost_wind_power;
PHS_cost = reg_power_cap_ch*cost_PHS_power + big_storage_cap*cost_PHS_energy;
CAES_cost = size(power_matrix,1)*(cost_CAES_power*loc_power_cap_ch + cost_CAES_power*(loc_power_cap_dch-loc_power_cap_ch)/loc_power_cap_dch + cost_CAES_energy*loc_storage_capacity);
cable_cost = size(power_matrix,1)*cost_cable_power*cable_power_cap;
tot_cost = wind_cost + PHS_cost + CAES_cost + cable_cost;

% Define labels and costs
labels = {'Wind Power', 'PHS', 'CAES', 'Cables'};
costs = [wind_cost, PHS_cost, CAES_cost, cable_cost];
tbl = table(labels,costs);

% Create the pie chart
figure;
piechart(tbl,"costs", "labels");
set(gcf, 'Position', [100, 100, 800, 600])  % [x, y, width, height]
title(['Cost Distribution With Total Cost: ', num2str(round(tot_cost)/10^9,4),' Bil USD']);

disp('/////      Economic Performance      \\\\\')
disp(['Total System Cost:             ', num2str(round(tot_cost)/10^9,4),' Bil USD']);
disp(['Wind Ratio Cost:               ', num2str(round(wind_cost/tot_cost,3)*100),' %']);
disp(['CAES Ratio Cost:               ', num2str(round(CAES_cost/tot_cost,3)*100), '%']);
disp(['PHS Ratio Cost:                ', num2str(round(PHS_cost/tot_cost,3)*100), '%']);
disp(['Cable Ratio Cost:              ', num2str(round(cable_cost/tot_cost,3)*100), '%']);
disp(['Capital Cost:                  ', num2str(round((tot_cost/sum(mean(power_out_matrix,2))/10^9),2)), ' USD/W']);

%% PLOT RESULTS
X = 1:length(big_storage_vec);

% Costumize plots
years = 2006:2023;  % Example years
x_ticks = (0:length(years)-1) * 365*24 + 1; % Start of each year

figure(2)

set(gcf, 'Position', [100, 100, 1200, 600])  % [x, y, width, height]
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact')
sgtitle('Local Storage Over Time')

nexttile
plot(X,loc_storage_matrix(1,:))
title('Example Region 1')
xticks(x_ticks);
xticklabels(years);
%xlim([0, length(X)]);
ylabel('Energy (GWh)')
grid on 
grid minor

nexttile
plot(X,loc_storage_matrix(7,:))
title('Example Region 2')
xticks(x_ticks);
xticklabels(years);
%xlim([0, length(X)]);
grid on 
grid minor

nexttile
plot(X,loc_storage_matrix(13,:))
title('Example Region 3')
xticks(x_ticks);
xticklabels(years);
%xlim([0, length(X)]);
grid on 
grid minor


figure(3)
hold on
plot(X,power_out_matrix(1,:))
plot(X,power_out_matrix(7,:))
plot(X,power_out_matrix(13,:))
title('Power Supply Out Example Parks')
xticks(x_ticks);
xticklabels(years);
%xlim([0, length(X)]);
ylabel('Power (GW)')
legend('eg Park reg 1','eg Park reg 2','eg Park reg 3')
grid on 
grid minor

figure(4)
plot(X,big_storage_vec)
title('Large Central Storage Over Time')
ylabel('Energy (GWh)')
xticks(x_ticks);
xticklabels(years);
%xlim([0, length(X)]);
grid on 
grid minor

figure(5)
hold on
plot(X,sum(power_out_matrix))
plot(X,sum(power_demand_matrix))
title('Power Over Time, Supply vs Demand')
xticks(x_ticks);
xticklabels(years);
%xlim([0, length(X)]);
ylabel('Power (GW)')
legend('Supply','Demand')
grid on 
grid minor

figure(6)
plot(X,loc_storage_matrix(1,:))
title('Local Storage of an Example Park')
xticks(x_ticks);
xticklabels(years);
ylim([0, loc_storage_capacity*1.05]);
ylabel('Energy (GWh)')
grid on 
grid minor
%%
disp('/////   Large Central Storage Performance  \\\\\')
disp(['Max diff:             ', num2str(round(max(big_storage_vec)- big_storage_cap/2),6),' GWh']);
disp(['Min diff:             ', num2str(round(big_storage_cap/2 - min(big_storage_vec)),6),' GWh']);
disp(['Variance:             ', num2str((var(big_storage_vec)/10^9)),'GWh']);

%%
 %options = optimset('Display', 'off'); % Suppress output
 %fittedParams = lsqcurvefit(@(params, t) sinusoidalModel(params, t), initialParams, numericDates, loadValues, [], [], options);
 
 b = regional_transmission_surplus(1,:)-regional_transmission_deficit(1,:);
 c = regional_transmission_surplus(2,:)-regional_transmission_deficit(2,:);
 d = regional_transmission_surplus(3,:)-regional_transmission_deficit(3,:);
 y1 = smoothdata(b,'sgolay',2000);
 y2 = smoothdata(c,'sgolay',2000);
 y3 = smoothdata(d,'sgolay',2000);
 
 figure() 
 hold on
 plot(X,y1)
 plot(X,y2)
 plot(X,y3)



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