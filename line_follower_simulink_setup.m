%% line_follower_simulink_setup.m
% This script sets up parameters and helper functions for the Simulink
% line following robot simulation.

clear;
clc;
close all;

%% Simulation Parameters (accessible in Simulink)
% Using a structure for parameters is a good practice for Simulink
P.dt = 0.05;         % Time step for simulation (seconds) - also Simulink fixed-step size
P.T_sim = 50;        % Total simulation time (seconds)

P.robot_radius = 0.1; % Robot radius (meters)
P.wheel_base = 0.2;   % Distance between wheels (meters)

% Robot initial position and orientation
P.robot_x0 = 0.5;      % Initial X position
P.robot_y0 = 0.1;      % Initial Y position (starting slightly above the line)
P.robot_theta0 = pi/2; % Initial orientation (radians, pi/2 = facing upwards)

% Sensor parameters
P.num_sensors = 5; % Number of simulated IR sensors
P.sensor_spacing = 0.03; % Spacing between sensors on the robot (meters)
P.sensor_offset_y = -P.robot_radius + 0.01; % Offset of sensors from robot center along Y-axis (front of robot)

% Motor parameters
P.base_speed = 0.5;   % Base speed of motors when moving straight (m/s)
P.max_turn_factor = 0.8; % Maximum factor to adjust speed for turning

% PID Controller Parameters
P.Kp = 1.0; % Proportional gain
P.Ki = 0.0; % Integral gain
P.Kd = 0.0; % Derivative gain

% Line parameters (straight vertical line for simplicity)
P.line_width = 0.05; % Width of the black line (meters)
P.line_center_x = 0.5; % X-coordinate of the center of the vertical line

% Assign P to base workspace so Simulink can access it
assignin('base', 'P', P);

fprintf('Parameters loaded for Simulink simulation.\n');

%% Helper Function for Environment (Line Detection)
% This function is called by the Sensor Model in Simulink
% It returns 1 if the given global (x,y) point is on the line, 0 otherwise.
% Save this as a separate file named `is_on_line.m` in the same directory.

% function on_line = is_on_line(x_coord)
% % IS_ON_LINE Checks if a given x-coordinate is on the simulated line.
% %   Assumes P.line_center_x and P.line_width are defined in base workspace.
% 
%     global P; % Access the global parameter structure
%     
%     if abs(x_coord - P.line_center_x) < P.line_width / 2
%         on_line = 1; % On the line
%     else
%         on_line = 0; % Off the line
%     end
% end