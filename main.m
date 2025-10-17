function laser_speaker_slider()
    % Main function to create the GUI for the laser speaker simulation
    
    clear;      % Clear workspace variables
    clc;        % Clear command window
    close all;  % Close all figures

    %% --- 1. Define System Parameters ---
    f_x_nat = 10.0;  % Natural frequency in X-direction (Hz)
    f_y_nat = 12.0;  % Natural frequency in Y-direction (Hz)
    zeta_x = 0.1;    % Damping ratio in X-direction (dimensionless)
    zeta_y = 0.1;    % Damping ratio in Y-direction (dimensionless)

    F0_over_m = 1.0; % Normalized driving force amplitude (F_0 / m)

    % --- Convert to angular frequencies (rad/s) ---
    w_x_nat = 2 * pi * f_x_nat;
    w_y_nat = 2 * pi * f_y_nat;

    % --- Define Slider Frequency Range ---
    f_min = 1.0;   % Minimum frequency on the slider (Hz)
    f_max = 20.0;  % Maximum frequency on the slider (Hz)
    f_start = f_x_nat; % Initial slider position (Hz)

    %% --- 2. Create the GUI Elements ---
    hFig = figure('Name', 'Laser Speaker Simulation (Normalized)', ...
                  'Position', [200, 200, 600, 700], ...
                  'NumberTitle', 'off');

    hAx = axes('Parent', hFig, ...
               'Position', [0.15, 0.25, 0.75, 0.7]);
    
    hPlot = plot(hAx, NaN, NaN, 'r', 'LineWidth', 2);
    
    grid(hAx, 'on');
    axis(hAx, 'equal');
    xlabel(hAx, 'X Position (Normalized)');
    ylabel(hAx, 'Y Position (Normalized)');

    hSlider = uicontrol('Parent', hFig, ...
                        'Style', 'slider', ...
                        'Min', f_min, 'Max', f_max, 'Value', f_start, ...
                        'Position', [100, 50, 400, 20]);

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

    %% --- 3. Link Slider to Callback Function ---
    addlistener(hSlider, 'ContinuousValueChange', @updatePlot);

    %% --- 4. Call the update function once to draw the initial plot ---
    updatePlot(hSlider); 

    %% --- 5. Nested Callback Function ---
    function updatePlot(sliderObj, ~)
        % Get the current frequency from the slider
        f_drive = sliderObj.Value;
        w_drive = 2 * pi * f_drive;

        % --- Calculate PHYSICAL Steady-State Response ---
        % (We temporarily store these as 'phys' to normalize them)
        A_x_phys = F0_over_m / sqrt((w_x_nat^2 - w_drive^2)^2 + (2 * zeta_x * w_x_nat * w_drive)^2);
        A_y_phys = F0_over_m / sqrt((w_y_nat^2 - w_drive^2)^2 + (2 * zeta_y * w_y_nat * w_drive)^2);
        
        phi_x = atan2(2 * zeta_x * w_x_nat * w_drive, w_x_nat^2 - w_drive^2);
        phi_y = atan2(2 * zeta_y * w_y_nat * w_drive, w_y_nat^2 - w_drive^2);
        
        phase_diff_deg = (phi_y - phi_x) * 180/pi;

        % --- *** NEW: NORMALIZE AMPLITUDES *** ---
        % Find the largest physical amplitude
        max_phys_amp = max(abs([A_x_phys, A_y_phys]));
        
        % Avoid division by zero if frequencies are far off
        if max_phys_amp < 1e-9 
            max_phys_amp = 1e-9;
        end
        
        % Set the PLOTTING amplitudes by dividing by the max.
        % This forces the largest amplitude to be 1.0,
        % but preserves the ratio A_x / A_y (which defines the shape).
        A_x = A_x_phys / max_phys_amp;
        A_y = A_y_phys / max_phys_amp;
        % --- *** END OF NEW CODE *** ---
        
        % --- Generate Waveform ---
        T_period = 1 / f_drive;
        t = linspace(0, 3 * T_period, 1000); 

        x_t = A_x * cos(w_drive * t - phi_x);
        y_t = A_y * cos(w_drive * t - phi_y);

        % --- Update Plot Data (Fast!) ---
        set(hPlot, 'XData', x_t, 'YData', y_t);

        % --- *** MODIFIED: Use STATIC Axis Limits *** ---
        % Since the max amplitude is now always 1.0,
        % we can use a fixed "static" display.
        axis_limit = 1.1; % 10% buffer
        xlim(hAx, [-axis_limit, axis_limit]);
        ylim(hAx, [-axis_limit, axis_limit]);
        % --- *** END OF MODIFIED CODE *** ---
        
        % --- Update Titles and Labels ---
        % We will display the NORMALIZED amplitudes [A_x, A_y]
        % but also show the PHYSICAL amplitudes [A_x_phys, A_y_phys]
        % to understand what's "really" happening.
        
        title_str = sprintf('Laser Projection at %.2f Hz', f_drive);
        
        % Show the normalized (plot) ratio
        shape_str = sprintf('Normalized Shape (Ratio): [X=%.2f, Y=%.2f]', A_x, A_y);
        
        % Show the physical amplitudes
        phys_str = sprintf('Physical Amps: [X=%.3f, Y=%.3f] | Phase: %.1f°', ...
                           A_x_phys, A_y_phys, phase_diff_deg);
                           
        title(hAx, {title_str, shape_str, phys_str});
        
        set(hFreqText, 'String', sprintf('%.2f Hz', f_drive));
    end

end