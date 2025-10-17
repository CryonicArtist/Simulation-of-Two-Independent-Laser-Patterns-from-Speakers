function live_multi_slider_sim()
    % Main function to create the GUI and run the live animation
    
    clear;      % Clear workspace variables
    clc;        % Clear command window
    close all;  % Close all figures

    %% --- 1. Define System Parameters ---
    f_x_nat = 10.0;  % Natural frequency in X-direction (Hz)
    f_y_nat = 12.0;  % Natural frequency in Y-direction (Hz)
    zeta_x = 0.05;   % Damping ratio in X (Made smaller for sharper peaks)
    zeta_y = 0.05;   % Damping ratio in Y (Made smaller for sharper peaks)
    F0_over_m = 1.0; % Normalized driving force amplitude

    w_x_nat = 2 * pi * f_x_nat;
    w_y_nat = 2 * pi * f_y_nat;
    
    % --- Slider Ranges ---
    f_min = 0.0;     % 0 Hz will mean "off"
    f_max = 20.0;    
    p_min = 1;       % Min trail length (1 point = dot)
    p_max = 500;     % Max trail length (500 points)
    
    % --- Initial Frequencies ---
    f_start_1 = 10.0;
    f_start_2 = 12.0;
    f_start_3 = 0.0; % Off by default
    
    % --- Simulation Time Parameters ---
    T_sim_trail = 5.0;  % Total time to pre-calculate for the gray trail (s)
    N_points_trail = 20000; % Number of points for the gray trail
    
    %% --- 2. Create the GUI Elements ---
    hFig = figure('Name', 'Live Multi-Slider Simulation', ...
                  'Position', [200, 100, 600, 900], ... % Very tall figure
                  'NumberTitle', 'off', ...
                  'DeleteFcn', @onFigClose); 

    hAx = axes('Parent', hFig, ...
               'Position', [0.15, 0.40, 0.75, 0.55]); % Plot at the top
    
    % --- Create Plot Handles ---
    hTrail = plot(hAx, NaN, NaN, 'LineWidth', 1, 'Color', [0.5 0.5 0.5]); % Gray
    hold(hAx, 'on');
    hDot = plot(hAx, NaN, NaN, 'r', 'LineWidth', 3); % Red trail
    hold(hAx, 'off');
    
    grid(hAx, 'on');
    axis(hAx, 'equal');
    xlabel(hAx, 'X Position (Normalized)');
    ylabel(hAx, 'Y Position (Normalized)');
    
    % --- Set STATIC Axis Limits ---
    axis_limit = 1.1;
    xlim(hAx, [-axis_limit, axis_limit]);
    ylim(hAx, [-axis_limit, axis_limit]);
    
    % --- GUI Controls (3 Freq Sliders + 1 Persistence Slider) ---
    
    % --- Frequency Slider 1 ---
    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Frequency 1 (0=Off):', ...
              'Position', [100, 300, 150, 20], 'HorizontalAlignment', 'left');
    hFreqText1 = uicontrol('Parent', hFig, 'Style', 'text', 'String', sprintf('%.2f Hz', f_start_1), ...
                           'Position', [250, 300, 100, 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    hFreqSlider1 = uicontrol('Parent', hFig, 'Style', 'slider', 'Min', f_min, 'Max', f_max, 'Value', f_start_1, ...
                             'Position', [100, 270, 400, 20], 'Callback', @updatePhysics);

    % --- Frequency Slider 2 ---
    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Frequency 2 (0=Off):', ...
              'Position', [100, 240, 150, 20], 'HorizontalAlignment', 'left');
    hFreqText2 = uicontrol('Parent', hFig, 'Style', 'text', 'String', sprintf('%.2f Hz', f_start_2), ...
                           'Position', [250, 240, 100, 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    hFreqSlider2 = uicontrol('Parent', hFig, 'Style', 'slider', 'Min', f_min, 'Max', f_max, 'Value', f_start_2, ...
                             'Position', [100, 210, 400, 20], 'Callback', @updatePhysics);
                             
    % --- Frequency Slider 3 ---
    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Frequency 3 (0=Off):', ...
              'Position', [100, 180, 150, 20], 'HorizontalAlignment', 'left');
    hFreqText3 = uicontrol('Parent', hFig, 'Style', 'text', 'String', sprintf('%.2f Hz', f_start_3), ...
                           'Position', [250, 180, 100, 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    hFreqSlider3 = uicontrol('Parent', hFig, 'Style', 'slider', 'Min', f_min, 'Max', f_max, 'Value', f_start_3, ...
                             'Position', [100, 150, 400, 20], 'Callback', @updatePhysics);

    % --- Persistence Slider ---
    uicontrol('Parent', hFig, 'Style', 'text', 'String', 'Persistence (Trail Length):', ...
              'Position', [100, 80, 160, 20], 'HorizontalAlignment', 'left');
    hPersistenceText = uicontrol('Parent', hFig, 'Style', 'text', 'String', sprintf('%d points', p_max/2), ...
                                 'Position', [260, 80, 100, 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    hPersistenceSlider = uicontrol('Parent', hFig, 'Style', 'slider', 'Min', p_min, 'Max', p_max, 'Value', p_max/2, ...
                                   'Position', [100, 50, 400, 20], 'Callback', @updatePersistenceText); 

    %% --- 3. Animation Loop Setup ---
    
    simState = struct();
    simState.run = true; % Loop control flag
    simState.x_history = []; % Stores the dot's trail
    simState.y_history = [];
    simState.freq_params = {}; % Will store physics for each freq
    simState.max_extent = 1.0; % Normalization factor
    
    set(hFig, 'UserData', simState);
    
    % Run the physics calculation once to initialize
    updatePhysics();
    
    % --- Main Animation Loop ---
    t = 0;           % Master simulation time
    dt = 0.0005;     % Time step (needs to be smaller for complex shapes)
    
    while true
        if ~ishandle(hFig)
            break;
        end
        simState = get(hFig, 'UserData');
        if ~simState.run
            break;
        end
        
        persistence_length = round(get(hPersistenceSlider, 'Value'));
        
        % --- Calculate Dot's CURRENT Position (Superposition) ---
        x_dot_phys = 0;
        y_dot_phys = 0;
        
        for k = 1:length(simState.freq_params)
            params = simState.freq_params{k};
            x_dot_phys = x_dot_phys + params.Ax_phys * cos(params.w_drive * t - params.phi_x);
            y_dot_phys = y_dot_phys + params.Ay_phys * cos(params.w_drive * t - params.phi_y);
        end
        
        % --- Normalize ---
        x_dot = x_dot_phys / simState.max_extent;
        y_dot = y_dot_phys / simState.max_extent;
        
        % --- Update history buffer ---
        simState.x_history = [simState.x_history, x_dot];
        simState.y_history = [simState.y_history, y_dot];
        
        if length(simState.x_history) > persistence_length
            simState.x_history = simState.x_history(end-persistence_length+1:end);
            simState.y_history = simState.y_history(end-persistence_length+1:end);
        end
        
        set(hDot, 'XData', simState.x_history, 'YData', simState.y_history);
        t = t + dt;
        drawnow limitrate;
        set(hFig, 'UserData', simState);
    end
    
    %% --- 4. Nested Callback Functions ---

    function updatePhysics(~, ~)
        % Called when ANY frequency slider is moved.
        
        simState = get(hFig, 'UserData');
        
        % --- Get Frequencies from ALL sliders ---
        f1 = get(hFreqSlider1, 'Value');
        f2 = get(hFreqSlider2, 'Value');
        f3 = get(hFreqSlider3, 'Value');
        
        % --- Update text labels ---
        set(hFreqText1, 'String', sprintf('%.2f Hz', f1));
        set(hFreqText2, 'String', sprintf('%.2f Hz', f2));
        set(hFreqText3, 'String', sprintf('%.2f Hz', f3));
        
        % --- Build the list of active frequencies ---
        f_drives = [f1, f2, f3];
        f_drives(f_drives <= 0) = []; % Remove all frequencies <= 0
        
        if isempty(f_drives)
            % If all sliders are at 0, clear the plot
            set(hTrail, 'XData', NaN, 'YData', NaN);
            simState.freq_params = {};
            simState.x_history = [];
            simState.y_history = [];
            title(hAx, 'Set a frequency above 0 Hz');
            set(hFig, 'UserData', simState);
            return;
        end
        
        % --- Calculate Physics for Each Active Frequency ---
        simState.freq_params = {}; % Clear old parameters
        for f_drive = f_drives
            w_drive = 2 * pi * f_drive;
            params = struct();
            
            params.w_drive = w_drive;
            params.Ax_phys = F0_over_m / sqrt((w_x_nat^2 - w_drive^2)^2 + (2 * zeta_x * w_x_nat * w_drive)^2);
            params.Ay_phys = F0_over_m / sqrt((w_y_nat^2 - w_drive^2)^2 + (2 * zeta_y * w_y_nat * w_drive)^2);
            params.phi_x = atan2(2 * zeta_x * w_x_nat * w_drive, w_x_nat^2 - w_drive^2);
            params.phi_y = atan2(2 * zeta_y * w_y_nat * w_drive, w_y_nat^2 - w_drive^2);
            
            simState.freq_params{end+1} = params;
        end
        
        % --- Pre-Calculate Full Trail for Normalization ---
        t_trail_vec = linspace(0, T_sim_trail, N_points_trail);
        x_trail_total = zeros(1, N_points_trail);
        y_trail_total = zeros(1, N_points_trail);
        
        for k = 1:length(simState.freq_params)
            params = simState.freq_params{k};
            x_trail_total = x_trail_total + params.Ax_phys * cos(params.w_drive * t_trail_vec - params.phi_x);
            y_trail_total = y_trail_total + params.Ay_phys * cos(params.w_drive * t_trail_vec - params.phi_y);
        end
        
        % --- Find Normalization Factor ---
        simState.max_extent = max(abs([x_trail_total, y_trail_total]));
        if simState.max_extent < 1e-9, simState.max_extent = 1.0; end
        
        % --- Normalize and Plot the Gray "Ghost" Trail ---
        x_trail_plot = x_trail_total / simState.max_extent;
        y_trail_plot = y_trail_total / simState.max_extent;
        set(hTrail, 'XData', x_trail_plot, 'YData', y_trail_plot);
        
        % --- Clear History and Update Title ---
        simState.x_history = [];
        simState.y_history = [];
        
        freq_string = sprintf('%.2f ', f_drives);
        title_str = ['Active Frequencies: ', freq_string, 'Hz'];
        title(hAx, {title_str, 'Normalized to fit display'});

        % --- Save updated state for the animation loop ---
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