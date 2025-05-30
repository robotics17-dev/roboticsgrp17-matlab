%% is_on_line.m
% This function checks if a given x-coordinate is on the simulated line.
%
% Note: For Simulink's 'MATLAB Function' block, it's generally best
% to copy this logic directly into the block for code generation.

function on_line = is_on_line(x_coord, line_center_x, line_width)
    % Initialize output to ensure it's always defined (crucial for code generation)
    on_line = 0; % Default: Off the line

    % Check if the x_coord is within the line's boundaries
    if abs(x_coord - line_center_x) < line_width / 2
        on_line = 1; % On the line
    end
end