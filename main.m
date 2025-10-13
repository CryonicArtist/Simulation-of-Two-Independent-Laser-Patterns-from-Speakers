% MATLAB Simulation of Two Independent Laser Patterns from Speakers
%
% This script simulates two separate Lissajous figures on a clean,
% full-screen "canvas" to mimic a laser projection.

% --- Simulation Setup ---
% Clear workspace, command window, and close all figures
clear;
clc;
close all;

% --- Parameters for Laser 1 ---
% To create a slowly rotating (oscillating) ellipse, set f_x1 and f_y1
% to be very close to each other.
f_x1 = 60;       % Base frequency for X-axis (Hz)
f_y1 = 60.1;     % Slightly different Y-axis frequency causes rotation
A_x1 = 1;        % Amplitude for X-axis motion (width)
A_y1 = 1;        % Amplitude for Y-axis motion (height)
delta1 = pi / 2; % Phase difference (radians) - pi/2 creates a clear ellipse
offsetX1 = -1.5; % Horizontal position offset
offsetY1 = 0;    % Vertical position offset

% --- Parameters for Laser 2 ---
% A higher base frequency will make the laser dot move faster.
f_x2 = 90;       % Base frequency for X-axis (Hz)
f_y2 = 90.2;     % Slightly different Y-axis frequency causes rotation
A_x2 = 0.8;      % Amplitude for X-axis motion
A_y2 = 0.8;      % Amplitude for Y-axis motion
delta2 = pi / 2; % Phase difference (radians)
offsetX2 = 1.5;  % Horizontal position offset
offsetY2 = 0;    % Vertical position offset

% --- Animation and Time Parameters ---
simulation_time = 15;   % Increased duration for a longer animation.
time_step = 0.001;      % Time step for the simulation (smaller is smoother).
t = 0:time_step:simulation_time; % Time vector.
tail_length = 200;      % NEW: Number of points in the laser's "tail".

% --- Generate the Laser Path Coordinates ---
% Calculate paths for both lasers, including their offsets.
x_path1 = A_x1 * sin(2 * pi * f_x1 * t) + offsetX1;
y_path1 = A_y1 * sin(2 * pi * f_y1 * t + delta1) + offsetY1;

x_path2 = A_x2 * sin(2 * pi * f_x2 * t) + offsetX2;
y_path2 = A_y2 * sin(2 * pi * f_y2 * t + delta2) + offsetY2;


% --- Animate the Simulation ---
% Create a new figure for the animation. This will be our "canvas".
% It is set to be borderless, black, and fullscreen.
figure('Name', 'Laser Projection Canvas', ...
       'NumberTitle', 'off', ...
       'MenuBar', 'none', ...
       'ToolBar', 'none', ...
       'Color', 'k', ...
       'WindowState', 'fullscreen');

% Create axes that fill the entire figure
ax = gca;
ax.Position = [0 0 1 1]; % Make axes fill the entire figure window.
ax.Color = 'k'; % Set axes background to black.

% Hide all plot decorations (axes, ticks, labels) for a clean canvas look.
ax.Visible = 'off';

% Set the plot limits and maintain the aspect ratio. This is important
% for the shapes to appear correctly, even though the axes are not visible.
axis([-3, 3, -1.5, 1.5]);
axis equal;

hold on;

% Create animated line objects for both laser trails.
laser_trail1 = animatedline('Color', '#00FF00', 'LineWidth', 2); % Bright green, slightly thicker
laser_trail2 = animatedline('Color', '#00FF00', 'LineWidth', 2); % Bright green, slightly thicker

% --- Animation Loop ---
% Loop through each point in time to draw the animation.
% This loop now clears the previous trail and draws only a short segment,
% creating a "tail" effect.
for i = 1:length(t)
    % Clear the points from the previous frame
    clearpoints(laser_trail1);
    clearpoints(laser_trail2);

    % Determine the start index for the tail segment
    start_index = max(1, i - tail_length);

    % Add only the most recent segment of points to the animated line
    addpoints(laser_trail1, x_path1(start_index:i), y_path1(start_index:i));
    addpoints(laser_trail2, x_path2(start_index:i), y_path2(start_index:i));

    % 'drawnow' updates the figure window with the latest changes.
    % Using 'limitrate' is crucial for a smooth animation.
    drawnow limitrate;
end

hold off;

