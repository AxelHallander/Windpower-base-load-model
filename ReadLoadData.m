function [countryCodes, countryMatrices, minLoadByCountry] = ReadLoadData(CSV_file)
    % Read the CSV file into a table.
    LoadData = readtable(CSV_file);
    
    % Extract the unique country codes from column 10.
    % Assuming column 10 contains country codes stored as strings or categorical.
    countryCodes = unique(LoadData{:, 10}); 

    % Initialize a cell array to store the matrices for each country.
    countryMatrices = cell(length(countryCodes), 1);

    % Loop through each country code and extract the corresponding rows.
    for i = 1:length(countryCodes)
        % Use strcmp or ismember for comparison.
        rowsForCountry = LoadData(strcmp(LoadData{:, 10}, countryCodes{i}), :);
        
        % Store the rows in the cell array.
        countryMatrices{i} = rowsForCountry;
    end

    % Initialize a cell array to store the minimum load per date for each country.
    minLoadByCountry = cell(length(countryMatrices), 1);
    
    % Loop through each timetable in countryMatrices.
    for i = 1:length(countryMatrices)
        % Extract the current country's timetable.
        data = countryMatrices{i}; 
        
        % Convert Var7 (date column) to datetime if it's not already.
        data.Var7 = datetime(data.Var7, 'InputFormat', 'dd-MM-yyyy'); 
        
        % Extract the relevant columns: Var7 (date) and Var12 (load).
        dates = data.Var7;         % Dates for this country.
        loads = data.Var12;        % Electricity loads for this country.
        
        % Combine dates and loads into a timetable.
        countryData = timetable(dates, loads);

        % Generate a datetime array with all dates in the year
        allDates = (datetime(2023, 1, 1):datetime(2023, 12, 31))';
        
        % Repeat each date 24 times (one for each hour)
        dates = repelem(allDates, 24);
        
        % Create a timetable with only the repeated dates
        completeCountryData = timetable(dates);
        
        % Merge the country data with the complete dates timetable.
        countryData = outerjoin(completeCountryData, countryData, ...
                            'Keys', 'dates', ...
                            'MergeKeys', true, ...
                            'Type', 'left');
        
        % Use backward filling to fill missing load values
        countryData.loads = fillmissing(countryData.loads, 'next');
        
        % Group by date and find the minimum load for each date.
        minLoadPerDate = groupsummary(countryData, 'dates', 'min', 'loads');
        
        % Store the result in the cell array.
        minLoadByCountry{i} = table(minLoadPerDate.dates, minLoadPerDate.min_loads, 'VariableNames', {'Date', 'MinLoad'});
    end 
end
