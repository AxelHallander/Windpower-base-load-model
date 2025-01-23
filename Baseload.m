function BaseLoadMatrix = Baseload(years, Regions, CSV_file, amp)
% This function calculates the minimum power for each country represented
% in the data file to assume the countries baseload demand. Then it
% fits a sinusodial function to said baseload for all countries in the same
% defined region. Also an amplifier to the sinusodial amplitude is added
% for demand flexibility which is used to match the seasonality of the
% wind.

    % Leap year adjustments
    nYears = years(2)-years(1)+1;
    LeapYear = zeros(1,nYears);
    for i = 1:nYears
        CurrentYear = years(1)+i-1;
        if mod(CurrentYear, 4) == 0
            LeapYear(i)=1;
        end
    end
    
    % Dictionaries for storing data
    Loads = containers.Map();
    HourlyLoads = containers.Map();
    FittedValues = containers.Map();
    
    % Read the data for the electric loads for all countries
    [countryCodes, countryMatrices, minLoadByCountry] = ReadLoadData(CSV_file);
    
    % Loop over each region
    for region = keys(Regions)
        
        % Initialize an array to store the summed load values for each date.
        Loads(region{1}) = timetable(minLoadByCountry{1}.Date, zeros(length(minLoadByCountry{1}.Date), 1), 'VariableNames', {'SummedMinLoad'});
        
        % Find the countries in investigated region
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
        
        % Initialize sinusoidal fit
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
        
        % Change amplitude 
        fittedParams(1) = fittedParams(1) * amp;
        
        % Apply fit with leap year
        FittedValues(region{1}) = sinusoidalModel(fittedParams, numericDates);
        HourlyLoadsCurrent = repelem(FittedValues(region{1}), 24);
        EndValue = HourlyLoadsCurrent(end);
        LeapYearLoad = [HourlyLoadsCurrent; repmat(EndValue, 24, 1)];
        HourlyLoads(region{1}) = [];
        for i = 1:nYears
            if LeapYear(i) == 1
                HourlyLoads(region{1}) = [HourlyLoads(region{1}); LeapYearLoad];
            else
                HourlyLoads(region{1}) = [HourlyLoads(region{1}); HourlyLoadsCurrent];
            end
        end
    end

    % Initialize an empty matrix to store the combined arrays
    BaseLoadMatrix = [];
    
    % Loop through each key and extract the corresponding array
    for i = keys(HourlyLoads)
        % Extract the array associated with the current key
        array = HourlyLoads(i{1}); 
        
        % Append the array as a column to the combined matrix
        BaseLoadMatrix = [BaseLoadMatrix, array];
    end

    % Convert to GIGA
    BaseLoadMatrix = BaseLoadMatrix./10^3;

