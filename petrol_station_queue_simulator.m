function petrol_station_queue_simulator()
    % Clear workspace and command window
    clear;
    clc;
    
    % Display welcome message
    disp('=== Petrol Station Queue Simulator ===');
    disp('Brand: Petron');
    disp('-------------------------------------');
    
    % Ask user for number of vehicles
    num_vehicles = input('Enter number of vehicles to simulate: ');
    
    % Ask for peak/non-peak selection
    disp('Select hour type:');
    disp('1 - Non-Peak Hours');
    disp('2 - Peak Hours');
    hour_type = input('Choose hour type (1 or 2): ');
    
    % Ask for choice of random num generator
    disp('Available random number generators:');
    disp('1 - Linear Congruential Generator');
    disp('2 - Built-in rand() function (default)');
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
    if hour_type == 1 % Non-Peak Hours
        % More spread out arrival times (longer intervals more likely)
        inter_arrival = struct();
        inter_arrival.time = [1, 2, 3, 4, 5, 6]';
        inter_arrival.prob = [0.10, 0.25, 0.30, 0.20, 0.10, 0.05]';
        inter_arrival.cdf = cumsum(inter_arrival.prob);
        inter_arrival.range = [1, 10; 10, 35; 35, 65; 65, 85; 85, 95; 95, 100];
    else % Peak Hours
        % More frequent arrivals (shorter intervals more likely)
        inter_arrival = struct();
        inter_arrival.time = [1, 2, 3, 4, 5, 6]';
        inter_arrival.prob = [0.40, 0.35, 0.10, 0.10, 0.04, 0.01]';
        inter_arrival.cdf = cumsum(inter_arrival.prob);
        inter_arrival.range = [1, 40; 40, 75; 75, 85; 85, 95; 95, 99; 99, 100];
    end
    
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
    lane_assignment = zeros(1, num_vehicles);
    
    % Calculate arrival times first using inter-arrival random numbers
    arrival_times = zeros(1, num_vehicles);
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
        % Lane assignment (50/50 chance)
        lane_assignment(i) = (rand() > 0.5) + 1;

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
    
    % Initialize pump status (4 pumps)
    pumps = struct();
    for i = 1:4
        pumps(i).busy = false;
        pumps(i).vehicle = 0;
        pumps(i).end_time = 0;
    end
    
    % Initialize statistics
    total_wait_time = 0;
    total_time_in_system = 0;
    total_vehicles_waited = 0;
    pump_usage = zeros(1,4); % Track how many vehicles used each pump
    
    % Initialize event tracking
    event_count = 0;
    max_events = num_vehicles * 2;
    event_times = zeros(1, max_events);
    event_messages = cell(1, max_events);
    
    % Initialize result tracking
    sim_data = struct();
    pump_assignment = zeros(1, num_vehicles);
    start_time = zeros(1, num_vehicles);
    end_time = zeros(1, num_vehicles);
    waiting_time = zeros(1, num_vehicles);
    
    % Main simulation loop
    for i = 1:num_vehicles
        % Determine available pumps based on lane
        if lane_assignment(i) == 1
            available_pumps = [1, 2];
        else
            available_pumps = [3, 4];
        end
        
        % Check for available pumps
        pump_assigned = 0;
        current_time = arrival_times(i);
        start_time(i) = current_time;
        
        % First check for immediately available pumps
        for p = available_pumps
            if ~pumps(p).busy || pumps(p).end_time <= current_time
                pump_assigned = p;
                break;
            end
        end
        
        % If no pumps available, find the one that will be free soonest
        if pump_assigned == 0
            min_end_time = Inf;
            for p = available_pumps
                if pumps(p).end_time < min_end_time
                    min_end_time = pumps(p).end_time;
                    pump_assigned = p;
                end
            end
            start_time(i) = min_end_time;
            total_vehicles_waited = total_vehicles_waited + 1;
        end
        
        % Calculate waiting time
        waiting_time(i) = start_time(i) - arrival_times(i);
        total_wait_time = total_wait_time + waiting_time(i);
        
        % Update pump status
        pumps(pump_assigned).busy = true;
        pumps(pump_assigned).vehicle = i;
        pumps(pump_assigned).end_time = start_time(i) + refuel_times(i);
        pump_usage(pump_assigned) = pump_usage(pump_assigned) + 1;
        
        % Calculate time spent in system
        end_time(i) = pumps(pump_assigned).end_time;
        time_in_system = end_time(i) - arrival_times(i);
        total_time_in_system = total_time_in_system + time_in_system;
        
        % Store pump assignment
        pump_assignment(i) = pump_assigned;
        
        % Store simulation data
        sim_data(i).number = i;
        sim_data(i).petrol_type = petrol_types{i};
        sim_data(i).quantity = quantities(i);
        sim_data(i).total_price = total_prices(i);
        sim_data(i).inter_arrival_time = inter_arrival_times(i);
        sim_data(i).arrival_time = arrival_times(i);
        sim_data(i).lane = lane_assignment(i);
        sim_data(i).refuel_time = refuel_times(i);
        sim_data(i).pump = pump_assigned;
        sim_data(i).start_time = start_time(i);
        sim_data(i).end_time = end_time(i);
        sim_data(i).wait_time = waiting_time(i);
        sim_data(i).time_in_system = time_in_system;
        
        % Record events
        event_count = event_count + 1;
        event_times(event_count) = start_time(i);
        event_messages{event_count} = sprintf('Vehicle %d arrived at minute %.1f and began refueling with %s at Pump %d.', ...
            i, start_time(i), petrol_types{i}, pump_assigned);
        
        event_count = event_count + 1;
        event_times(event_count) = end_time(i);
        event_messages{event_count} = sprintf('Vehicle %d finished refueling and departed at minute %.1f.', ...
            i, end_time(i));
    end

    % Display events in chronological order
    disp('=== Simulation Events ===');
    [sorted_times, sort_idx] = sort(event_times(1:event_count));
    for j = 1:event_count
        disp(event_messages{sort_idx(j)});
    end
    
    % Calculate performance metrics
    avg_wait_time = total_wait_time / num_vehicles;
    avg_time_in_system = total_time_in_system / num_vehicles;
    prob_wait = total_vehicles_waited / num_vehicles;
    pump_utilization = pump_usage / num_vehicles;
    
    % Display results
    disp('Simulation Results:');
    fprintf('| Veh | Petrol Type  | Lane | Pump | Qty (L) | Price (RM) | Arrival | Start | End | Wait | Refuel |\n');
    fprintf('|-----|--------------|------|------|---------|------------|---------|-------|-----|------|--------|\n');

    for i = 1:num_vehicles
        fprintf('| %3d | %-12s |  %1d   |  %1d   | %7.1f | %10.2f | %7.1f | %5.1f | %3.1f | %4.1f | %6.1f |\n', ...
                i, ...
                petrol_types{i}, ...
                lane_assignment(i), ...
                pump_assignment(i), ...
                quantities(i), ...
                total_prices(i), ...
                arrival_times(i), ...
                start_time(i), ...
                end_time(i), ...
                waiting_time(i), ...
                refuel_times(i));
    end
    
    % Display performance metrics
    fprintf('\n=== Performance Metrics ===\n');
    fprintf('Average waiting time: %.2f minutes\n', avg_wait_time);
    fprintf('Average time spent in system: %.2f minutes\n', avg_time_in_system);
    fprintf('Probability a customer has to wait: %.2f\n', prob_wait);
    fprintf('Pump utilization:\n');
    fprintf('  Pump 1: %.2f\n', pump_utilization(1));
    fprintf('  Pump 2: %.2f\n', pump_utilization(2));
    fprintf('  Pump 3: %.2f\n', pump_utilization(3));
    fprintf('  Pump 4: %.2f\n', pump_utilization(4));
    
    function display_tables(inter_arrival, petrol_type, refuel_time)
        % Display inter-arrival time table
        disp('Inter-arrival Time Table:');
        fprintf('------------------------------------------------------\n');
        fprintf('Time (min) | Probability | CDF   | Random Number Range|\n');
        fprintf('-----------|-------------|-------|--------------------|\n');
        for i = 1:length(inter_arrival.time)
            fprintf('%7d    | %5.2f       | %5.2f | (%6.2f, %9.2f)|\n', inter_arrival.time(i), inter_arrival.prob(i), ...
                    inter_arrival.cdf(i), inter_arrival.range(i,1), inter_arrival.range(i,2));
        end
        fprintf('\n');
        
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

