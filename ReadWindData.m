function [wind_speed,R] = ReadWindData(DataFile)
% Function that reads .grib files containing wind speeds in east and north
% directions. Input the data file from local directory, recieve wind speed
% for each location and hour and information file (R)

[A,R] = readgeoraster(DataFile);

Data_Size = size(A);
wind_speed = zeros(Data_Size(1), Data_Size(2), Data_Size(3)/2);

for i = 1:length(A)/2
    east_comp = A(:,:,2*i-1);
    north_comp = A(:,:,2*i);

    Wind_speed_momentarily = real(sqrt(east_comp.^2 + north_comp.^2));
    wind_speed(:,:,i) = Wind_speed_momentarily;
end