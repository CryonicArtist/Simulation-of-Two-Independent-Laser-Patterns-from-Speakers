function live_laser_sim_persistence()
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
    
    % --- Persistence Slider Range ---
    p_min = 1;     % Min trail length (1 point = dot)
    p_max = 500;   % Max trail length (500 points = full ellipse)
    p_start = 50;  % Default trail length

    %% --- 2. Create the GUI Elements ---
    hFig = figure('Name', 'Live Laser Simulation', ...
                  'Position', [200, 100, 600, 800], ... % Made figure taller
                  'NumberTitle', 'off', ...
                  'DeleteFcn', @onFigClose); 

    % --- Plot Axes (moved up) ---
    hAx = axes('Parent', hFig, ...
               'Position', [0.15, 0.30, 0.75, 0.65]);
    
    % --- Create Plot Handles ---
    hTrail = plot(hAx, NaN, NaN, 'LineWidth', 1, 'Color', [0.5 0.5 0.5]); % Gray
    hold(hAx, 'on');
    % hDot is now the "trail" or "comet"
    hDot = plot(hAx, NaN, NaN, 'r', 'LineWidth', 3); % Thicker red line
    hold(hAx, 'off');
    
    grid(hAx, 'on');
    axis(hAx, 'equal');
    xlabel(hAx, 'X Position (Normalized)');
    ylabel(hAx, 'Y Position (Normalized)');
    
    % --- Set STATIC Axis Limits ---
    axis_limit = 1.1;
    xlim(hAx, [-axis_limit, axis_limit]);
    ylim(hAx, [-axis_limit, axis_limit]);
    
    % --- Frequency Slider (moved up) ---
    uicontrol('Parent', hFig, ...
              'Style', 'text', ...
              'String', 'Driving Frequency (Hz):', ...
              'Position', [100, 140, 150, 20], ...
              'HorizontalAlignment', 'left');

    hFreqText = uicontrol('Parent', hFig, ...
                          'Style', 'text', ...
                          'String', sprintf('%.2f Hz', f_start), ...
                          'Position', [250, 140, 100, 20], ...
                          'HorizontalAlignment', 'left', ...
                          'FontWeight', 'bold');
                          
    hSlider = uicontrol('Parent', hFig, ...
                        'Style', 'slider', ...
                        'Min', f_min, 'Max', f_max, 'Value', f_start, ...
                        'Position', [100, 110, 400, 20], ...
                        'Callback', @updatePhysics);

    % --- NEW: Persistence Slider ---
    uicontrol('Parent', hFig, ...
              'Style', 'text', ...
              'String', 'Persistence (Trail Length):', ...
              'Position', [100, 80, 160, 20], ...
              'HorizontalAlignment', 'left');
              
    hPersistenceText = uicontrol('Parent', hFig, ...
                                 'Style', 'text', ...
                                 'String', sprintf('%d points', p_start), ...
                                 'Position', [260, 80, 100, 20], ...
                                 'HorizontalAlignment', 'left', ...
                                 'FontWeight', 'bold');

    hPersistenceSlider = uicontrol('Parent', hFig, ...
                                   'Style', 'slider', ...
                                   'Min', p_min, 'Max', p_max, 'Value', p_start, ...
                                   'Position', [100, 50, 400, 20], ...
                                   'Callback', @updatePersistenceText); % Updates text

    %% --- 3. Animation Loop Setup ---
    
    % Use a structure to hold the physics state
    simState = struct();
    simState.run = true; % Loop control flag
    simState.x_history = []; % NEW: Stores the dot's trail
    simState.y_history = []; % NEW: Stores the dot's trail
    
    set(hFig, 'UserData', simState);
    
    % Run the physics calculation once to initialize
    updatePhysics(hSlider);
    
    % --- Main Animation Loop ---
    t = 0;           % Master simulation time
    dt = 0.002;      % Time step (controls dot speed)
    
    while true
        % Check if the figure window still exists or run flag is false
        if ~ishandle(hFig)
            break;
        end
        simState = get(hFig, 'UserData');
        if ~simState.run
            break;
        end
        
        % --- NEW: Get persistence length from slider ---
        persistence_length = round(get(hPersistenceSlider, 'Value'));
        
        % Calculate the dot's CURRENT position
        x_dot = simState.Ax_norm * cos(simState.w_drive * t - simState.phi_x);
        y_dot = simState.Ay_norm * cos(simState.w_drive * t - simState.phi_y);
        
        % --- NEW: Update the history buffer ---
        % Add new point
        simState.x_history = [simState.x_history, x_dot];
        simState.y_history = [simState.y_history, y_dot];
        
        % Trim history to the persistence length
        if length(simState.x_history) > persistence_length
            simState.x_history = simState.x_history(end-persistence_length+1:end);
            simState.y_history = simState.y_history(end-persistence_length+1:end);
        end
        
        % Update the dot's XData and YData with the *entire trail*
        set(hDot, 'XData', simState.x_history, 'YData', simState.y_history);
        
        % Increment time
        t = t + dt;
        
        % Refresh the plot
        drawnow limitrate;
        
        % Put the state back (with updated history)
        set(hFig, 'UserData', simState);
    end
    
    %% --- 4. Nested Callback Functions ---

    function updatePhysics(sliderObj, ~)
        % Called when the FREQUENCY slider is moved.
        
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
        t_trail = linspace(0, T_period, 500); 
        x_trail = A_x_norm * cos(w_drive * t_trail - phi_x);
        y_trail = A_y_norm * cos(w_drive * t_trail - phi_y);
        
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
        
        % --- NEW: Clear the history buffer ---
        % Since the shape changed, the old trail is invalid
        simState.x_history = [];
        simState.y_history = [];
        
        set(hFig, 'UserData', simState);
    end

    function updatePersistenceText(sliderObj, ~)
        % This simple callback just updates the text for the new slider
        p_val = round(get(sliderObj, 'Value'));
        set(hPersistenceText, 'String', sprintf('%d points', p_val));
    end

    function onFigClose(~, ~)
        % Sets the 'run' flag to false, stopping the while loop.
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