function petrol_station_queue_simulator()
    % Clear workspace and command window
    clear;
    clc;
    
    % Display welcome message
    disp('=== Petrol Station Queue Simulator ===');
    disp('Brand: Petron');
    disp('-------------------------------------');
    
    % Ask user for simulation parameters
    num_vehicles = input('Enter number of vehicles to simulate: ');
    disp('Available random number generators:');
    disp('1 - Linear Congruential Generator (default)');
    disp('2 - Built-in rand() function');
    rng_choice = input('Choose random number generator (1 or 2): ');

    % Generate random numbers for each category
    if rng_choice == 1
        seed = input('Enter seed for LCG (eg. 42): ');
        % Generate separate random numbers for each category
        rand_inter_arrival = lcg(seed, num_vehicles) * 100;
        rand_petrol_type = lcg(seed+1, num_vehicles) * 100; % Different seed offset
        rand_quantity = lcg(seed+2, num_vehicles) * 100;
        rand_refuel_time = lcg(seed+3, num_vehicles) * 100;
    else
        % Using MATLAB's built-in generator
        rand_inter_arrival = rand(1, num_vehicles) * 100;
        rand_petrol_type = rand(1, num_vehicles) * 100;
        rand_quantity = rand(1, num_vehicles) * 100;
        rand_refuel_time = rand(1, num_vehicles) * 100;
    end
    
    % Initialize probability tables
    
    % Table 1: Inter-arrival time (minutes)
    inter_arrival = struct();
    inter_arrival.time = [1, 2, 3, 4, 5, 6]';
    inter_arrival.prob = [0.10, 0.25, 0.30, 0.20, 0.10, 0.05]';
    inter_arrival.cdf = cumsum(inter_arrival.prob);
    inter_arrival.range = [1, 10; 10, 35; 35, 65; 65, 85; 85, 95; 95, 100];
    
    % Table 2: Type of petrol
    petrol_type = struct();
    petrol_type.name = {'Blaze 95', 'Blaze 97', 'Blaze 100', 'Diesel MAX'}';
    petrol_type.prob = [0.40, 0.30, 0.20, 0.10]';
    petrol_type.cdf = cumsum(petrol_type.prob);
    petrol_type.range = [1, 40; 40, 70; 70, 90; 90, 100];
    petrol_type.price = [2.05, 3.14, 5.00, 2.81]; % RM per litre
    
    % Table 3: Refueling time (minutes)
    refuel_time = struct();
    refuel_time.time = [3, 4, 5, 6, 7, 8]';
    refuel_time.prob = [0.05, 0.15, 0.25, 0.30, 0.15, 0.10]';
    refuel_time.cdf = cumsum(refuel_time.prob);
    refuel_time.range = [1, 5; 5, 20; 20, 45; 45, 75; 75, 90; 90, 100];

    % Table 4: Quantity (litres)
    quantity = struct();
    quantity.range = [10, 20; 20, 30; 30, 40; 40, 50; 50, 60]';
    quantity.value = [15, 25, 35, 45, 55]';
    
    % Display the tables
    disp('=== Probability Tables ===');
    display_tables(inter_arrival, petrol_type, refuel_time);

    % Map random numbers to events
    inter_arrival_times = zeros(1, num_vehicles);
    petrol_types = cell(1, num_vehicles);
    refuel_times = zeros(1, num_vehicles);
    quantities = zeros(1, num_vehicles);
    total_prices = zeros(1, num_vehicles);
    refuel_times = zeros(1, num_vehicles);

    % Calculate arrival times first using inter-arrival random numbers
    for i = 1:num_vehicles
        r = rand_inter_arrival(i);
        idx = find(r <= inter_arrival.range(:,2), 1);
        inter_arrival_times(i) = inter_arrival.time(idx);
        
        if i == 1
            arrival_times(i) = inter_arrival_times(i);
        else
            arrival_times(i) = arrival_times(i-1) + inter_arrival_times(i);
        end
    end

    % Map other attributes using their specific random numbers
    for i = 1:num_vehicles
        % Petrol type
        r = rand_petrol_type(i);
        idx = find(r <= petrol_type.range(:,2), 1);
        petrol_types{i} = petrol_type.name{idx};
        
        % Quantity
        r = rand_quantity(i);
        q_range = min(ceil(r/20), 5); % 5 quantity ranges
        quantities(i) = quantity.value(q_range);
        
        % Total price
        total_prices(i) = quantities(i) * petrol_type.price(idx);
        
        % Refueling time
        r = rand_refuel_time(i);
        idx = find(r <= refuel_time.range(:,2), 1);
        refuel_times(i) = refuel_time.time(idx);
    end

    % Display results
    disp('Simulation Results:');
    printf('| Veh | Petrol Type  | Qty (L) | Price (RM) | Rand IntArr | IntArr | Arrival | Rand Refuel | Refuel |\n');
    printf('|-----|--------------|---------|------------|-------------|--------|---------|-------------|--------|\n');
    
    for i = 1:num_vehicles
        printf('| %3d | %-12s | %7.1f | %10.2f | %11d | %6d | %7d | %11d | %6d |\n', ...
                i, ...
                petrol_types{i}, ...
                quantities(i), ...
                total_prices(i), ...
                rand_inter_arrival(i), ...
                inter_arrival_times(i), ...
                arrival_times(i), ...
                rand_refuel_time(i), ...
                refuel_times(i));
    end

    function display_tables(inter_arrival, petrol_type, refuel_time)
        % Display inter-arrival time table
        disp('Inter-arrival Time Table:');
        printf('------------------------------------------------------\n');
        printf('Time (min) | Probability | CDF   | Random Number Range|\n');
        printf('-----------|-------------|-------|--------------------|\n');
        for i = 1:length(inter_arrival.time)
            printf('%7d    | %5.2f       | %5.2f | (%6.2f, %9.2f)|\n', inter_arrival.time(i), inter_arrival.prob(i), ...
                    inter_arrival.cdf(i), inter_arrival.range(i,1), inter_arrival.range(i,2));
        end
        printf('\n');
        
        % Display petrol type table
        disp('Petrol Type Table:');
        disp('+---------------+-------------+-------+----------------------+-------------+');
        disp('|    Type       | Probability |  CDF  | Random Number Range  | Price (RM/l)|');
        disp('+---------------+-------------+-------+----------------------+-------------+');
        for i = 1:length(petrol_type.name)
            fprintf('| %-13s |    %5.2f    | %5.2f |   %5.2f - %-8.2f   |   %8.2f  |\n', ...
                    petrol_type.name{i}, petrol_type.prob(i), petrol_type.cdf(i), ...
                    petrol_type.range(i,1), petrol_type.range(i,2), petrol_type.price(i));
        end
        disp('+---------------+-------------+-------+----------------------+-------------+');
        disp(' ');

        % Display refueling time table  
        disp('Refueling Time Table:');  
        disp('+------------+-------------+-------+----------------------+');  
        disp('| Time (min) | Probability |  CDF  | Random Number Range  |');  
        disp('+------------+-------------+-------+----------------------+');  
        for i = 1:length(refuel_time.time)  
            fprintf('|    %-5d   |    %6.2f   | %5.2f |   %5.2f - %-8.2f   |\n', ...  
                    refuel_time.time(i), refuel_time.prob(i), refuel_time.cdf(i), ...  
                    refuel_time.range(i,1), refuel_time.range(i,2));  
        end  
        disp('+------------+-------------+-------+----------------------+');  
        disp(' ');  
    end
    
    
end


