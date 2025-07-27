classdef Audio_analysis_tool < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        DarkmodeSwitch               matlab.ui.control.Switch
        DarkmodeSwitchLabel          matlab.ui.control.Label
        ApplyButton                  matlab.ui.control.Button
        CustomFilterDropDown         matlab.ui.control.DropDown
        CustomFilterDropDownLabel    matlab.ui.control.Label
        TimesEditField               matlab.ui.control.NumericEditField
        TimesEditFieldLabel          matlab.ui.control.Label
        MaxAmplitudeEditField        matlab.ui.control.NumericEditField
        MaxAmplitudeEditFieldLabel   matlab.ui.control.Label
        SampleRateEditField          matlab.ui.control.NumericEditField
        SampleRateLabel              matlab.ui.control.Label
        StopbandFrequency2EditField  matlab.ui.control.NumericEditField
        StopbandFrequency2Label      matlab.ui.control.Label
        PassbandFrequency2EditField  matlab.ui.control.NumericEditField
        PassbandFrequency2Label      matlab.ui.control.Label
        StopbandFrequencyEditField   matlab.ui.control.NumericEditField
        StopbandFrequencyLabel       matlab.ui.control.Label
        PassbandFrequencyEditField   matlab.ui.control.NumericEditField
        PassbandFrequencyLabel       matlab.ui.control.Label
        RecordButton                 matlab.ui.control.Button
        SpeedSlider                  matlab.ui.control.Slider
        SpeedSliderLabel             matlab.ui.control.Label
        VolumeSlider                 matlab.ui.control.Slider
        VolumeSlider_2Label          matlab.ui.control.Label
        LoadButton                   matlab.ui.control.Button
        SaveButton                   matlab.ui.control.Button
        PlayButton                   matlab.ui.control.Button
        PlaystatementLamp            matlab.ui.control.Lamp
        Label_5                      matlab.ui.control.Label
        GraphButtonGroup             matlab.ui.container.ButtonGroup
        SpectrogramButton            matlab.ui.control.RadioButton
        SpectrumButton               matlab.ui.control.RadioButton
        WaveformButton               matlab.ui.control.RadioButton
        FiltersFIRDropDown           matlab.ui.control.DropDown
        Label                        matlab.ui.control.Label
        UIAxes                       matlab.ui.control.UIAxes
    end


    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end

    
    properties (Access = private)
        % Audio information
        fileName         string    % Name of user-loaded audio file
        yOriginal        double    % Original audio data
        fsOriginal       double    % Original sample rate
        yCurrent         double    % Manipulated audio data
        fsCurrent        double    % Manipulated sample rate
        channel          int32     % # of channel of audio
        duration         double    % Duration of audio
        maxAmp           double    % Amplitude of audio
        

        % App status
        recorder         audiorecorder      % Audio recorder (from MATLAB)
        recordStatement  logical = false    % is recording or not
        player           audioplayer        % Audio player (from MATLAB)
        playStatement    logical = false    % is playing or not
        

        % Filter information
        filter                     % Filter
        lowPassBand      double    % Parameters of low-pass filter
        lowStopBand      double             
        highPassBand     double    % Parameters of high-pass filter
        highStopBand     double             
        bpPassBand1      double    % Parameter of band-pass filter
        bpPassBand2      double             
        bpStopBand1      double             
        bpStopBand2      double             
        bsPassBand1      double    % Parameter of band-stop filter
        bsPassBand2      double             
        bsStopBand1      double             
        bsStopBand2      double             
        firstTimeCustom  logical = true    % is the first time switch to custom filter or not
        minTransition    double = 1000     % Minimum transition (check input)
        minPassBandWidth double = 2000     % Minimum pass band
        minStopBandWidth double = 2000     % Minimum stop band
        w                double    % Window of box filter
        sigma            double    % Sigma value of Gaussian filter


        % Properties for display playing progress
        playingTimer     timer           % Timer of playing status
        progressLine                     % Vertical line to show playing progress
        currentTime      double = 0      % Current playing time
        

        % Plot color
        lineColor1       double    % Color of waveform
        lineColor2       double    % Color of spectrum
        progressColor    double    % Color of playing progress line
    end

    
    methods (Access = private)
        % Reset all ui
        function Reset_UI(app)
            % Graph
            app.GraphButtonGroup.SelectedObject = app.WaveformButton;
            
            % Filter
            app.FiltersFIRDropDown.Value = 'None';

            % Custom filter
            app.CustomFilterDropDown.Visible = "off";
            app.CustomFilterDropDownLabel.Visible = "off";
            app.CustomFilterDropDown.Value = 'Low-pass';

            app.ApplyButton.Visible = "off";
            
            % Volume and speed sliders
            app.VolumeSlider.Value = 1;
            app.SpeedSlider.Value = 1;

            % play statement
            if app.playStatement
                stop(app.player);
                app.PlayButton.Text = 'Play';
                app.PlaystatementLamp.Color = 'red';
                app.playStatement = false;
            end

            % Parameter edit fields
            app.PassbandFrequencyEditField.Visible = "off";
            app.PassbandFrequencyLabel.Visible = "off";
            app.PassbandFrequencyEditField.Value = 3000;
            
            app.StopbandFrequencyEditField.Visible = "off";
            app.StopbandFrequencyLabel.Visible = "off";
            app.StopbandFrequencyEditField.Value = 5000;

            app.PassbandFrequency2EditField.Visible = "off";
            app.PassbandFrequency2Label.Visible = "off";
            app.PassbandFrequency2EditField.Value = 6000;

            app.StopbandFrequency2EditField.Visible = "off";
            app.StopbandFrequency2Label.Visible = "off";
            app.StopbandFrequency2EditField.Value = 8000;
        end
        

        % Show parameters
        function Show_info(app)
            % Max amplitude, sample rate, time (always display)
            app.MaxAmplitudeEditField.Value = app.maxAmp;
            app.SampleRateEditField.ValueDisplayFormat = '%.0f';
            app.SampleRateEditField.Value = app.fsCurrent;
            app.TimesEditField.Value = app.duration;

            app.Show_widget();

            % Show parameters of filter (if used)
            switch app.FiltersFIRDropDown.Value
                case 'Low-pass'
                    app.PassbandFrequencyEditField.Value = app.lowPassBand;
                    app.StopbandFrequencyEditField.Value = app.lowStopBand;
                case 'High-pass'
                    app.PassbandFrequencyEditField.Value = app.highPassBand;
                    app.StopbandFrequencyEditField.Value = app.highStopBand;
                case 'Band-pass'
                    app.PassbandFrequencyEditField.Value = app.bpPassBand1;
                    app.StopbandFrequencyEditField.Value = app.bpStopBand1;
                    app.PassbandFrequency2EditField.Value = app.bpPassBand2;
                    app.StopbandFrequency2EditField.Value = app.bpStopBand2;
                case 'Band-stop'
                    app.PassbandFrequencyEditField.Value = app.bsPassBand1;
                    app.StopbandFrequencyEditField.Value = app.bsStopBand1;
                    app.PassbandFrequency2EditField.Value = app.bsPassBand2;
                    app.StopbandFrequency2EditField.Value = app.bsStopBand2;
                case 'Box'
                    app.PassbandFrequencyEditField.Value = app.w;
                case 'Gaussian'
                    app.PassbandFrequencyEditField.Value = app.sigma;
            end
        end
        

        % Control the visibility and editability of ui widgets (Decide by chosen built-in filter)
        function Show_widget(app)
            if isequal(app.FiltersFIRDropDown.Value, 'Low-pass') || isequal(app.FiltersFIRDropDown.Value, 'High-pass') 
                app.PassbandFrequencyLabel.Text = 'Passband Frequency';
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyLabel.Visible = "on";
                app.PassbandFrequency2EditField.Editable = "off";

                app.StopbandFrequencyEditField.Visible = "on";
                app.StopbandFrequencyLabel.Visible = "on";
                app.StopbandFrequencyEditField.Editable = "off";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2Label.Visible = "off";
                
                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2Label.Visible = "off";

                app.CustomFilterDropDown.Visible = "off";
                app.CustomFilterDropDownLabel.Visible = "off";
                app.ApplyButton.Visible = "off";
            elseif isequal(app.FiltersFIRDropDown.Value, 'None')
                app.PassbandFrequencyLabel.Text = 'Passband Frequency';
                app.PassbandFrequencyEditField.Visible = "off";
                app.PassbandFrequencyLabel.Visible = "off";

                app.StopbandFrequencyEditField.Visible = "off";
                app.StopbandFrequencyLabel.Visible = "off";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2Label.Visible = "off";

                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2Label.Visible = "off";

                app.CustomFilterDropDown.Visible = "off";
                app.CustomFilterDropDownLabel.Visible = "off";
                app.ApplyButton.Visible = "off";
            elseif isequal(app.FiltersFIRDropDown.Value, 'Band-pass') || isequal(app.FiltersFIRDropDown.Value, 'Band-stop')
                app.PassbandFrequencyLabel.Text = 'Passband Frequency';
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "off";

                app.StopbandFrequencyEditField.Visible = "on";
                app.StopbandFrequencyLabel.Visible = "on";
                app.StopbandFrequencyEditField.Editable = "off";

                app.PassbandFrequency2EditField.Visible = "on";
                app.PassbandFrequency2Label.Visible = "on";
                app.PassbandFrequency2EditField.Editable = "off";

                app.StopbandFrequency2EditField.Visible = "on";
                app.StopbandFrequency2Label.Visible = "on";
                app.StopbandFrequency2EditField.Editable = "off";

                app.CustomFilterDropDown.Visible = "off";
                app.CustomFilterDropDownLabel.Visible = "off";
                app.ApplyButton.Visible = "off";
            elseif isequal(app.FiltersFIRDropDown.Value, 'Box')
                app.PassbandFrequencyLabel.Text = 'W';
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "off";

                app.StopbandFrequencyEditField.Visible = "off";
                app.StopbandFrequencyLabel.Visible = "off";
                app.StopbandFrequencyEditField.Editable = "off";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2Label.Visible = "off";
                app.PassbandFrequency2EditField.Editable = "off";

                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2Label.Visible = "off";
                app.StopbandFrequency2EditField.Editable = "off";

                app.CustomFilterDropDown.Visible = "off";
                app.CustomFilterDropDownLabel.Visible = "off";
                app.ApplyButton.Visible = "off";
            elseif isequal(app.FiltersFIRDropDown.Value, 'Gaussian')
                app.PassbandFrequencyLabel.Text = 'Sigma';
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "off";

                app.StopbandFrequencyEditField.Visible = "off";
                app.StopbandFrequencyLabel.Visible = "off";
                app.StopbandFrequencyEditField.Editable = "off";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2Label.Visible = "off";
                app.PassbandFrequency2EditField.Editable = "off";

                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2Label.Visible = "off";
                app.StopbandFrequency2EditField.Editable = "off";

                app.CustomFilterDropDown.Visible = "off";
                app.CustomFilterDropDownLabel.Visible = "off";
                app.ApplyButton.Visible = "off";
            else
                app.CustomFilterDropDown.Visible = "on";
                app.CustomFilterDropDownLabel.Visible = "on";
                app.ApplyButton.Visible = "on";

                app.Show_widget_by_custom();
            end
        end
        

        % Control the visibility and editability of ui widgets (Decide by chosen custom filter)
        function Show_widget_by_custom(app)
            if isequal(app.CustomFilterDropDown.Value, 'Low-pass') || isequal(app.CustomFilterDropDown.Value, 'High-pass') 
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "on";

                app.StopbandFrequencyEditField.Visible = "on";
                app.StopbandFrequencyLabel.Visible = "on";
                app.StopbandFrequencyEditField.Editable = "on";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2Label.Visible = "off";
                
                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2Label.Visible = "off";
            elseif isequal(app.CustomFilterDropDown.Value, 'Band-pass') || isequal(app.CustomFilterDropDown.Value, 'Band-stop') 
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "on";

                app.StopbandFrequencyEditField.Visible = "on";
                app.StopbandFrequencyLabel.Visible = "on";
                app.StopbandFrequencyEditField.Editable = "on";

                app.PassbandFrequency2EditField.Visible = "on";
                app.PassbandFrequency2Label.Visible = "on";
                app.PassbandFrequency2EditField.Editable = "on";

                app.StopbandFrequency2EditField.Visible = "on";
                app.StopbandFrequency2Label.Visible = "on";
                app.StopbandFrequency2EditField.Editable = "on";
            elseif isequal(app.CustomFilterDropDown.Value, 'Box')
                app.PassbandFrequencyLabel.Text = 'W';
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "on";

                app.StopbandFrequencyEditField.Visible = "off";
                app.StopbandFrequencyLabel.Visible = "off";
                app.StopbandFrequencyEditField.Editable = "off";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2Label.Visible = "off";
                
                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2Label.Visible = "off";
            else
                app.PassbandFrequencyLabel.Text = 'Sigma';
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "on";

                app.StopbandFrequencyEditField.Visible = "off";
                app.StopbandFrequencyLabel.Visible = "off";
                app.StopbandFrequencyEditField.Editable = "off";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2Label.Visible = "off";
                
                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2Label.Visible = "off";
            end
        end


        % Plot the cohsen graph
        function Plot_graph(app)
            app.Reset_graph();

            % Decide by "graph" radio button
            if app.WaveformButton.Value
                app.Plot_waveform();
            elseif app.SpectrumButton.Value
                app.Plot_spectrum();
            else
                app.Plot_spectrogram();
            end
        end


        % Reset the entire graph
        function Reset_graph(app)
            % Clear graph
            cla(app.UIAxes);
            
            % Reset axis
            app.UIAxes.XScale = 'linear';
            app.UIAxes.YScale = 'linear';
            axis(app.UIAxes, 'xy');
            app.UIAxes.XLimMode = 'auto'; 
            app.UIAxes.YLimMode = 'auto';
            
            % Remove colorbar
            cbar = findall(app.UIAxes.Parent, 'Type', 'ColorBar');
            if ~isempty(cbar)
                delete(cbar);
            end
        end
        

        % Plot waveform
        function Plot_waveform(app)
            % Compute x (time)
            t = (0:length(app.yCurrent) - 1)/app.fsCurrent;
            
            % Plot waveform
            plot(app.UIAxes, t, app.yCurrent, Color=app.lineColor1);

            title(app.UIAxes, 'Waveform');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Amplitude');
        end
        

        % Plot spectrum
        function Plot_spectrum(app)
            % fft
            t1 = fft(app.yCurrent);
            len = length(app.yCurrent);
            t2 = abs(t1 / len);
            t3 = t2(1:floor(len / 2 + 1));
            t3(2:end - 1) = 2 * t3(2:end - 1);
            xFreq = app.fsCurrent * (0:floor(len / 2)) / len;
            yMag = t3;

            % Plot spectrum
            plot(app.UIAxes, xFreq, yMag, Color=app.lineColor2);

            title(app.UIAxes, 'Spectrum');
            xlabel(app.UIAxes, 'Frequency (Hz)');
            ylabel(app.UIAxes, 'Amplitude');

            % Limit x-axis (max frequency of human ear or Nyquist frequency)
            maxFreq = 20000;
            if app.fsCurrent / 2 < maxFreq
                maxFreq = app.fsCurrent / 2;
            end
            
            xlim(app.UIAxes, [0, maxFreq]);
        end
        

        % Plot spectrogram
        function Plot_spectrogram(app)
            % More than 1 channel: only take first channel to plot
            if app.channel > 1
                dataToPlot = app.yCurrent(:,1);
            else
                dataToPlot = app.yCurrent;
            end

            % Compute amplitude, frequency and time
            [a, f, t] = spectrogram(dataToPlot, hamming(512), 256, 1024, app.fsCurrent);

            % Plot spectrogram
            imagesc(app.UIAxes, t, f, 20 * log10(abs(a)));
            
            title(app.UIAxes, 'Spectrogram');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Frequency (Hz)');
            colorbar(app.UIAxes);

            xlim(app.UIAxes, [0, t(end)]);
            ylim(app.UIAxes, [0, app.fsCurrent / 2]);
        end
        

        % Prevent user from using objects without loaded any audio data
        function permission = Nload_first_data(app)
            if isempty(app.fsCurrent)
                uialert(app.UIFigure, '尚未載入音訊資料', 'Error', 'Icon', 'error');
                permission = false;
            else
                permission = true;
            end
        end
        

        % Update manipulated audio data
        function Update_audio(app)
            % Stop playing
            app.Stop_playing_audio();

            % Manipulate sample rate
            app.fsCurrent = app.fsOriginal * app.SpeedSlider.Value;

            % Create and apply filter
            app.Filter_audio();

            % Manipulate amplitude
            app.yCurrent = app.yCurrent * app.VolumeSlider.Value;

            % Update druration
            app.duration = length(app.yCurrent) / app.fsCurrent;
            
            % Updata max amplitude
            app.maxAmp = max(abs(app.yCurrent), [], 'all');
        end
        
        
        % Create and apply filter
        function Filter_audio(app)
            fsMax = 100000;
            nyquist = app.fsCurrent / 2;
        
            % Limit max and min sample rates to prevent crash and error
            if (isequal(app.FiltersFIRDropDown.Value, 'None'))
                app.yCurrent = app.yOriginal;
            elseif app.fsCurrent > fsMax
                uialert(app.UIFigure, '取樣率過高，無法設計濾波器，已自動停用濾波器', ...
                        'Error', 'Icon', 'error');
                
                app.FiltersFIRDropDown.Value = 'None';
                app.yCurrent = app.yOriginal;
            elseif nyquist < 6000
                uialert(app.UIFigure, '取樣率過低，無法設計濾波器，已自動停用濾波器', ...
                        'Error', 'Icon', 'error');
                
                app.FiltersFIRDropDown.Value = 'None';
                app.yCurrent = app.yOriginal;
            else
                % Sample rate is permitted -> create filter
                app.Create_filter();
                
                % Apply filter to every channel
                % TODO: create "apply filter" function to make this part
                % clear 
                if isequal(app.FiltersFIRDropDown.Value, 'Box') || ...
                   (isequal(app.FiltersFIRDropDown.Value, 'Custom') && ...
                    isequal(app.CustomFilterDropDown.Value, 'Box'))
                    if app.channel > 1
                        app.yCurrent = zeros(size(app.yOriginal));
                        for i = 1:app.channel
                            app.yCurrent(:, i) = conv(app.yOriginal(:, i), ones(app.w, 1)/app.w, 'same');
                        end
                    else
                        app.yCurrent = conv(app.yOriginal, ones(app.w, 1)/app.w, 'same');
                    end
                elseif isequal(app.FiltersFIRDropDown.Value, 'Gaussian') || ...
                       (isequal(app.FiltersFIRDropDown.Value, 'Custom') && ...
                        isequal(app.CustomFilterDropDown.Value, 'Gaussian'))
                    if app.channel > 1
                        app.yCurrent = zeros(size(app.yOriginal));
                        for i = 1:app.channel
                            app.yCurrent(:, i) = conv(app.yOriginal(:, i), app.filter, 'same');
                        end
                    else
                        app.yCurrent = conv(app.yOriginal, app.filter, 'same');
                    end
                else
                    if app.channel > 1
                        app.yCurrent = zeros(size(app.yOriginal));
                        for i = 1:app.channel
                            app.yCurrent(:,i) = filtfilt(app.filter, app.yOriginal(:,i));
                        end
                    else
                        app.yCurrent = filtfilt(app.filter, app.yOriginal);
                    end
                end
            end
        end


        % Create built-in filter (from user's choice)
        function Create_filter(app)
            switch app.FiltersFIRDropDown.Value
                case 'Low-pass'
                    % Reset first time status
                    app.firstTimeCustom = true;

                    % Default parameters
                    app.lowPassBand = 3000;
                    app.lowStopBand = 5000;

                    % Create filter (low-pass)
                    app.filter = designfilt('lowpassfir', ...
                                            PassbandFrequency = app.lowPassBand, ...
                                            StopbandFrequency = app.lowStopBand, ...
                                            SampleRate = app.fsCurrent);
                case 'High-pass'
                    app.firstTimeCustom = true;
                    
                    app.highStopBand = 3000;
                    app.highPassBand = 5000;

                    app.filter = designfilt('highpassfir', ...
                                            StopbandFrequency = app.highStopBand, ...
                                            PassbandFrequency = app.highPassBand, ...
                                            SampleRate = app.fsCurrent);
                case 'Band-pass'
                    app.firstTimeCustom = true;
                    
                    app.bpStopBand1 = 500;
                    app.bpPassBand1 = 1000;
                    app.bpPassBand2 = 5000;
                    app.bpStopBand2 = 6000;

                    app.filter = designfilt('bandpassfir', ...
                                            StopbandFrequency1 = app.bpStopBand1, ...
                                            PassbandFrequency1 = app.bpPassBand1, ...
                                            PassbandFrequency2 = app.bpPassBand2, ...
                                            StopbandFrequency2 = app.bpStopBand2, ...
                                            SampleRate = app.fsCurrent);
                case 'Band-stop'
                    app.firstTimeCustom = true;

                    app.bsPassBand1 = 500;
                    app.bsStopBand1 = 1000;
                    app.bsStopBand2 = 5000;
                    app.bsPassBand2 = 6000;

                    app.filter = designfilt('bandstopfir', ...
                                            PassbandFrequency1 = app.bsPassBand1, ...
                                            StopbandFrequency1 = app.bsStopBand1, ...
                                            StopbandFrequency2 = app.bsStopBand2, ...
                                            PassbandFrequency2 = app.bsPassBand2, ...
                                            SampleRate = app.fsCurrent);
                case 'Box'
                    app.firstTimeCustom = true;
                    app.w = 12;
                case 'Gaussian'
                    app.w = 12;
                    app.sigma = app.w / 6;
                    app.filter = fspecial('gaussian', [1, app.w], app.sigma);
                case 'Custom'
                    % It's first time -> show info alert
                    if app.firstTimeCustom
                        uialert(app.UIFigure, '請選擇濾波器種類和參數', 'Customize filter', 'Icon', 'info');
                        app.firstTimeCustom = false;
                    end
                    % Create custom filter
                    app.Create_custom_filter();
            end
        end


        % Create custom filter (from user's choice)
        function Create_custom_filter(app)
            switch app.CustomFilterDropDown.Value
                case 'Low-pass'
                    % Check input
                    app.Check_input();
                    
                    % Get type of filter and input parameter from user
                    customFilter = 'lowpassfir';
                    app.lowStopBand = app.StopbandFrequencyEditField.Value;
                    app.lowPassBand = app.PassbandFrequencyEditField.Value;

                    % Create custom filter
                    app.filter = designfilt(customFilter, ...
                                            StopbandFrequency = app.lowStopBand, ...
                                            PassbandFrequency = app.lowPassBand, ...
                                            SampleRate = app.fsCurrent);
                case 'High-pass'
                    app.Check_input();
                                        
                    customFilter = 'highpassfir';
                    app.highStopBand = app.StopbandFrequencyEditField.Value;
                    app.highPassBand = app.PassbandFrequencyEditField.Value;
                    
                    app.filter = designfilt(customFilter, ...
                                            StopbandFrequency = app.highStopBand, ...
                                            PassbandFrequency = app.highPassBand, ...
                                            SampleRate = app.fsCurrent);
                case 'Band-pass'
                    app.Check_input();
                    
                    customFilter = 'bandpassfir';
                    app.bpStopBand1 = app.StopbandFrequencyEditField.Value;
                    app.bpPassBand1 = app.PassbandFrequencyEditField.Value;
                    app.bpPassBand2 = app.PassbandFrequency2EditField.Value;
                    app.bpStopBand2 = app.StopbandFrequency2EditField.Value;
                    
                    app.filter = designfilt(customFilter, ...
                                            PassbandFrequency1 = app.bpPassBand1, ...
                                            StopbandFrequency1 = app.bpStopBand1, ...
                                            StopbandFrequency2 = app.bpStopBand2, ...
                                            PassbandFrequency2 = app.bpPassBand2, ...
                                            SampleRate = app.fsCurrent);
                case 'Band-stop'
                    app.Check_input();
                    
                    customFilter = 'bandstopfir';
                    app.bsPassBand1 = app.PassbandFrequencyEditField.Value;
                    app.bsStopBand1 = app.StopbandFrequencyEditField.Value;
                    app.bsStopBand2 = app.StopbandFrequency2EditField.Value;
                    app.bsPassBand2 = app.PassbandFrequency2EditField.Value;
                   
                    app.filter = designfilt(customFilter, ...
                                            PassbandFrequency1 = app.bsPassBand1, ...
                                            StopbandFrequency1 = app.bsStopBand1, ...
                                            StopbandFrequency2 = app.bsStopBand2, ...
                                            PassbandFrequency2 = app.bsPassBand2, ...
                                            SampleRate = app.fsCurrent);
                case 'Box'
                    app.w = app.PassbandFrequencyEditField.Value;
                case 'Gaussian'
                    app.sigma = app.PassbandFrequencyEditField.Value;
                    app.filter = fspecial('gaussian', [1, app.w], app.sigma);
            end
        end
        

        % Check input of custom filter
        function Check_input(app)
            switch app.CustomFilterDropDown.Value
                case 'Low-pass'
                    % Correct: PassBand < StopBand
                    if app.StopbandFrequencyEditField.Value <= app.PassbandFrequencyEditField.Value
                        app.StopbandFrequencyEditField.Value = app.PassbandFrequencyEditField.Value + 1000;
                        uialert(app.UIFigure, '輸入值大小順序錯誤，已自動調整', 'Warning', 'Icon', 'warning');
                    end
                case 'High-pass'
                    % Correct: PassBand > StopBand
                    if app.StopbandFrequencyEditField.Value >= app.PassbandFrequencyEditField.Value
                        app.PassbandFrequencyEditField.Value = app.StopbandFrequencyEditField.Value + 1000;
                        uialert(app.UIFigure, '輸入值大小順序錯誤，已自動調整', 'Warning', 'Icon', 'warning');
                    end
                case 'Band-pass'
                    % Correct: StopBand1 < PassBand1 < PassBand2 < StopBand2
                    if ~(app.StopbandFrequencyEditField.Value < app.PassbandFrequencyEditField.Value && ...
                         app.PassbandFrequencyEditField.Value < app.PassbandFrequency2EditField.Value && ...
                         app.PassbandFrequency2EditField.Value < app.StopbandFrequency2EditField.Value)
                        
                        sorted = sort([app.StopbandFrequencyEditField.Value, ...
                                       app.PassbandFrequencyEditField.Value, ...
                                       app.PassbandFrequency2EditField.Value, ...
                                       app.StopbandFrequency2EditField.Value]);
                        
                        [app.StopbandFrequencyEditField.Value, ...
                         app.PassbandFrequencyEditField.Value, ...
                         app.PassbandFrequency2EditField.Value, ...
                         app.StopbandFrequency2EditField.Value] = deal(sorted(1), sorted(2), sorted(3), sorted(4));
                        
                        uialert(app.UIFigure, '輸入值大小順序錯誤，已自動排序', 'Warning', 'Icon', 'warning');
                    end

                    % Check the width of transition
                    if app.PassbandFrequencyEditField.Value - app.StopbandFrequencyEditField.Value < app.minTransition
                        app.PassbandFrequencyEditField.Value = app.StopbandFrequencyEditField.Value + app.minTransition;
                        uialert(app.UIFigure, 'Passband1與Stopband1間距過小，已自動調整', 'Warning', 'Icon', 'warning');
                    end
                    if app.StopbandFrequency2EditField.Value - app.PassbandFrequency2EditField.Value < app.minTransition
                        app.StopbandFrequency2EditField.Value = app.PassbandFrequency2EditField.Value + app.minTransition;
                        uialert(app.UIFigure, 'Stopband2與Passband2間距過小，已自動調整', 'Warning', 'Icon', 'warning');
                    end

                    % Check the width of PassBand
                    if app.PassbandFrequency2EditField.Value - app.PassbandFrequencyEditField.Value < app.minPassBandWidth
                        app.PassbandFrequency2EditField.Value = app.PassbandFrequencyEditField.Value + app.minPassBandWidth;
                        % Can not bigger than StopBand2 (after auto fix)
                        if app.PassbandFrequency2EditField.Value >= app.StopbandFrequency2EditField.Value
                            app.StopbandFrequency2EditField.Value = app.PassbandFrequency2EditField.Value + app.minTransition;
                        end
                        uialert(app.UIFigure, '通帶寬度不足，已自動調整', 'Warning', 'Icon', 'warning');
                    end
                case 'Band-stop'
                    % Correct: PassBand1 < StopBand1 < StopBand2 < PassBand2
                    if ~(app.PassbandFrequencyEditField.Value < app.StopbandFrequencyEditField.Value && ...
                         app.StopbandFrequencyEditField.Value < app.StopbandFrequency2EditField.Value && ...
                         app.StopbandFrequency2EditField.Value < app.PassbandFrequency2EditField.Value)

                        sorted = sort([app.PassbandFrequencyEditField.Value, ...
                                       app.StopbandFrequencyEditField.Value, ...
                                       app.StopbandFrequency2EditField.Value, ...
                                       app.PassbandFrequency2EditField.Value]);

                        [app.PassbandFrequencyEditField.Value, ...
                         app.StopbandFrequencyEditField.Value, ...
                         app.StopbandFrequency2EditField.Value, ...
                         app.PassbandFrequency2EditField.Value] = deal(sorted(1), sorted(2), sorted(3), sorted(4));

                        uialert(app.UIFigure, '輸入值大小順序錯誤，已自動排序', 'Warning', 'Icon', 'warning');
                    end

                    % Check the width of transition
                    if app.StopbandFrequencyEditField.Value - app.PassbandFrequencyEditField.Value < app.minTransition
                        app.StopbandFrequencyEditField.Value = app.PassbandFrequencyEditField.Value + app.minTransition;
                        uialert(app.UIFigure, 'Stopband1與Passband1間距過小，已自動調整', 'Warning', 'Icon', 'warning');
                    end
                    if app.PassbandFrequency2EditField.Value - app.StopbandFrequency2EditField.Value < app.minTransition
                        app.PassbandFrequency2EditField.Value = app.StopbandFrequency2EditField.Value + app.minTransition;
                        uialert(app.UIFigure, 'Passband2與Stopband2間距過小，已自動調整', 'Warning', 'Icon', 'warning');
                    end

                    % Check the width of StopBand
                    if app.StopbandFrequency2EditField.Value - app.StopbandFrequencyEditField.Value < app.minStopBandWidth
                        app.StopbandFrequency2EditField.Value = app.StopbandFrequencyEditField.Value + app.minStopBandWidth;
                        % Can not bigger than PassBand2 (after auto fix)
                        if app.StopbandFrequency2EditField.Value >= app.PassbandFrequency2EditField.Value
                            app.PassbandFrequency2EditField.Value = app.StopbandFrequency2EditField.Value + app.minTransition;
                        end
                        uialert(app.UIFigure, 'Stopband 寬度不足，已自動調整', 'Warning', 'Icon', 'warning');
                    end
            end
        end
        

        % Update title of plot
        function Update_title(app)
            % Get manipulated information
            graph = app.GraphButtonGroup.SelectedObject.Text;
            
            if app.VolumeSlider.Value == 1
                volume = "";
            else
                volume = "| Vol: " + num2str(app.VolumeSlider.Value) + "x";
            end

            if app.SpeedSlider.Value == 1
                speed = "";
            else
                speed = "| Spd: " + num2str(app.SpeedSlider.Value) + "x";
            end

            filterStr = "| Filter: [ " + app.FiltersFIRDropDown.Value + " ]";

            % Combine them into a string (title)
            title = sprintf("[ %s ] – [ %s ] %s %s %s", app.fileName, graph, volume, speed, filterStr);
    
            app.UIAxes.Title.Interpreter = "none";
            app.UIAxes.Title.String = title;
        end
        

        % Change to dark mode or light mode
        function Change_theme(app)
            isDark = strcmp(app.DarkmodeSwitch.Value, 'On');
    
            % Set color
            if isDark % Dark mode
                bgColor = [0.15 0.15 0.15];     % Background
                fgColor = [1 1 1];              % Foreground (text)
                gridColor = [0.7 0.7 0.7];      % Grid
                app.lineColor1 = [0 1 1];       % Waveform
                app.lineColor2 = [0.5 0.7 1];   % Spectrum
                app.progressColor = [0.16, 1, 0.16];    % Playing progress line
                figureColor = [0.3 0.3 0.3];    % Figure background    
                btnColor = [0.51 0.51 0.51];    % Button background
            else % light mode
                bgColor = [1 1 1];           
                fgColor = [0 0 0];           
                gridColor = [0.6 0.6 0.6];   
                app.lineColor1 = [0.01 0.4 0.7];
                app.lineColor2 = [0.5 0.2 0.6];
                app.progressColor = [0, 0.7, 0];
                figureColor = [0.94,0.94,0.94];
                btnColor = [0.49 0.49 0.49];
            end

            % Reset-plot the graph
            app.Plot_graph();

            % Apply color to widgets
            % Background
            app.UIFigure.Color = figureColor;
            
            % UIAxes
            app.UIAxes.Color = bgColor;
            app.UIAxes.XColor = fgColor;
            app.UIAxes.YColor = fgColor;
            app.UIAxes.GridColor = gridColor;
            app.UIAxes.Title.Color = fgColor;
            app.UIAxes.XLabel.Color = fgColor;
            app.UIAxes.YLabel.Color = fgColor;
            
            % Graph radio button group
            app.GraphButtonGroup.ForegroundColor = fgColor;
            app.GraphButtonGroup.BackgroundColor = figureColor;
            app.GraphButtonGroup.BorderColor = btnColor;
            app.WaveformButton.FontColor = fgColor;
            app.SpectrumButton.FontColor = fgColor;
            app.SpectrogramButton.FontColor = fgColor;

            % Filter drop down
            app.FiltersFIRDropDown.FontColor = fgColor;
            app.FiltersFIRDropDown.BackgroundColor = figureColor;
            app.Label.FontColor = fgColor;
            app.Label.BackgroundColor = figureColor;
            
            % Custom filter drop down
            app.CustomFilterDropDown.FontColor = fgColor;
            app.CustomFilterDropDown.BackgroundColor = figureColor;
            app.CustomFilterDropDownLabel.FontColor = fgColor;
            app.CustomFilterDropDownLabel.BackgroundColor = figureColor;

            % Apply button
            app.ApplyButton.FontColor = fgColor;
            app.ApplyButton.BackgroundColor = figureColor;

            % Volume slider
            app.VolumeSlider.FontColor = fgColor;
            app.VolumeSlider_2Label.FontColor = fgColor;
            app.VolumeSlider_2Label.BackgroundColor = figureColor;

            % Speed slider
            app.SpeedSlider.FontColor = fgColor;
            app.SpeedSliderLabel.FontColor = fgColor;
            app.SpeedSliderLabel.BackgroundColor = figureColor;

            % Audio information display edit fields
            app.MaxAmplitudeEditField.FontColor = fgColor;
            app.MaxAmplitudeEditField.BackgroundColor = figureColor;
            app.MaxAmplitudeEditFieldLabel.FontColor = fgColor;
            app.MaxAmplitudeEditFieldLabel.BackgroundColor = figureColor;

            app.SampleRateEditField.FontColor = fgColor;
            app.SampleRateEditField.BackgroundColor = figureColor;
            app.SampleRateLabel.FontColor = fgColor;
            app.SampleRateLabel.BackgroundColor = figureColor;

            app.TimesEditField.FontColor = fgColor;
            app.TimesEditField.BackgroundColor = figureColor;
            app.TimesEditFieldLabel.FontColor = fgColor;
            app.TimesEditFieldLabel.BackgroundColor = figureColor;

            % Playing statement
            app.Label_5.FontColor = fgColor;
            app.Label_5.BackgroundColor = figureColor;
            
            % Buttons
            app.PlayButton.FontColor = fgColor;
            app.PlayButton.BackgroundColor = figureColor;

            app.LoadButton.FontColor = fgColor;
            app.LoadButton.BackgroundColor = figureColor;

            app.RecordButton.FontColor = fgColor;
            app.RecordButton.BackgroundColor = figureColor;

            app.SaveButton.FontColor = fgColor;
            app.SaveButton.BackgroundColor = figureColor;

            % Filter information display edit fields
            % Passband1
            app.PassbandFrequencyEditField.FontColor = fgColor;
            app.PassbandFrequencyEditField.BackgroundColor = figureColor;
            app.PassbandFrequencyLabel.FontColor = fgColor;
            app.PassbandFrequencyLabel.BackgroundColor = figureColor;

            % Passband2
            app.PassbandFrequency2EditField.FontColor = fgColor;
            app.PassbandFrequency2EditField.BackgroundColor = figureColor;
            app.PassbandFrequency2Label.FontColor = fgColor;
            app.PassbandFrequency2Label.BackgroundColor = figureColor;

            % Stopband1
            app.StopbandFrequencyEditField.FontColor = fgColor;
            app.StopbandFrequencyEditField.BackgroundColor = figureColor;
            app.StopbandFrequencyLabel.FontColor = fgColor;
            app.StopbandFrequencyLabel.BackgroundColor = figureColor;

            % Stopband2
            app.StopbandFrequency2EditField.FontColor = fgColor;
            app.StopbandFrequency2EditField.BackgroundColor = figureColor;
            app.StopbandFrequency2Label.FontColor = fgColor;
            app.StopbandFrequency2Label.BackgroundColor = figureColor;

            % Light switch
            app.DarkmodeSwitch.FontColor = fgColor;
            app.DarkmodeSwitchLabel.FontColor = fgColor;
            app.DarkmodeSwitchLabel.BackgroundColor = figureColor;
        end


        % Show playing progress line
        function Update_playing_progress(app)
            % fprintf("current time: " + app.currentTime + "\n");
            
            % Manually adjust the time error
            app.currentTime = app.currentTime + 0.05;
            app.progressLine.Value = app.currentTime;

            % Play to the end
            if app.currentTime >= app.duration
                app.Stop_playing_audio();
            end
        end
        
        % Stop playing audio
        function Stop_playing_audio(app)
            % Stop player and timer
            if app.playStatement
                stop(app.player);
                if app.WaveformButton.Value
                    stop(app.playingTimer);
                    delete(app.playingTimer);
                end
            end

            % Reset ui and plot
            app.PlayButton.Text = 'Play';
            app.PlaystatementLamp.Color = 'red';
            app.playStatement = false;
            app.Plot_graph();
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Initialize the theme
            app.Change_theme();

            % Starting info
            uialert(app.UIFigure, '請先讀取或錄製音訊資料', 'Welcome', 'Icon', 'info');
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            % Select audio file (.wav)
            [fileNameToRead, filePath] = uigetfile({'*.wav', 'wav file (*.wav)'}, 'Selecting file');
            
            if isequal(fileNameToRead, 0) % Cancel
                return;
            else
                % Success loading file
                uialert(app.UIFigure, '讀取成功！', 'Success', 'Icon', 'success');
                
                % Load the audio file
                fullPath = [filePath, fileNameToRead];
                [app.yOriginal, app.fsOriginal] = audioread(fullPath);
                app.yCurrent = app.yOriginal;
                app.fsCurrent = app.fsOriginal;

                % Get information
                app.fileName = erase(fileNameToRead, '.wav');
                audioInfo = audioinfo(fullPath);
                app.channel = audioInfo.NumChannels;
                app.duration = audioInfo.Duration;
                app.maxAmp = max(abs(app.yCurrent), [], 'all');

                % Reset ui
                app.Reset_UI();

                % Show information
                app.Show_info();

                % Plot graph
                app.Plot_graph();
                app.Update_title();
            end
        end

        % Selection changed function: GraphButtonGroup
        function GraphButtonGroupSelectionChanged(app, event)
            % Cannot used before the file is loaded
            if ~app.Nload_first_data()
                app.GraphButtonGroup.SelectedObject = app.WaveformButton;
                return;
            end

            % Stop playing
            app.Stop_playing_audio();
            
            % Re-plot graph
            app.Plot_graph();
            app.Update_title();
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            if ~app.Nload_first_data()
                return;
            end
            
            if ~app.playStatement % Want to play
                app.playStatement = true;

                % Prepare to create audio player
                app.PlayButton.Text = 'Preparing...';
                app.PlayButton.Enable = "off";
                app.player = audioplayer(app.yCurrent, app.fsCurrent);

                % If using waveform (need to show playing progress)
                if app.playStatement && app.WaveformButton.Value
                    % Set up timer
                    app.playingTimer = timer;
                    app.playingTimer.Period = 0.05;
                    app.playingTimer.ExecutionMode = 'fixedSpacing';
                    app.playingTimer.TimerFcn = @(~,~) app.Update_playing_progress();

                    % Initialize playing progress line
                    app.progressLine = xline(app.UIAxes, 0, 'Color', app.progressColor, ...
                                                            'LineWidth', 2);
                    app.currentTime = 0;
                end
                
                play(app.player);

                % Change text of button and status of lamp
                app.PlayButton.Text = 'Stop';
                app.PlayButton.Enable = "on";
                app.PlaystatementLamp.Color = 'green';
                
                % Start timer
                if app.playStatement && app.WaveformButton.Value
                    start(app.playingTimer);
                end
            else % Want to stop
                app.playStatement = false;

                % Stop player and timer
                stop(app.player);
                if app.playStatement && app.WaveformButton.Value
                    stop(app.playingTimer);
                    delete(app.playingTimer);
                end
                
                % Change text of button and status of lamp
                app.PlayButton.Text = 'Play';
                app.PlaystatementLamp.Color = 'red';
            end

        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % Stop playing
            app.Stop_playing_audio();
        
            % Close app
            delete(app.UIFigure);
        end

        % Value changed function: VolumeSlider
        function VolumeSliderValueChanged(app, event)
            if ~app.Nload_first_data()
                app.VolumeSlider.Value = 1;
                return;
            end
            
            app.Update_audio();

            app.Show_info();
            app.Plot_graph();
            app.Update_title();
        end

        % Value changed function: SpeedSlider
        function SpeedSliderValueChanged(app, event)
            if ~app.Nload_first_data()
                app.SpeedSlider.Value = 1;
                return;
            end

            % Sample rate can not be 0
            if app.SpeedSlider.Value <= 0
                app.SpeedSlider.Value = 0.1;
            end
            
            app.Update_audio();

            app.Show_info();
            app.Plot_graph();
            app.Update_title();
        end

        % Button pushed function: RecordButton
        function RecordButtonPushed(app, event)
            if ~app.recordStatement % Want to record
                % Default record parameters
                fs = 44100;
                bits = 16;
                channels = 1;
                
                % Start to record
                uialert(app.UIFigure, '開始錄音...', 'Recording', 'Icon', 'info');
                app.recorder = audiorecorder(fs, bits, channels);
                record(app.recorder);

                app.recordStatement = true;
                app.RecordButton.Text = 'Stop';
            else % Want to stop
                % Stop recording
                stop(app.recorder);
                uialert(app.UIFigure, '錄製成功！', 'Success', 'Icon', 'success');
                
                % Save the result
                yRecorded = getaudiodata(app.recorder);
                app.yOriginal = yRecorded;
                app.yCurrent = app.yOriginal;
                app.fsOriginal = app.recorder.SampleRate;
                app.fsCurrent = app.fsOriginal;

                % Get information
                app.duration = length(app.yOriginal) / app.fsOriginal;
                app.channel = app.recorder.NumChannels;
                app.maxAmp = max(abs(app.yCurrent), [], 'all');
                app.fileName = "User Recorded";
                
                % Reset status
                app.recordStatement = false;
                app.RecordButton.Text = 'Record';

                % Plot initialize graph
                app.Reset_UI();

                app.Show_info();
                app.Plot_graph();
                app.Update_title();
            end
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            if ~app.Nload_first_data()
                return;
            end

            % Choose saving path
            [saveFileName, filePath] = uiputfile('*.wav', '儲存音訊檔案');
            
            % Save the audio file
            if isequal(saveFileName, 0)
                return;
            else
                fullPath = fullfile(filePath, saveFileName);
                audiowrite(fullPath, app.yCurrent, round(app.fsCurrent));

                uialert(app.UIFigure, '儲存成功！', 'Success', 'Icon', 'success');
            end
        end

        % Value changed function: FiltersFIRDropDown
        function FiltersFIRDropDownValueChanged(app, event)
            if ~app.Nload_first_data()
                app.FiltersFIRDropDown.Value = 'None';
                return;
            end
            
            % Initialize the value inside edit field when switch to custom filter
            if isequal(app.FiltersFIRDropDown.Value, 'Custom')
                app.Show_info();
                app.PassbandFrequencyEditField.Value = 3000;
                app.StopbandFrequencyEditField.Value = 5000;
                app.PassbandFrequency2EditField.Value = 6000;
                app.StopbandFrequency2EditField.Value = 8000;
            end

            app.Update_audio();

            app.Show_info();
            app.Plot_graph();
            app.Update_title();
        end

        % Button pushed function: ApplyButton
        function ApplyButtonPushed(app, event)
            % Apply custom filter
            app.Update_audio();

            app.Show_info();
            app.Plot_graph();
            app.Update_title();
        end

        % Value changed function: CustomFilterDropDown
        function CustomFilterDropDownValueChanged(app, event)
            % Determine whether to display the two edit fields below based on the selected filter
            app.Show_info();
        end

        % Value changed function: DarkmodeSwitch
        function DarkmodeSwitchValueChanged(app, event)
            % Change theme
            app.Change_theme();           
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [500 500 696 584];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Waveform')
            xlabel(app.UIAxes, 'Time (s)')
            ylabel(app.UIAxes, 'Amplitude')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [25 292 632 271];

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [191 258 68 22];
            app.Label.Text = 'Filters (FIR)';

            % Create FiltersFIRDropDown
            app.FiltersFIRDropDown = uidropdown(app.UIFigure);
            app.FiltersFIRDropDown.Items = {'None', 'Low-pass', 'High-pass', 'Band-pass', 'Band-stop', 'Box', 'Gaussian', 'Custom'};
            app.FiltersFIRDropDown.ValueChangedFcn = createCallbackFcn(app, @FiltersFIRDropDownValueChanged, true);
            app.FiltersFIRDropDown.Position = [278 258 147 22];
            app.FiltersFIRDropDown.Value = 'None';

            % Create GraphButtonGroup
            app.GraphButtonGroup = uibuttongroup(app.UIFigure);
            app.GraphButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @GraphButtonGroupSelectionChanged, true);
            app.GraphButtonGroup.Title = 'Graph';
            app.GraphButtonGroup.Position = [63 194 106 96];

            % Create WaveformButton
            app.WaveformButton = uiradiobutton(app.GraphButtonGroup);
            app.WaveformButton.Text = 'Waveform';
            app.WaveformButton.Position = [11 50 76 22];
            app.WaveformButton.Value = true;

            % Create SpectrumButton
            app.SpectrumButton = uiradiobutton(app.GraphButtonGroup);
            app.SpectrumButton.Text = 'Spectrum';
            app.SpectrumButton.Position = [11 28 73 22];

            % Create SpectrogramButton
            app.SpectrogramButton = uiradiobutton(app.GraphButtonGroup);
            app.SpectrogramButton.Text = 'Spectrogram';
            app.SpectrogramButton.Position = [11 6 91 22];

            % Create Label_5
            app.Label_5 = uilabel(app.UIFigure);
            app.Label_5.HorizontalAlignment = 'right';
            app.Label_5.Position = [48 109 84 22];
            app.Label_5.Text = 'Play statement';

            % Create PlaystatementLamp
            app.PlaystatementLamp = uilamp(app.UIFigure);
            app.PlaystatementLamp.Position = [147 109 20 20];
            app.PlaystatementLamp.Color = [1 0 0];

            % Create PlayButton
            app.PlayButton = uibutton(app.UIFigure, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.Position = [188 108 100 23];
            app.PlayButton.Text = 'Play';

            % Create SaveButton
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [549 108 100 23];
            app.SaveButton.Text = 'Save';

            % Create LoadButton
            app.LoadButton = uibutton(app.UIFigure, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [309 108 100 23];
            app.LoadButton.Text = 'Load';

            % Create VolumeSlider_2Label
            app.VolumeSlider_2Label = uilabel(app.UIFigure);
            app.VolumeSlider_2Label.HorizontalAlignment = 'right';
            app.VolumeSlider_2Label.Position = [435 268 45 22];
            app.VolumeSlider_2Label.Text = 'Volume';

            % Create VolumeSlider
            app.VolumeSlider = uislider(app.UIFigure);
            app.VolumeSlider.Limits = [0 5];
            app.VolumeSlider.MajorTicks = [0 1 2 3 4 5];
            app.VolumeSlider.ValueChangedFcn = createCallbackFcn(app, @VolumeSliderValueChanged, true);
            app.VolumeSlider.Position = [501 277 145 3];
            app.VolumeSlider.Value = 1;

            % Create SpeedSliderLabel
            app.SpeedSliderLabel = uilabel(app.UIFigure);
            app.SpeedSliderLabel.HorizontalAlignment = 'right';
            app.SpeedSliderLabel.Position = [435 219 40 22];
            app.SpeedSliderLabel.Text = 'Speed';

            % Create SpeedSlider
            app.SpeedSlider = uislider(app.UIFigure);
            app.SpeedSlider.Limits = [0 5];
            app.SpeedSlider.ValueChangedFcn = createCallbackFcn(app, @SpeedSliderValueChanged, true);
            app.SpeedSlider.Position = [496 228 150 3];
            app.SpeedSlider.Value = 1;

            % Create RecordButton
            app.RecordButton = uibutton(app.UIFigure, 'push');
            app.RecordButton.ButtonPushedFcn = createCallbackFcn(app, @RecordButtonPushed, true);
            app.RecordButton.Position = [432 108 100 23];
            app.RecordButton.Text = 'Record';

            % Create PassbandFrequencyLabel
            app.PassbandFrequencyLabel = uilabel(app.UIFigure);
            app.PassbandFrequencyLabel.HorizontalAlignment = 'right';
            app.PassbandFrequencyLabel.Visible = 'off';
            app.PassbandFrequencyLabel.Position = [45 63 118 22];
            app.PassbandFrequencyLabel.Text = 'Passband Frequency';

            % Create PassbandFrequencyEditField
            app.PassbandFrequencyEditField = uieditfield(app.UIFigure, 'numeric');
            app.PassbandFrequencyEditField.Editable = 'off';
            app.PassbandFrequencyEditField.Visible = 'off';
            app.PassbandFrequencyEditField.Position = [185 63 81 22];
            app.PassbandFrequencyEditField.Value = 3000;

            % Create StopbandFrequencyLabel
            app.StopbandFrequencyLabel = uilabel(app.UIFigure);
            app.StopbandFrequencyLabel.HorizontalAlignment = 'right';
            app.StopbandFrequencyLabel.Visible = 'off';
            app.StopbandFrequencyLabel.Position = [430 63 116 22];
            app.StopbandFrequencyLabel.Text = 'Stopband Frequency';

            % Create StopbandFrequencyEditField
            app.StopbandFrequencyEditField = uieditfield(app.UIFigure, 'numeric');
            app.StopbandFrequencyEditField.Editable = 'off';
            app.StopbandFrequencyEditField.Visible = 'off';
            app.StopbandFrequencyEditField.Position = [568 63 81 22];
            app.StopbandFrequencyEditField.Value = 5000;

            % Create PassbandFrequency2Label
            app.PassbandFrequency2Label = uilabel(app.UIFigure);
            app.PassbandFrequency2Label.HorizontalAlignment = 'right';
            app.PassbandFrequency2Label.Visible = 'off';
            app.PassbandFrequency2Label.Position = [45 21 125 22];
            app.PassbandFrequency2Label.Text = 'Passband Frequency2';

            % Create PassbandFrequency2EditField
            app.PassbandFrequency2EditField = uieditfield(app.UIFigure, 'numeric');
            app.PassbandFrequency2EditField.Editable = 'off';
            app.PassbandFrequency2EditField.Visible = 'off';
            app.PassbandFrequency2EditField.Position = [185 21 81 22];
            app.PassbandFrequency2EditField.Value = 6000;

            % Create StopbandFrequency2Label
            app.StopbandFrequency2Label = uilabel(app.UIFigure);
            app.StopbandFrequency2Label.HorizontalAlignment = 'right';
            app.StopbandFrequency2Label.Visible = 'off';
            app.StopbandFrequency2Label.Position = [430 21 123 22];
            app.StopbandFrequency2Label.Text = 'Stopband Frequency2';

            % Create StopbandFrequency2EditField
            app.StopbandFrequency2EditField = uieditfield(app.UIFigure, 'numeric');
            app.StopbandFrequency2EditField.Editable = 'off';
            app.StopbandFrequency2EditField.Visible = 'off';
            app.StopbandFrequency2EditField.Position = [568 21 81 22];
            app.StopbandFrequency2EditField.Value = 8000;

            % Create SampleRateLabel
            app.SampleRateLabel = uilabel(app.UIFigure);
            app.SampleRateLabel.HorizontalAlignment = 'right';
            app.SampleRateLabel.Position = [252 154 74 22];
            app.SampleRateLabel.Text = 'Sample Rate';

            % Create SampleRateEditField
            app.SampleRateEditField = uieditfield(app.UIFigure, 'numeric');
            app.SampleRateEditField.Editable = 'off';
            app.SampleRateEditField.Position = [376 154 134 22];

            % Create MaxAmplitudeEditFieldLabel
            app.MaxAmplitudeEditFieldLabel = uilabel(app.UIFigure);
            app.MaxAmplitudeEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxAmplitudeEditFieldLabel.Position = [48 154 84 22];
            app.MaxAmplitudeEditFieldLabel.Text = 'Max Amplitude';

            % Create MaxAmplitudeEditField
            app.MaxAmplitudeEditField = uieditfield(app.UIFigure, 'numeric');
            app.MaxAmplitudeEditField.Editable = 'off';
            app.MaxAmplitudeEditField.Position = [169 154 67 22];

            % Create TimesEditFieldLabel
            app.TimesEditFieldLabel = uilabel(app.UIFigure);
            app.TimesEditFieldLabel.HorizontalAlignment = 'right';
            app.TimesEditFieldLabel.Position = [531 154 37 22];
            app.TimesEditFieldLabel.Text = 'Times';

            % Create TimesEditField
            app.TimesEditField = uieditfield(app.UIFigure, 'numeric');
            app.TimesEditField.Editable = 'off';
            app.TimesEditField.Position = [591 154 55 22];

            % Create CustomFilterDropDownLabel
            app.CustomFilterDropDownLabel = uilabel(app.UIFigure);
            app.CustomFilterDropDownLabel.HorizontalAlignment = 'right';
            app.CustomFilterDropDownLabel.Visible = 'off';
            app.CustomFilterDropDownLabel.Position = [187 219 76 22];
            app.CustomFilterDropDownLabel.Text = 'Custom Filter';

            % Create CustomFilterDropDown
            app.CustomFilterDropDown = uidropdown(app.UIFigure);
            app.CustomFilterDropDown.Items = {'Low-pass', 'High-pass', 'Band-pass', 'Band-stop', 'Box', 'Gaussian'};
            app.CustomFilterDropDown.ValueChangedFcn = createCallbackFcn(app, @CustomFilterDropDownValueChanged, true);
            app.CustomFilterDropDown.Visible = 'off';
            app.CustomFilterDropDown.Position = [278 219 147 22];
            app.CustomFilterDropDown.Value = 'Low-pass';

            % Create ApplyButton
            app.ApplyButton = uibutton(app.UIFigure, 'push');
            app.ApplyButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyButtonPushed, true);
            app.ApplyButton.Visible = 'off';
            app.ApplyButton.Position = [278 185 147 23];
            app.ApplyButton.Text = 'Apply';

            % Create DarkmodeSwitchLabel
            app.DarkmodeSwitchLabel = uilabel(app.UIFigure);
            app.DarkmodeSwitchLabel.HorizontalAlignment = 'center';
            app.DarkmodeSwitchLabel.Position = [327 28 64 22];
            app.DarkmodeSwitchLabel.Text = 'Dark mode';

            % Create DarkmodeSwitch
            app.DarkmodeSwitch = uiswitch(app.UIFigure, 'slider');
            app.DarkmodeSwitch.ValueChangedFcn = createCallbackFcn(app, @DarkmodeSwitchValueChanged, true);
            app.DarkmodeSwitch.Position = [336 65 45 20];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Audio_analysis_tool

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
