%paths
path_axel = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\test_data.grib";
path_vilgot = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\Windpower-base-load-model\test_data.grib";

%Park and turbine characteristics
Rated_Power = 5*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;


%Read data and windspeeds
Wind_Speed = ReadWindData(path_vilgot);

%Calculate power
Power_Values = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed);

%plot
Y1 = Power_Values(1,1,:);
Y1 = reshape(Y1,1,length(Y1));

Y2 = Power_Values(1,2,:);
Y2 = reshape(Y2,1,length(Y2));

Y3 = Power_Values(2,1,:);
Y3 = reshape(Y3,1,length(Y3));

Y4 = Power_Values(2,2,:);
Y4 = reshape(Y4,1,length(Y4));

X = 1:length(Y1);
%%
figure(1)
hold on
plot(X,Y1)
plot(X,Y2)
plot(X,Y3)
plot(X,Y4)
hold off

figure(2)
plot(X,Y1+Y2+Y3+Y4)
%%

%tot power
power_vec = Y1 + Y2 + Y3 + Y4;

%pre-allocate arrays
loc_storage_vec = zeros(1,length(X));
big_storage_vec = zeros(1,length(X));
power_out = zeros(1,length(X));

%load max and min
cable_power_cap = 4*10^9;
min_power_out = 3*10^9;
loc_storage_cap = 10*10^9; %? It will decrease when adding more parks

%index start 2 to initiate as index value 1 is zero
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
           power_out(i) = min_power_out; %p + power_diff; %or just = min_power_out
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


figure(3)
plot(X,loc_storage_vec,'--')
figure(4)
plot(X,power_out)

