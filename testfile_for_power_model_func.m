path_spa = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\spa_gri_18-23.grib";
path_cre = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\grece_crete18-23.grib";

%Read data and windspeeds
Wind_Speed_spa = ReadWindData(path_spa);
Wind_Speed_gre = ReadWindData(path_cre);

%%

%Park and turbine characteristics
Rated_Power = 5*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;

%power calc
Sum = true;
power_vec = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_spa,Sum);
power_vec2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_gre,Sum);
power_matrix = [power_vec; power_vec2];

%%

%X-vector
X = 1:length(power_vec);

%pre-allocate arrays
loc_storage_matrix = zeros(2,length(X));
big_storage_vec = zeros(1,length(X));
power_out_matrix = zeros(2,length(X));

%load max and min
cable_power_cap = 4*10^9;
min_power_out = 3*10^9;
loc_storage_cap = 10*10^9; %? It will decrease when adding more parks

%index start 2 to initiate as loop is dependent on i-1

%% inte börjat här...
i = 2;
for p = power_vec
    if p >= cable_power_cap                      %if power is bigger than the cable's, store the remainder in storage
        power_diff = p - cable_power_cap;
        loc_storage_matrix(i) = loc_storage_matrix(i-1) + power_diff;
        power_out_matrix(i) = cable_power_cap;
    elseif p < min_power_out                    %if power is lower than min, use storage
        power_diff = min_power_out - p;
        if loc_storage_matrix(i-1) > power_diff
           loc_storage_matrix(i) = loc_storage_matrix(i-1) - power_diff;
           power_out_matrix(i) = min_power_out; 
        elseif loc_storage_matrix(i-1) < power_diff % if not enough power stored to reach min, empty the storage
            loc_storage_matrix(i) = 0;
            power_out_matrix(i) = loc_storage_matrix(i);
        end
    else
        loc_storage_matrix(i) = loc_storage_matrix(i-1);      %otherwise, storage reamains the same
        power_out_matrix(i) = p;
    end
i = i + 1;
end

%remove first zero-value index.
loc_storage_matrix(1) = [];
power_out_matrix(1) = [];


figure(3)
plot(X,loc_storage_matrix)

figure(4)
plot(X,power_out_matrix)


