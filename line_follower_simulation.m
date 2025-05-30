%% MATLAB Line Following Robot Simulation

% Clear workspace and close figures
clear;
clc;
close all;

%% 1. Simulation Parameters

dt = 0.05;         % Time step for simulation (seconds)
T_sim = 50;        % Total simulation time (seconds)
num_steps = T_sim / dt; % Number of simulation steps

robot_radius = 0.1; % Robot radius (meters) - simplified as a circle
wheel_base = 0.2;   % Distance between wheels (meters)

% Robot initial position and orientation
robot_x = 0.5;      % Initial X position
robot_y = 0.1;      % Initial Y position (starting slightly above the line)
robot_theta = pi/2; % Initial orientation (radians, pi/2 = facing upwards)

% Sensor parameters
num_sensors = 5; % Number of simulated IR sensors
sensor_spacing = 0.03; % Spacing between sensors on the robot (meters)
sensor_offset_y = -robot_radius + 0.01; % Offset of sensors from robot center along Y-axis (front of robot)

% Motor parameters
base_speed = 0.5;   % Base speed of motors when moving straight (m/s)
max_turn_factor = 0.8; % Maximum factor to adjust speed for turning

% PID Controller Parameters (or use rule-based for simplicity first)
Kp = 1.0; % Proportional gain
Ki = 0.0; % Integral gain (often not needed for basic line following)
Kd = 0.0; % Derivative gain (can help smooth turns)

integral_error = 0;
previous_error = 0;

% Line parameters (straight line for simplicity)
line_width = 0.05; % Width of the black line (meters)
line_center_x = 0.5; % X-coordinate of the center of the vertical line

% Simulation data storage
robot_history_x = zeros(1, num_steps);
robot_history_y = zeros(1, num_steps);
robot_history_theta = zeros(1, num_steps);

%% 2. Setup Figure for Visualization

figure('Name', 'Line Following Robot Simulation', 'Position', [100, 100, 800, 700]);
ax = gca;
hold on;
axis equal; % Maintain aspect ratio
grid on;
xlim([0 1]); % X-axis limits for the environment
ylim([0 T_sim * 0.05]); % Y-axis limits (adjust as robot moves up)
xlabel('X (m)');
ylabel('Y (m)');
title('Line Following Robot Simulation');

% Plot the simulated line (a black vertical strip)
patch([line_center_x - line_width/2, line_center_x + line_width/2, ...
       line_center_x + line_width/2, line_center_x - line_width/2], ...
      [0, 0, T_sim * base_speed * 1.5, T_sim * base_speed * 1.5], ... % Extend line far enough
      'k', 'FaceAlpha', 0.5); % Black line

% Initialize robot plot
robot_plot = plot(robot_x, robot_y, 'ro', 'MarkerSize', robot_radius*100, 'LineWidth', 2); % Robot body
robot_orientation_line = plot([robot_x, robot_x + robot_radius*cos(robot_theta)], ...
                              [robot_y, robot_y + robot_radius*sin(robot_theta)], 'b-', 'LineWidth', 2); % Orientation line

% Initialize sensor plots
sensor_plots = gobjects(num_sensors, 1);
for i = 1:num_sensors
    sensor_plots(i) = plot(0, 0, 'go', 'MarkerSize', 5, 'MarkerFaceColor', 'g'); % Green for white surface
end


%% 3. Simulation Loop

