function [Power_Values] = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speeds,Sum)
% Calculate the power generation of a park. Assumes the use of the same
% turbine. Input the cut in, cut out and rated wind speed for the turbines,
% as well as the rated power of the entire park and the wind speed data of
% the site (can be calculated with the ReadWindData function). Recieve
% power generation for each section of the park (.25 degree resolution), 
% at every hour.

%pre allocate
Power_Values = zeros(size(Wind_Speeds));

%data size: MxNxK
Data_Size = size(Wind_Speeds);

%distribute power evenly on each cell of the park grid
Rated_Fraction = Rated_Power/(Data_Size(1)*Data_Size(2));

for i = 1:Data_Size(3)
    for j = 1:Data_Size(1)
        for k = 1:Data_Size(2)
            if Wind_Speeds(j,k,i) > Rated_Wind
                Power_Values(j,k,i) = Rated_Fraction;
            elseif Wind_Speeds(j,k,i) > Cut_Out
                Power_Values(j,k,i) = 0;
            elseif Wind_Speeds(j,k,i) < Cut_In
                Power_Values(j,k,i) = 0;
            else
                Power_Values(j,k,i) = Rated_Fraction*(Wind_Speeds(j,k,i)/Rated_Wind)^3;
            end
        end
    end
end

%Sums up the power for each cell of the wind park to a total power.
if Sum == true
    Power_Sum = zeros(1, Data_Size(3)); %pre-allocate
    for i = 1:Data_Size(1) % M
        for j = 1:Data_Size(2)  % N - Extract, reshape, and sum each MxN element across the third dimension
            Y = reshape(Power_Values(i,j,:), 1, Data_Size(3));
            Power_Sum = Power_Sum + Y;
        end
    end
    Power_Values = Power_Sum;
end