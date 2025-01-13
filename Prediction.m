% Vehicle Parameters
car.mass = 800; % kg
car.fuel_capacity = 500; % liters
car.fuel_consumption_rate = 0.01; % liters/m
car.power = 300; % kW
car.drag_coeff = 0.3;
car.frontal_area = 1.5; % m^2
car.tire_grip = 1.2; % Initial grip
car.downforce_coeff = 2.5;
car.braking_force = 8000; % N
car.rr = 0.015;
g = 9.81; % m/s^2
air_density = 1.225; % kg/m^3

% User Input
num_laps = input('Enter the number of laps to simulate: '); % Number of laps

% Track Parameters
track_segments = [ ...
    500, 0; % Straight
    100, 50; % Corner
    300, 0; % Straight
    150, 40; % Corner
    100, 90; % Corner
];

% Functions
F_drag = @(v) 0.5 * car.drag_coeff * car.frontal_area * air_density * v.^2;
F_roll = @(v) car.rr * car.mass * g;
F_traction = @(v) car.power * 1000 ./ v; % Convert kW to W
tire_degradation = @(lap_fraction) car.tire_grip * (1 - 0.2 * lap_fraction); % 20% degradation over the race
corner_speed = @(grip, r) sqrt(grip * g * r); % Adjust corner speed based on grip

% Initial Parameters
fuel_remaining = car.fuel_capacity; % Initial fuel
lap_times = [];
fuel_left = [];
current_speed = 0.1; % Avoid division by zero

% Simulation Loop
for lap = 1:num_laps
    lap_time = 0; % Initialize lap time for this lap
    distance_covered = 0; % Reset distance covered for this lap

    for i = 1:size(track_segments, 1)
        length = track_segments(i, 1);
        radius = track_segments(i, 2);

        % Update grip for tire degradation
        lap_fraction = (lap - 1) / num_laps; % Lap fraction based on current lap
        current_grip = tire_degradation(lap_fraction);

        % Calculate speed and time for the segment
        if radius == 0 % Straight Segment
            syms v
            eq = F_traction(v) - F_drag(v) - F_roll(v) == 0;
            max_speed = double(vpasolve(eq, v, [current_speed, Inf]));
            if isempty(max_speed) % Handle solver failure
                max_speed = current_speed; % Assume no change if solver fails
            end
            avg_speed = (current_speed + max_speed) / 2;
            lap_time = lap_time + length / avg_speed;
            current_speed = max_speed;
        else % Corner Segment
            max_speed_corner = corner_speed(current_grip, radius);
            if current_speed > max_speed_corner
                braking_distance = (current_speed^2 - max_speed_corner^2) / ...
                    (2 * (car.braking_force / car.mass));
                lap_time = lap_time + braking_distance / current_speed;
                current_speed = max_speed_corner;
            end
            lap_time = lap_time + length / current_speed;
        end

        % Update distance and fuel
        distance_covered = distance_covered + length;
        fuel_used = length * car.fuel_consumption_rate;
        fuel_remaining = max(0, fuel_remaining - fuel_used);

        % Handle out-of-fuel scenario
        if fuel_remaining <= 0
            disp('Out of fuel! Simulation ending.');
            break;
        end
    end

    % Store results for this lap
    lap_times = [lap_times, lap_time];
    fuel_left = [fuel_left, fuel_remaining];
    disp(['Lap ', num2str(lap), ': ', num2str(lap_time), ' seconds']);
    disp(['Fuel Remaining: ', num2str(fuel_remaining), ' liters']);

    % End simulation if out of fuel
    if fuel_remaining <= 0
        break;
    end
end

% Plot Lap Times
figure;
plot(1:num_laps, lap_times, '-o');
title('Lap Times Over Race');
xlabel('Lap Number');
ylabel('Lap Time (s)');
grid on;

% Summary
disp('Simulation Complete!');
disp(['Total Laps Completed: ', num2str(lap_times)]);
disp(['Average Lap Time: ', num2str(mean(lap_times)), ' seconds']);
disp(['Final Fuel Remaining: ', num2str(fuel_remaining), ' liters']);
