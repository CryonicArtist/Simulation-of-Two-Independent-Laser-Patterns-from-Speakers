clear;  % Clear workspace variables
clc;    % Clear command window
close all; % Close all figures

%% --- 1. Define System Parameters ---
f_x_nat = 10.0;  % Natural frequency in X-direction (Hz)
f_y_nat = 12.0;  % Natural frequency in Y-direction (Hz)
zeta_x = 0.1;    % Damping ratio in X-direction (dimensionless)
zeta_y = 0.1;    % Damping ratio in Y-direction (dimensionless)

F0_over_m = 1.0; % Normalized driving force amplitude (F_0 / m)

% --- Convert to angular frequencies (rad/s) ---
w_x_nat = 2 * pi * f_x_nat;
w_y_nat = 2 * pi * f_y_nat;

%% --- 2. Simulation Loop ---
while true
    %% --- 3. Get User Input ---
    prompt = '\nEnter speaker driving frequency in Hz (e.g., 8, 10, 11, 12, 15) or "q" to quit: ';
    f_drive_str = input(prompt, 's');

    if strcmpi(f_drive_str, 'q')
        break;
    end

    f_drive = str2double(f_drive_str);

    if isnan(f_drive) || f_drive <= 0
        disp('Invalid input. Please enter a positive number or "q".');
        continue;
    end

    w_drive = 2 * pi * f_drive;

    %% --- 4. Calculate Steady-State Response ---
    A_x = F0_over_m / sqrt((w_x_nat^2 - w_drive^2)^2 + (2 * zeta_x * w_x_nat * w_drive)^2);
    A_y = F0_over_m / sqrt((w_y_nat^2 - w_drive^2)^2 + (2 * zeta_y * w_y_nat * w_drive)^2);

    phi_x = atan2(2 * zeta_x * w_x_nat * w_drive, w_x_nat^2 - w_drive^2);
    phi_y = atan2(2 * zeta_y * w_y_nat * w_drive, w_y_nat^2 - w_drive^2);

    phase_diff_deg = (phi_y - phi_x) * 180/pi;

    %% --- 5. Generate Waveform for Plotting ---
    T_period = 1 / f_drive;
    t = linspace(0, 3 * T_period, 1000);

    x_t = A_x * cos(w_drive * t - phi_x);
    y_t = A_y * cos(w_drive * t - phi_y);

    %% --- 6. Plot the Result ---
    figure(1);
    clf;
    
    plot(x_t, y_t, 'r', 'LineWidth', 2);
    
    grid on;
    axis equal;

    % --- NEW / MODIFIED ZOOM LOGIC ---
    % Calculate the maximum extent needed for the current ellipse
    % This ensures the plot always fits the ellipse and "zooms in" or "out" as needed.
    current_max_extent = max(abs([A_x, A_y])) * 1.1; % Add a 10% buffer
    if current_max_extent == 0 % Avoid division by zero if both amplitudes are zero
        current_max_extent = 0.1; % A small default extent
    end
    xlim([-current_max_extent, current_max_extent]);
    ylim([-current_max_extent, current_max_extent]);
    % --- END NEW / MODIFIED ZOOM LOGIC ---

    xlabel('X Position (arbitrary units)');
    ylabel('Y Position (arbitrary units)');
    
    title_str = sprintf('Laser Projection at %.2f Hz', f_drive);
    subtitle_str = sprintf('Phase Difference: %.1f° | Amplitudes: [X=%.2f, Y=%.2f]', ...
                           phase_diff_deg, A_x, A_y);
    title({title_str, subtitle_str});

    drawnow;
end

disp('Simulation ended.');