fprintf('Starting simulation...\n');
for k = 1:num_steps

    % Calculate sensor positions relative to robot center
    % Sensors are arranged horizontally at the front of the robot
    sensor_angles = linspace(-wheel_base/2, wheel_base/2, num_sensors); % Relative x-positions
    
    sensor_readings = zeros(1, num_sensors);
    weighted_sum = 0;
    active_sensors = 0;
    
    for i = 1:num_sensors
        % Sensor position in robot's local frame
        local_sensor_x = sensor_angles(i);
        local_sensor_y = sensor_offset_y;

        % Convert sensor local position to global coordinates
        global_sensor_x = robot_x + local_sensor_x * cos(robot_theta) - local_sensor_y * sin(robot_theta);
        global_sensor_y = robot_y + local_sensor_x * sin(robot_theta) + local_sensor_y * cos(robot_theta);

        % Simulate sensor reading: 1 if on line, 0 if off line
        if abs(global_sensor_x - line_center_x) < line_width / 2
            sensor_readings(i) = 1; % Sensor detects the black line
        else
            sensor_readings(i) = 0; % Sensor detects white background
        end

        % Update sensor plot color based on reading
        if sensor_readings(i) == 1
            set(sensor_plots(i), 'XData', global_sensor_x, 'YData', global_sensor_y, 'MarkerFaceColor', 'r'); % Red for black line
        else
            set(sensor_plots(i), 'XData', global_sensor_x, 'YData', global_sensor_y, 'MarkerFaceColor', 'g'); % Green for white background
        end
        
        % For calculating error: A weighted sum of active sensors
        % Sensors are indexed from left (1) to right (num_sensors)
        % Weights: -2, -1, 0, 1, 2 for 5 sensors
        weight = (i - (num_sensors + 1) / 2); % e.g., -2, -1, 0, 1, 2 for 5 sensors
        if sensor_readings(i) == 1
            weighted_sum = weighted_sum + weight;
            active_sensors = active_sensors + 1;
        end
    end

    % 4. Implement Control Logic (PID-like error calculation)
    % The 'error' indicates how far off-center the robot is from the line.
    % If weighted_sum is 0, robot is centered.
    % If weighted_sum is positive, robot is too far left (needs to turn right).
    % If weighted_sum is negative, robot is too far right (needs to turn left).
    
    current_error = weighted_sum; % Directly use weighted sum as error for simplicity

    % PID controller (adjust Kp, Ki, Kd as needed)
    integral_error = integral_error + current_error * dt;
    derivative_error = (current_error - previous_error) / dt;
    
    turn_adjustment = Kp * current_error + Ki * integral_error + Kd * derivative_error;
    previous_error = current_error;

    % Limit the turn adjustment
    turn_adjustment = max(-max_turn_factor, min(max_turn_factor, turn_adjustment));

    % Calculate wheel speeds
    v_left = base_speed - turn_adjustment;
    v_right = base_speed + turn_adjustment;

    % Limit wheel speeds to avoid negative speeds or excessively high speeds
    v_left = max(-base_speed, min(base_speed * 2, v_left));
    v_right = max(-base_speed, min(base_speed * 2, v_right));
    
    % 5. Update Robot Dynamics (Differential Drive Kinematics)
    
    % Angular velocity of the robot
    omega = (v_right - v_left) / wheel_base;
    
    % Linear velocity of the robot's center
    v = (v_left + v_right) / 2;

    % Update robot pose
    robot_theta = robot_theta + omega * dt;
    robot_x = robot_x + v * cos(robot_theta) * dt;
    robot_y = robot_y + v * sin(robot_theta) * dt;

    % Store history
    robot_history_x(k) = robot_x;
    robot_history_y(k) = robot_y;
    robot_history_theta(k) = robot_theta;

    % 6. Update Visualization
    set(robot_plot, 'XData', robot_x, 'YData', robot_y);
    set(robot_orientation_line, 'XData', [robot_x, robot_x + robot_radius*cos(robot_theta)], ...
                                'YData', [robot_y, robot_y + robot_radius*sin(robot_theta)]);

    % Adjust Y-axis limit dynamically if the robot moves far
    if robot_y > current_ylim_values(2) * 0.8
        new_ylim = ylim(2) + base_speed * T_sim * 0.1; % Extend 10% of total possible travel
        ylim([ylim(1) new_ylim]);
        % Re-plot the line to extend with the new limits
        patch([line_center_x - line_width/2, line_center_x + line_width/2, ...
               line_center_x + line_width/2, line_center_x - line_width/2], ...
              [0, 0, new_ylim * 1.2, new_ylim * 1.2], ... % Extend line further
              'k', 'FaceAlpha', 0.5, 'EdgeColor', 'none'); % 'EdgeColor', 'none' to avoid overlapping lines
        uistack(robot_plot, 'top'); % Bring robot to front
        uistack(robot_orientation_line, 'top');
        for i=1:num_sensors, uistack(sensor_plots(i), 'top'); end
    end


    drawnow limitrate; % Update plot efficiently
    
    % Optional: Add a slight pause for slower visualization
    % pause(dt * 0.1);

    % Optional: Stop simulation if robot goes too far off track (implement detection)
    if abs(robot_x - line_center_x) > line_width * 2
        fprintf('Robot went too far off track! Simulation ended.\n');
        break;
    end
end

fprintf('Simulation finished.\n');

% Plot the robot's path
plot(robot_history_x(1:k), robot_history_y(1:k), 'b--', 'LineWidth', 1); % Blue dashed line for path

hold off;