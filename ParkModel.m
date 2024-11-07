%paths
path_axel = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\test_data.grib";
path_vilgot = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\Windpower-base-load-model\test_data.grib";

%Park and turbine characteristics
Rated_Power = 5*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;


%Read data and windspeeds
Wind_Speed = ReadWindData(path_axel);

%Calculate power
Sum = false;
Power_Values = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed,Sum);

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

figure(1)
hold on
plot(X,Y1)
plot(X,Y2)
plot(X,Y3)
plot(X,Y4)
hold off

figure(2)
plot(X,Y1+Y2+Y3+Y4)

%tot power
power_vec = Y1 + Y2 + Y3 + Y4;

%% Automized section
Sum = true;
power_vec2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed,Sum);
[p,s] = Power_model(power_vec);
plot(X,p)



