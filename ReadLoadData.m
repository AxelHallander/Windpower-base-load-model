function [country_codes, country_matrices, min_load_by_country] = ReadLoadData(CSV_file)
% This function reades the CSV file containing the load for each country during 2023.
% It finds the minimum load for each country per day and saves it in
% "min_load_by_country".

    % Read the CSV file into a table.
    Load_data = readtable(CSV_file);
    
    % Extract the unique country codes from column 10.
    % Assuming column 10 contains country codes stored as strings or categorical.
    country_codes = unique(Load_data{:, 10}); 

    % Initialize a cell array to store the matrices for each country.
    country_matrices = cell(length(country_codes), 1);

    % Loop through each country code and extract the corresponding rows.
    for i = 1:length(country_codes)
        % Use strcmp or ismember for comparison.
        rowsForCountry = Load_data(strcmp(Load_data{:, 10}, country_codes{i}), :);
        
        % Store the rows in the cell array.
        country_matrices{i} = rowsForCountry;
    end

    % Initialize a cell array to store the minimum load per date for each country.
    min_load_by_country = cell(length(country_matrices), 1);
    
    % Loop through each timetable in countryMatrices.
    for i = 1:length(country_matrices)
        % Extract the current country's timetable.
        data = country_matrices{i}; 
        
        % Convert Var7 (date column) to datetime if it's not already.
        data.Var7 = datetime(data.Var7, 'InputFormat', 'dd-MM-yyyy'); 
        
        % Extract the relevant columns: Var7 (date) and Var12 (load).
        dates = data.Var7;         % Dates for this country.
        loads = data.Var12;        % Electricity loads for this country.
        
        % Combine dates and loads into a timetable.
        country_data = timetable(dates, loads);

        % Generate a datetime array with all dates in the year
        allDates = (datetime(2023, 1, 1):datetime(2023, 12, 31))';
        
        % Repeat each date 24 times (one for each hour)
        dates = repelem(allDates, 24);
        
        % Create a timetable with only the repeated dates
        complete_country_data = timetable(dates);
        
        % Merge the country data with the complete dates timetable.
        country_data = outerjoin(complete_country_data, country_data, ...
                            'Keys', 'dates', ...
                            'MergeKeys', true, ...
                            'Type', 'left');
        
        % Use backward filling to fill missing load values
        country_data.loads = fillmissing(country_data.loads, 'next');
        
        % Group by date and find the minimum load for each date.
        min_load_per_date = groupsummary(country_data, 'dates', 'min', 'loads');
        
        % Store the result in the cell array.
        min_load_by_country{i} = table(min_load_per_date.dates, min_load_per_date.min_loads, 'VariableNames', {'Date', 'MinLoad'});
    end 
end
