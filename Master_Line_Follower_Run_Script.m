%% Master_Line_Follower_Run_Script.m
% This script automates the entire process:
% 1. Clears workspace and figures.
% 2. Loads simulation parameters from line_follower_simulink_setup.m.
% 3. Runs the Simulink model programmatically.
% 4. Verifies that simulation output data is in the workspace.
% 5. Calls animate_robot_path.m to visualize the results.

clear all; % Clear workspace to start fresh
clc;       % Clear command window
close all; % Close all figure windows

disp(' '); % Add a blank line for readability
disp('--- Starting Master Line Follower Simulation & Animation Script ---');
disp(' ');

%% Step 1: Load Simulation Parameters
disp('Step 1 of 4: Loading simulation parameters...');
try
    % Ensure line_follower_simulink_setup.m is in the same directory or on MATLAB path
    line_follower_simulink_setup;
    disp('Parameters loaded successfully from line_follower_simulink_setup.m.');
catch ME
    warning('Error loading parameters: %s', ME.message);
    disp('CRITICAL: Please ensure line_follower_simulink_setup.m is in the current directory and valid.');
    disp('Aborting script.');
    return; % Stop execution if parameters cannot be loaded
end

% Verify P structure exists after setup script runs
if ~exist('P', 'var')
    error('CRITICAL: The "P" structure was not created by line_follower_simulink_setup.m. Please check that script.');
end
disp(' ');

%% Step 2: Run the Simulink Model Programmatically
disp('Step 2 of 4: Running Simulink model...');
model_name = 'line_follower_robot'; % Corrected: Removed the .slx extension

% If the model is already open, close it to ensure a clean run without unsaved changes
if bdIsLoaded(model_name)
    save_system(model_name); % Save any unsaved changes first
    close_system(model_name, 0); % Close the model window without prompting to save
end % <--- This 'end' matches the 'if' on line 44 (if you count from the top of this block)

try % <--- This 'try' block starts here
    % Capture the output of the simulation into a variable (e.g., sim_out)
    sim_out = sim(model_name, ...
        'StartTime', '0', ...
        'StopTime', num2str(P.T_sim), ...
        'FixedStep', num2str(P.dt), ...
        'Solver', 'ode45');

    disp('Simulink model simulation completed successfully.');

 
    % Now, extract the data from the sim_out object into the workspace variables
    % These variables (sim_x, sim_y, etc.) will then be accessible by animate_robot_path
    sim_x     = sim_out.sim_x;
    sim_y     = sim_out.sim_y;
    sim_theta = sim_out.sim_theta;
    sim_time  = sim_out.sim_time;

    % You might want to remove the 'ans' variable that Simulink creates if not captured.
    % This is not strictly necessary but keeps the workspace cleaner.
    if exist('ans', 'var') && isa(ans, 'Simulink.SimulationOutput')
        clear ans;
    end % <--- This 'end' matches the 'if' on line 73 (if you count from the top of this block)

catch ME % <--- This 'catch' block starts here
    disp(' '); % Blank line for readability
    warning('Error during Simulink simulation:');
    disp(['MATLAB Error Message: ' ME.message]);
    if bdIsLoaded(model_name)
        close_system(model_name, 0);
    end
    error('CRITICAL: Simulink simulation failed. Please review the error message above and check your Simulink model for issues.');
end % <--- This 'end' matches the 'try' on line 49 (if you count from the top of this block)
disp(' ');

%% Step 3: Verify Simulation Data in Workspace
disp('Step 3 of 4: Verifying simulation data in workspace...');
% These checks are crucial if you've encountered "Unrecognized function or variable" errors before.
% They confirm if the 'To Workspace' blocks actually outputted data as expected.
required_vars = {'sim_x', 'sim_y', 'sim_theta', 'sim_time'};
data_missing = false;
for i = 1:length(required_vars)
    var_name = required_vars{i};
    if ~exist(var_name, 'var')
        warning('Variable "%s" not found in workspace.', var_name);
        data_missing = true;
    elseif isempty(eval(var_name))
        warning('Variable "%s" found but is empty. Simulation might have run for 0 steps or failed silently.', var_name);
        data_missing = true;
    end
end

if data_missing
    error(['CRITICAL: One or more required simulation output variables were missing or empty. ' ...
           'Please ensure your "To Workspace" blocks in the Simulink model are named ' ...
           'EXACTLY "sim_x", "sim_y", "sim_theta", "sim_time" (case-sensitive) ' ...
           'and are all set to "Save format: Array".']);
else
    disp('Simulation data (sim_x, sim_y, sim_theta, sim_time) successfully found in workspace.');
end
disp(' ');

%% Step 4: Animate the Robot Path
disp('Step 4 of 4: Animating robot path...');
try
    % Call the animation script. Ensure animate_robot_path.m is in the same directory.
    animate_robot_path;
    disp('Animation completed.');
catch ME
    warning('Error during animation: %s', ME.message);
    disp('Please check the animate_robot_path.m script for errors or issues with the plotted data.');
end

disp(' ');
disp('--- Master Line Follower Script Finished ---');
disp(' ');