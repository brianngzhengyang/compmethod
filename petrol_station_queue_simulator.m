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

    % Generate random numbers
    if rng_choice == 1
        seed = input('Enter seed for LCG (eg. 42): ');
        rand_numbers= lcg(seed, num_vehicles);
    else
        rand_numbers = rand(1, num_vehicles);
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
    
    % Display the tables
    disp('=== Probability Tables ===');
    display_tables(inter_arrival, petrol_type, refuel_time);

    % Map random numbers to events
    inter_arrival_samples = zeros(1, num_vehicles);
    petrol_type_samples = cell(1, num_vehicles);
    refuel_time_samples = zeros(1, num_vehicles);

    for i = 1:num_vehicles
        r = rand_numbers(i) * 100;
        
        % Inter-arrival time
        idx = find(r <= inter_arrival.range(:,2), 1);
        inter_arrival_samples(i) = inter_arrival.time(idx);
        
        % Petrol type
        idx = find(r <= petrol_type.range(:,2), 1);
        petrol_type_samples{i} = petrol_type.name{idx};
        
        % Refueling time
        idx = find(r <= refuel_time.range(:,2), 1);
        refuel_time_samples(i) = refuel_time.time(idx);
    end

    % Display results
    disp('Simulation Results:');
    fprintf('Vehicle | Inter-Arrival | Petrol Type  | Refuel Time\n');
    fprintf('--------|---------------|--------------|------------\n');
    for i = 1:num_vehicles
        fprintf('%4d    | %6.1f min    | %-12s | %6.1f min\n', ...
                i, inter_arrival_samples(i), petrol_type_samples{i}, refuel_time_samples(i));
    end

    function display_tables(inter_arrival, petrol_type, refuel_time)
        % Display inter-arrival time table
        disp('Inter-arrival Time Table:');
        fprintf('Time (min) Probability   CDF     Random Number Range\n');
        fprintf('---------- -----------   ---     -------------------\n');
        for i = 1:length(inter_arrival.time)
            fprintf('%5d       %6.2f      %5.2f       (%4.2f, %4.2f)\n', inter_arrival.time(i), inter_arrival.prob(i), ...
                    inter_arrival.cdf(i), inter_arrival.range(i,1), inter_arrival.range(i,2));
        end
        fprintf('\n');
        
        % Display petrol type table
        disp('Petrol Type Table:');
        fprintf('Type               Probability    CDF   Random Number Range   Price (RM/l)\n');
        fprintf('----               -----------    ---   -------------------   ------------\n');
        for i = 1:length(petrol_type.name)
            fprintf('%-15s      %6.2f      %5.2f      (%4.2f, %4.2f)        %6.2f\n', petrol_type.name{i}, petrol_type.prob(i), ...
                    petrol_type.cdf(i), petrol_type.range(i,1), petrol_type.range(i,2), petrol_type.price(i));
        end
        fprintf('\n');
    
        % Display refueling time table
        disp('Refueling Time Table:');
        fprintf('Time (min)  Probability  CDF     Random Number Range\n');
        fprintf('----------  -----------  ---     -------------------\n');
        for i = 1:length(refuel_time.time)
            fprintf('%5d         %6.2f    %5.2f       (%4.2f, %4.2f)\n', refuel_time.time(i), refuel_time.prob(i), ...
                    refuel_time.cdf(i), refuel_time.range(i,1), refuel_time.range(i,2));
        end
        fprintf('\n');
    end
    
    
end


