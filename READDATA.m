function [wind_parks_power, park_areas] = READDATA(path,coordinates,rated_power,rated_wind,cut_in,cut_out)
% Function that loads all data and stores it in sutiable matrices.     

    % Pre-setting
    Sum = true;
    
    % Load raw data
    [wind_speed_reg, geoinfo_reg] = ReadWindData(path);
    disp('Done...')

    %preallocate
    wind_parks_power = zeros(size(coordinates,1),size(wind_speed_reg,3));
    park_areas = zeros(size(coordinates,1),1);
  
    % Loop for all parks
    for n = 1:size(coordinates,1)
        % Calculate wind speed
        [wind_park,park_areas(n)] = ParkWindSpeeds(coordinates(n,:),wind_speed_reg,geoinfo_reg);
        
        % Calculate power
        wind_parks_power(n,:) = PowerCalculations(cut_in,cut_out,rated_wind,rated_power,wind_park,Sum);     
    end
end