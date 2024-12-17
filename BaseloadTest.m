%% Define The regions and timeframe

years = input('How many years are you simulating? ');

% This Regions dictionary contains the different regions, add and remove
% regions as needed
Regions = containers.Map();
Regions('1') = {'SE', 'FI', 'EE', 'LV', 'LT', 'DK', 'NO', 'DE', 'PL'};
Regions('2') = {'NL', 'BE', 'LU', 'FR', 'IE', 'ES', 'PT'};
Regions('3') = {'AT', 'SI', 'HR', 'HU', 'RS', 'BA', 'ME', 'XK', 'AL', 'GR', 'MK', 'BG', 'MD', 'RO', 'SK', 'CZ', 'IT', 'CH'};

% Dictionaries for storing data
Loads = containers.Map();
HourlyLoads = containers.Map();
FittedValues = containers.Map();

% Read the data for the electric loads for all countries
[countryCodes, countryMatrices, minLoadByCountry] = ReadLoadData("C:\Users\vilgo\OneDrive\Desktop\Projekt WindBaseload\BIG data\monthly_hourly_load_values_2023.csv");

%% loop through all regions

for region = keys(Regions)
    % Initialize an array to store the summed load values for each date.
    Loads(region{1}) = timetable(minLoadByCountry{1}.Date, zeros(length(minLoadByCountry{1}.Date), 1), 'VariableNames', {'SummedMinLoad'});
    
    countries = Regions(region{1});

    % Loop over each country code in NorthRegion.
    for i = 1:length(Regions(region{1}))
        % Find the index of the current country code in the countryCodes array
        countryIndex = find(strcmp(countryCodes, countries(i)));
        
        % Check if the country exists in countryCodes.
        if ~isempty(countryIndex)
            % Extract the country's data (timing and minimum load)
            countryData = minLoadByCountry{countryIndex};
            
            % Add the country's minimum load values to the summed load values.
            Loads(region{1}) = Loads(region{1}) + countryData.MinLoad;
        else
            % If a country code doesn't exist, just skip it (or handle the case differently)
            warning(['Country code ' countries(i) ' not found in data.']);
        end
    end
    
    sinusoidalModel = @(params, t) params(1) .* sin(2 .* pi .* t/365 + params(2)) + params(3);
    
    % Convert dates to numeric values (days since January 1st)
    numericDates = days(Loads(region{1}).Time - datetime(year(Loads(region{1}).Time(1)), 1, 1));
    
    % Extract the load values
    loadValues = Loads(region{1}).SummedMinLoad;
    
    % Initial guesses for [A, phi, C]
    A_guess = (max(loadValues) - min(loadValues)) / 2;
    phi_guess = 0;
    C_guess = mean(loadValues);
    
    initialParams = [A_guess, phi_guess, C_guess];
    
    % Fit the sinusoidal model
    options = optimset('Display', 'off'); % Suppress output
    fittedParams = lsqcurvefit(@(params, t) sinusoidalModel(params, t), initialParams, numericDates, loadValues, [], [], options);
    
    FittedValues(region{1}) = sinusoidalModel(fittedParams, numericDates);
    HourlyLoads(region{1}) = repelem(FittedValues(region{1}), 24);
    HourlyLoads(region{1}) = repmat(HourlyLoads(region{1}), years, 1);
end

clear A_guess C_guess countries countryData countryIndex fittedParams i initialParams phi_guess

%% Plot the Loads

figure;  % Create a new figure

hold on;  % Hold on to overlay all plots

% Plot each timetable
for i = keys(Loads)
    plot(Loads(i{1}).Time, Loads(i{1}).SummedMinLoad,'LineWidth', 2, 'DisplayName', i{1});
end
for i = keys(Loads)
    plot(Loads(i{1}).Time, FittedValues(i{1}),'LineWidth', 2, 'DisplayName', i{1});
end


% Formatting the plot
xlabel('Date');  % Label for the x-axis
ylabel('Summed Min Load');  % Label for the y-axis
title('Electricity Load by Region Over Time');  % Title of the plot
legend show;  % Show the legend

datetick('x', 'mmm yyyy', 'keepticks');  % Format x-axis to show month and year

grid on;  % Show grid
hold off;  % Release the hold

% Get the keys of the map
regions = keys(Regions);

% Initialize an empty matrix to store the combined arrays
BaseLoadMatrix = [];

% Loop through each key and extract the corresponding array
for i = keys(HourlyLoads)
    array = HourlyLoads(i{1}); % Extract the array associated with the current key
    
    % Append the array as a column to the combined matrix
    BaseLoadMatrix = [BaseLoadMatrix, array];
end