%% animate_robot_path.m
% Run this script AFTER running your Simulink model (line_follower_robot.slx)
% to animate the robot's path.

% Load parameters if not already in workspace (important if running this script standalone)
if ~exist('P', 'var')
    line_follower_simulink_setup;
end

% --- Setup the Figure and Static Elements ---
figure('Name', 'Simulink Line Following Robot Animation', 'Position', [100, 100, 900, 800]);
h_ax = gca; % Get current axes handle
hold(h_ax, 'on'); % Hold on to add multiple elements without clearing

% Plot the simulated line once (static background)
patch([P.line_center_x - P.line_width/2, P.line_center_x + P.line_width/2, ...
       P.line_center_x + P.line_width/2, P.line_center_x - P.line_width/2], ...
      [min(sim_y)-0.1, min(sim_y)-0.1, max(sim_y)*1.1, max(sim_y)*1.1], ... % Extend line vertically
      'k', 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'DisplayName', 'Line');

% Initial plot for robot's path (will be updated iteratively)
h_path = plot(h_ax, sim_x(1), sim_y(1), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Robot Path');

% Initial drawing of the robot (circle body + direction line)
% Use patch for a properly scaled circle representing the robot's body
theta_circle = linspace(0, 2*pi, 50); % Points to draw a smooth circle
h_robot_body = patch(h_ax, sim_x(1) + P.robot_radius * cos(theta_circle), ...
                       sim_y(1) + P.robot_radius * sin(theta_circle), 'r', 'FaceAlpha', 0.8, 'EdgeColor', 'k', 'DisplayName', 'Robot Body');

% Line indicating robot's orientation (from center to front)
h_robot_direction = plot(h_ax, [sim_x(1), sim_x(1) + P.robot_radius * cos(sim_theta(1))], ...
                               [sim_y(1), sim_y(1) + P.robot_radius * sin(sim_theta(1))], 'g-', 'LineWidth', 3, 'DisplayName', 'Direction');

% Set axes limits, labels, and title
axis(h_ax, 'equal'); % Maintain aspect ratio
grid(h_ax, 'on');
xlabel(h_ax, 'X (m)');
ylabel(h_ax, 'Y (m)');
title_handle = title(h_ax, 'Simulink Line Following Robot Animation'); % Get handle to update title
legend(h_ax, 'Location', 'best');
xlim(h_ax, [0 1]); % Standard X limits for the environment
ylim(h_ax, [min(sim_y)-0.1 max(sim_y)*1.1]); % Dynamically adjust Y limits based on simulation

% --- Animation Loop ---
% Control animation speed (factor > 1 for slower, < 1 for faster than real-time)
% E.g., 0.5 means animation plays 2x real-time simulation speed
animation_speed_factor = 0.5;
delay_time = P.dt * animation_speed_factor; % Pause duration between frames

for k = 1:length(sim_time) % Loop through each recorded time step
    % Get current robot pose
    current_x = sim_x(k);
    current_y = sim_y(k);
    current_theta = sim_theta(k);

    % 1. Update robot path: Extend the blue line up to the current position
    set(h_path, 'XData', sim_x(1:k), 'YData', sim_y(1:k));

    % 2. Update robot body position (circle): Redraw the circle at the current x,y
    set(h_robot_body, 'XData', current_x + P.robot_radius * cos(theta_circle), ...
                      'YData', current_y + P.robot_radius * sin(theta_circle));

    % 3. Update robot direction line: Redraw the line indicating orientation
    set(h_robot_direction, 'XData', [current_x, current_x + P.robot_radius * cos(current_theta)], ...
                             'YData', [current_y, current_y + P.robot_radius * sin(current_theta)]);

    % 4. Update title with current simulation time
    set(title_handle, 'String', sprintf('Simulink Line Following Robot Animation\nTime: %.2f s', sim_time(k)));

    % 5. Refresh the figure window
    drawnow limitrate; % Updates the figure as fast as possible, without queuing up too many events

    % 6. Optional: Pause for controlled animation speed
    if delay_time > 0
        pause(delay_time); % Pauses execution for 'delay_time' seconds
    end
end

hold(h_ax, 'off');