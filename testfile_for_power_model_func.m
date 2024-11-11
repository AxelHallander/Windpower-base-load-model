path_spa = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\spa_gri_18-23.grib";
path_cre = "C:\Users\axel_\Documents\MATLAB\windpower-baseload-project\model\data\grece_crete18-23.grib";

%Read data and windspeeds
Wind_Speed_spa = ReadWindData(path_spa);
Wind_Speed_gre = ReadWindData(path_cre);

%%

%Park and turbine characteristics
Rated_Power = 5; %*10^9; 
Rated_Wind = 11;
Cut_In = 3;
Cut_Out = 25;

%power calc
Sum = true;
power_vec = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_spa,Sum);
power_vec2 = Power_Calculations(Cut_In,Cut_Out,Rated_Wind,Rated_Power,Wind_Speed_gre,Sum);
power_matrix = [power_vec; power_vec2];

%%

%X-vector
X = 1:length(power_vec);

%pre-allocate arrays
n = 2; %number of parks
loc_storage_matrix = zeros(n,length(X));
power_out_matrix = zeros(n,length(X));
big_storage_vec = zeros(1,length(X));
power_diff_vec = zeros(1,n);

%load max and min
cable_power_cap = 4; %*10^9;
min_power_out = 3; %*10^9;
loc_storage_cap = 10; %*10^9; %? It will decrease when adding more parks

%index start 2 to initiate as loop is dependent on i-1

%% Inte klart... OCH DÅLIGT; SE NEDAN

% i - iterate over time series
% j - iterate over number of parks
for i = 2:length(power_vec)
    %iterates over one time index for all parks
    for j = 1:n
        p = power_matrix(j,i);
        if p >= cable_power_cap                      %if power is bigger than the cable's, store the remainder in storage
            loc_storage_matrix(j,i) = loc_storage_matrix(j,i-1) + p - cable_power_cap;
            power_out_matrix(j,i) = cable_power_cap;
            power_diff_vec(j) = 0;                  %store 0 in temp vector
        elseif p < min_power_out                    %if power is lower than min, use storage
            power_diff_vec(j) = min_power_out - p;  %store -diff in temp vector
        else
            power_diff_vec(j) = p - min_power_out; %store +diff in temp vector 
        end
    end

    %här här man gått igenom ett tidssteg för alla parker... skicka
    %överskotts energi till parker, om inte finns någon som vill ha till
    %storage

    balance = sum(power_diff_vec);
    if balance == 0
        %nothing happens as power_out_matrix is already calculated 
    elseif balance > 0  %if there is a surplus in total;
        %three alternatives 
        %1 - set all power_out to min min_power_out and store the rest
        %regionally -  (easy and keeps a steady load but introduces losses
        %and bigger storage)
        power_out_matrix(:,i) = min_power_out;
        big_storage_vec(i) = big_storage_vec(i-1) + balance;

        %2 - set the parks with negative power_diff to min_power_out and
        % calculate the difference between one + and one - til all are
        % good... save the rest in local or regional

        %3 - set the parks with negative power_diff to min_power_out and
        % fil the biggest +power_diff from before with the remainder(but not bigger than originally), then the second biggest... 

        %4 - introduce a distance/efficency matrix, sends to the ones that
        %have shortest distance/best efficency
    else
        %if there are +power_diffs send them to closest parks that are -.
        %When there are no +power_diffs, take from local storage,
        %if local storage empty, take from regional.

    end


    %någon if sats
        %take from local storage
        if loc_storage_matrix(j,i-1) > power_diff_vec(j)
           loc_storage_matrix(j,i) = loc_storage_matrix(j,i-1) - power_diff_vec(j);
           power_out_matrix(j,i) = min_power_out; 
        elseif loc_storage_matrix(j,i-1) < power_diff_vec(j) % if not enough power stored to reach min, empty the storage
            loc_storage_matrix(i) = 0;
            power_out_matrix(i) = loc_storage_matrix(i);
        end
    %här ska all
end


