%paths
path_axel = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\c76a760b03314b5fce3c90e342a95e93.grib";
path_vilgot = "C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\Windpower-base-load-model\c76a760b03314b5fce3c90e342a95e93.grib";

%Park and turbine characteristics
Rated_Power = 2*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;

%Read data and windspeeds
Wind_Speed = ReadWindData(path_axel);

%Calculate power
Power_Values = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed);

%plot
Y = Power_Values(1,1,:);
Y = reshape(Y,1,length(Y));
X = 1:length(Y);

plot(X,Y)