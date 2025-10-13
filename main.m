% MATLAB Simulation of Two Independent Laser Patterns from Speakers
%
% This script simulates two separate Lissajous figures, like those created
% by two laser beams reflected from mirrors on vibrating speaker cones.

% --- Simulation Setup ---
% Clear workspace, command window, and close all figures
clear;d
clc;
close all;

% --- Parameters for Laser 1 ---
f_x1 = 50;       % Frequency of speaker for X-axis (Hz)
f_y1 = 100.5;    % Frequency of speaker for Y-axis (Hz)hh
A_x1 = 1;        % Amplitude for X-axis motion
A_y1 = 1;        % Amplitude for Y-axis motion
delta1 = pi / 3; % Phase difference (radians)
offsetX1 = -1.5; % Horizontal position offset
offsetY1 = 0;    % Vertical position offset

% --- Parameters for Laser 2 ---
f_x2 = 60;       % Frequency of speaker for X-axis (Hz)
f_y2 = 90;       % Frequency of speaker for Y-axis (Hz)
A_x2 = 0.8;      % Amplitude for X-axis motion (make it a bit different)
A_y2 = 0.8;      % Amplitude for Y-axis motion
delta2 = pi / 2; % Phase difference (radians)
offsetX2 = 1.5;  % Horizontal position offset
offsetY2 = 0;    % Vertical position offset

% --- Animation and Time Parameters ---
simulation_time = 10;   % Total duration of the animation in seconds.
time_step = 0.001;      % Time step for the simulation (smaller is smoother).
t = 0:time_step:simulation_time; % Time vector.

% --- Generate the Laser Path Coordinates ---
% Calculate paths for both lasers, including their offsets.
x_path1 = A_x1 * sin(2 * pi * f_x1 * t) + offsetX1;
y_path1 = A_y1 * sin(2 * pi * f_y1 * t + delta1) + offsetY1;

x_path2 = A_x2 * sin(2 * pi * f_x2 * t) + offsetX2;
y_path2 = A_y2 * sin(2 * pi * f_y2 * t + delta2) + offsetY2;


% --- Animate the Simulation ---
% Create a new figure for the animation with a black background.
figure('Name', 'Dual Laser Speaker Simulation', 'Color', 'k');
ax = gca;
ax.Color = 'k'; % Set axes background to black
ax.XColor = 'w'; % Set tick and label color to white
ax.YColor = 'w';
grid on;
ax.GridColor = [0.2 0.2 0.2]; % Dark gray grid lines

% Set the plot limits to encompass both patterns.
axis([-3, 3, -1.5, 1.5]);
axis equal; % Ensure correct aspect ratio.

% Add labels and a title.
title('Simulated Dual Laser Patterns', 'Color', 'w', 'FontSize', 16);
xlabel('Horizontal Deflection (X)', 'Color', 'w');
ylabel('Vertical Deflection (Y)', 'Color', 'w');

hold on;

% Create animated line objects for both laser trails.
laser_trail1 = animatedline('Color', '#00FF00', 'LineWidth', 1.5); % Bright green
laser_trail2 = animatedline('Color', '#00FF00', 'LineWidth', 1.5); % Bright green

% Create markers for the "head" of each laser beam.
laser_dot1 = plot(x_path1(1), y_path1(1), 'o', 'MarkerFaceColor', '#90EE90', 'MarkerEdgeColor', 'w', 'MarkerSize', 8);
laser_dot2 = plot(x_path2(1), y_path2(1), 'o', 'MarkerFaceColor', '#90EE90', 'MarkerEdgeColor', 'w', 'MarkerSize', 8);

% Loop through each point in time to create the animation.
for i = 1:length(t)
    % Add the current point to the first laser trail and update its dot.
    addpoints(laser_trail1, x_path1(i), y_path1(i));
    set(laser_dot1, 'XData', x_path1(i), 'YData', y_path1(i));

    % Add the current point to the second laser trail and update its dot.
    addpoints(laser_trail2, x_path2(i), y_path2(i));
    set(laser_dot2, 'XData', x_path2(i), 'YData', y_path2(i));

    % 'drawnow' updates the figure window with the latest changes.
    drawnow limitrate;
end

hold off;