% %remove first zero-value index.
% loc_storage_matrix(1) = [];
% power_out_matrix(1) = [];



%% %Detta är en bättre approach!! Skippar en for loop, toppen!

% Initialize power and storage matrices (T x N)

%X-vector
X = 1:length(power_vec);

%pre-allocate arrays
n = 2; %number of parks
T = length(X); % number of timesteps

power_matrix = [power_vec; power_vec2];    % Power output data for each park over time
loc_storage_matrix = zeros(n,T);
power_out_matrix = zeros(n,T);
big_storage_vec = zeros(1,T);

%load max and min
cable_power_cap = 4;%*10^9;
min_power_out = 3;%*10^9;
loc_storage_cap = 20;%*10^9; %? It will decrease when adding more parks



for t = 2:T
    % Calculate power balance for each park
    power_diff_vec = power_matrix(:, t) - min_power_out; 
    
    % Calculate surplus and deficit values for each park
    surplus_parks = max(power_diff_vec, 0);     %if value>0 it gets stored, otherwise it is zero for that index
    deficit_parks = min(power_diff_vec, 0);    % If vulue<0 it gets stored, otherwise it is zero for that index
    diff_parks = surplus_parks + deficit_parks;
    
    %First case: handel power beyond caple_power_cap: store in local!
    if max(surplus_parks) > cable_power_cap - min_power_out
        %caculate power beyond cable_power_cap
        surplus_beyond_power_cable = max(surplus_parks - (cable_power_cap - min_power_out),0);
        
        %store the excess
        loc_storage_matrix(:,t) = loc_storage_matrix(:,t-1) + surplus_beyond_power_cable;
        
        %Remove the excess from available distrubution
        surplus_parks = surplus_parks - surplus_beyond_power_cable;
        
        %Set these parks power_out to cable_power_cap
        surplus_beyond_power_cable(surplus_beyond_power_cable ~= 0) = cable_power_cap; %replace the non zero indicies to max cable out
        power_out_matrix(:,t) = surplus_beyond_power_cable;
    
    else
        loc_storage_matrix(:,t) = loc_storage_matrix(:,t-1);      %otherwise, storage reamains the same, is not need here when implemented below
        big_storage_vec(t) = big_storage_vec(t-1);
    end

    % Remaining surplus and total deficit
    tot_Surplus = sum(surplus_parks);
    tot_Deficit = sum(deficit_parks);
    balance = tot_Surplus + tot_Deficit;
    
    % if balance is exacly zero, all has min_power.
    if balance == 0
        power_out_matrix(:,t) = min_power_out;
        big_storage_vec(t) = big_storage_vec(t-1);
        
    % if balance > 0, all surplus can be distributed evenly for all parks (easy scenario)
    elseif balance > 0 
        power_out_matrix(:,t) = balance/n + min_power_out;
        big_storage_vec(t) = big_storage_vec(t-1);
       
    % if balance < 0, 
    elseif balance < 0
        
        %This should handle a re-distrubution of power


        %This section takes from local storage, otherwise from big.

        %Remove deficit energy from storage
        currentStorage = loc_storage_matrix(:,t-1) + deficit_parks;
      
        %store the negative values, the ones that has not enough energy
        energy_left = currentStorage(currentStorage < 0);
        if isempty(energy_left)
            energy_left = 0;
        end
        energy_left = sum(energy_left);

        %then replace all negative values with zeros, as big storage takes
        %takes the capacity the local cannot
        currentStorage(currentStorage < 0) = 0;
     
        %update local storage
        loc_storage_matrix(:,t) = currentStorage;
        
        %update big storage for the amount the locals cannot handle
        big_storage_vec(t) = big_storage_vec(t-1) + energy_left;

        %set power to min as the storages handels the power.
        power_out_matrix(:,t) = min_power_out;

    end
end


%%
%loc_storage_matrix(:,1) = [];
%power_out_matrix(:,1) = [];

figure(5)
plot(X,loc_storage_matrix(1,:))
figure(6)
plot(X,power_out_matrix(1,:))
figure(7)
plot(X,big_storage_vec)
