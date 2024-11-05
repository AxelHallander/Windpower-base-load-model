function [A,R] = ReadWindData(DataFile,path)

[A,R] = readgeoraster(path);

wind_speed = zeros(size(A));

for i = 1:length(A)/2
    east_comp = A(:,:,2*i-1);
    north_comp = A(:,:,2*i);

    Wind_speed_momentarily = real(sqrt(east_comp.^2 + north_comp^2));
    wind_speed(:,:,i) = Wind_speed_momentarily;
end

