function live_laser_sim()
    % Main function to create the GUI and run the live animation
    
    clear;      % Clear workspace variables
    clc;        % Clear command window
    close all;  % Close all figures

    %% --- 1. Define System Parameters ---
    f_x_nat = 10.0;  % Natural frequency in X-direction (Hz)
    f_y_nat = 12.0;  % Natural frequency in Y-direction (Hz)
    zeta_x = 0.1;    % Damping ratio in X-direction
    zeta_y = 0.1;    % Damping ratio in Y-direction
    F0_over_m = 1.0; % Normalized driving force amplitude

    w_x_nat = 2 * pi * f_x_nat;
    w_y_nat = 2 * pi * f_y_nat;

    % --- Slider Frequency Range ---
    f_min = 1.0;   
    f_max = 20.0;  
    f_start = f_x_nat; 

    %% --- 2. Create the GUI Elements ---
    hFig = figure('Name', 'Live Laser Simulation', ...
                  'Position', [200, 200, 600, 700], ...
                  'NumberTitle', 'off', ...
                  'DeleteFcn', @onFigClose); % Add a close function

    hAx = axes('Parent', hFig, ...
               'Position', [0.15, 0.25, 0.75, 0.7]);
    
    % --- Create Plot Handles ---
    % hTrail: The "ghost" path of the full ellipse
    hTrail = plot(hAx, NaN, NaN, 'LineWidth', 1, 'Color', [0.5 0.5 0.5]); % Gray
    hold(hAx, 'on');
    % hDot: The "live" laser dot
    hDot = plot(hAx, NaN, NaN, 'r.', 'MarkerSize', 30); % Red dot
    hold(hAx, 'off');
    
    grid(hAx, 'on');
    axis(hAx, 'equal');
    xlabel(hAx, 'X Position (Normalized)');
    ylabel(hAx, 'Y Position (Normalized)');
    
    % --- Set STATIC Axis Limits (for normalized display) ---
    axis_limit = 1.1;
    xlim(hAx, [-axis_limit, axis_limit]);
    ylim(hAx, [-axis_limit, axis_limit]);
    
    % --- GUI Controls (Slider and Text) ---
    hSlider = uicontrol('Parent', hFig, ...
                        'Style', 'slider', ...
                        'Min', f_min, 'Max', f_max, 'Value', f_start, ...
                        'Position', [100, 50, 400, 20], ...
                        'Callback', @updatePhysics); % Slider calls updatePhysics

    uicontrol('Parent', hFig, ...
              'Style', 'text', ...
              'String', 'Driving Frequency (Hz):', ...
              'Position', [100, 80, 150, 20], ...
              'HorizontalAlignment', 'left');

    hFreqText = uicontrol('Parent', hFig, ...
                          'Style', 'text', ...
                          'String', sprintf('%.2f Hz', f_start), ...
                          'Position', [250, 80, 100, 20], ...
                          'HorizontalAlignment', 'left', ...
                          'FontWeight', 'bold');

    %% --- 3. Animation Loop Setup ---
    
    % Use a structure to hold the physics state
    % This is how the callback function will pass data to the main loop
    simState = struct();
    simState.run = true; % Loop control flag
    
    % We store 'simState' in the figure's 'UserData'
    % This makes it accessible from anywhere
    set(hFig, 'UserData', simState);
    
    % Run the physics calculation once to initialize
    updatePhysics(hSlider);
    
    % --- Main Animation Loop ---
    t = 0;           % Master simulation time
    dt = 0.002;      % Time step (controls dot speed)
    
    while simState.run
        % Check if the figure window still exists
        if ~ishandle(hFig)
            break;
        end
        
        % Get the physics state (set by the slider callback)
        simState = get(hFig, 'UserData');
        
        % Calculate the dot's CURRENT position
        x_dot = simState.Ax_norm * cos(simState.w_drive * t - simState.phi_x);
        y_dot = simState.Ay_norm * cos(simState.w_drive * t - simState.phi_y);
        
        % Update the dot's XData and YData
        set(hDot, 'XData', x_dot, 'YData', y_dot);
        
        % Increment time
        t = t + dt;
        
        % Refresh the plot
        % 'limitrate' is better for animation than plain 'drawnow'
        drawnow limitrate; 
    end
    
    %% --- 4. Nested Callback Functions ---

    function updatePhysics(sliderObj, ~)
        % This function is called ONLY when the slider is moved.
        % It calculates the ellipse shape and updates the "trail".
        
        % Get current state and frequency
        simState = get(hFig, 'UserData');
        f_drive = get(sliderObj, 'Value');
        w_drive = 2 * pi * f_drive;

        % --- Calculate PHYSICAL Amplitudes & Phases ---
        A_x_phys = F0_over_m / sqrt((w_x_nat^2 - w_drive^2)^2 + (2 * zeta_x * w_x_nat * w_drive)^2);
        A_y_phys = F0_over_m / sqrt((w_y_nat^2 - w_drive^2)^2 + (2 * zeta_y * w_y_nat * w_drive)^2);
        phi_x = atan2(2 * zeta_x * w_x_nat * w_drive, w_x_nat^2 - w_drive^2);
        phi_y = atan2(2 * zeta_y * w_y_nat * w_drive, w_y_nat^2 - w_drive^2);
        
        % --- Normalize for Plotting ---
        max_phys_amp = max(abs([A_x_phys, A_y_phys]));
        if max_phys_amp < 1e-9, max_phys_amp = 1.0; end
        
        A_x_norm = A_x_phys / max_phys_amp;
        A_y_norm = A_y_phys / max_phys_amp;

        % --- Calculate the "Trail" (the full ellipse path) ---
        T_period = 1 / f_drive;
        t_trail = linspace(0, T_period, 500); % 1 full cycle is enough
        
        x_trail = A_x_norm * cos(w_drive * t_trail - phi_x);
        y_trail = A_y_norm * cos(w_drive * t_trail - phi_y);
        
        % --- Update the "Trail" plot ---
        set(hTrail, 'XData', x_trail, 'YData', y_trail);
        
        % --- Update Titles and Text ---
        set(hFreqText, 'String', sprintf('%.2f Hz', f_drive));
        phase_diff_deg = (phi_y - phi_x) * 180/pi;
        title_str = sprintf('Laser Projection at %.2f Hz', f_drive);
        shape_str = sprintf('Normalized Shape (Ratio): [X=%.2f, Y=%.2f] | Phase: %.1f°', ...
                           A_x_norm, A_y_norm, phase_diff_deg);
        title(hAx, {title_str, shape_str});

        % --- Save updated state for the animation loop ---
        simState.w_drive = w_drive;
        simState.Ax_norm = A_x_norm;
        simState.Ay_norm = A_y_norm;
        simState.phi_x = phi_x;
        simState.phi_y = phi_y;
        set(hFig, 'UserData', simState);
    end

    function onFigClose(~, ~)
        % This function is called when the user closes the figure window.
        % It sets the 'run' flag to false, stopping the while loop.
        try
            simState = get(hFig, 'UserData');
            simState.run = false;
            set(hFig, 'UserData', simState);
        catch
            % Figure may already be gone, just exit
        end
        disp('Simulation stopped.');
    end

end