function [WindSpeeds, ParkArea] = ParkWindSpeeds(ParkBoundaries, WindData, GeoInfo)
% Function that gives the wind speed matrix of a park from latitude and
% longitude park boundaries input. ParkBoundaries is of the form
% [WestBound, EastBound, NorthBound, SouthBound]
% The WindData is the wind speed data of
% the entire region (Europe) which can be aquired with the ReadWindData
% function, and GeoInfo is the info file that can also be aquired
% with ReadWindData, it must be called like this: [WindData,
% GeoInfo] = ReadWindData(...)

% Error message if ParkBoundaries is wrong format
if length(ParkBoundaries)~=4
    error('ERROR: Wrong number of Park Boundaries given, must be 4')
end
if ParkBoundaries(1)>ParkBoundaries(2) || ParkBoundaries(4)>ParkBoundaries(3)
    error('ERROR: Park Boundaries are given in the wrong order (ParkBoundaries = [West, East, North, South])')
end

% First find the limits of the region from which the data is extracted
RegionWestB = GeoInfo.LongitudeLimits(1);
RegionEastB = GeoInfo.LongitudeLimits(2);
RegionNorthB = GeoInfo.LatitudeLimits(2);
RegionSouthB = GeoInfo.LatitudeLimits(1);

% Find the boundaries of the park
WestBound = ParkBoundaries(1);
EastBound = ParkBoundaries(2);
NorthBound = ParkBoundaries(3);
SouthBound = ParkBoundaries(4);

% Show an error message if the park is outside the limits of WindData
if WestBound<RegionWestB || EastBound>RegionEastB || NorthBound>RegionNorthB || SouthBound<RegionSouthB
    error('ERROR: Park is outside the wind data geographic boundaries')
end

% Find where in the WindData matrix the Park is located
LongitudeRes = 1/(GeoInfo.SampleSpacingInLongitude);
LatitudeRes = 1/(GeoInfo.SampleSpacingInLatitude);



WestIndex = ceil((WestBound-RegionWestB)*LongitudeRes + 1);
EastIndex = floor((EastBound-RegionWestB)*LongitudeRes + 1);
NorthIndex = floor((RegionNorthB-NorthBound)*LatitudeRes + 1);
SouthIndex = ceil((RegionNorthB-SouthBound)*LatitudeRes + 1);

WindSpeeds = WindData(NorthIndex:SouthIndex, WestIndex:EastIndex, :);

% Then find the area of the park, will vary depending on latitude
% Convert boundaries to radians
NorthBoundRad = deg2rad(NorthBound);
SouthBoundRad = deg2rad(SouthBound);
EastBoundRad = deg2rad(EastBound);
WestBoundRad = deg2rad(WestBound);

% Calculate average latitude in radians
avgLatitudeRad = (NorthBoundRad + SouthBoundRad) / 2;

% Earth radius in km
EarthRadius = 6371;

% Calculate area
latDiff = NorthBoundRad - SouthBoundRad;  % Latitude range in radians
longDiff = EastBoundRad - WestBoundRad;   % Longitude range in radians
ParkArea = EarthRadius^2 * abs(latDiff * longDiff * cos(avgLatitudeRad)); % Area in km^2
