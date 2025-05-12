classdef Audio_filter_v2 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        RecordButton         matlab.ui.control.Button
        SpeedSlider          matlab.ui.control.Slider
        SpeedSliderLabel     matlab.ui.control.Label
        VolumeSlider         matlab.ui.control.Slider
        VolumeSlider_2Label  matlab.ui.control.Label
        LoadButton           matlab.ui.control.Button
        SaveButton           matlab.ui.control.Button
        PlayButton           matlab.ui.control.Button
        PlaystatementLamp    matlab.ui.control.Lamp
        Label_5              matlab.ui.control.Label
        GraphButtonGroup     matlab.ui.container.ButtonGroup
        SpectrogramButton    matlab.ui.control.RadioButton
        SpectrumButton       matlab.ui.control.RadioButton
        WaveformButton       matlab.ui.control.RadioButton
        FiltersFIRDropDown   matlab.ui.control.DropDown
        Label                matlab.ui.control.Label
        UIAxes               matlab.ui.control.UIAxes
    end


    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end

    
    properties (Access = private)
        yOriginal        double             % 原始音訊
        yCurrent         double             % 修改後的音訊
        fsOriginal       double             % 原始採樣率
        fsCurrent        double             % 修改後的採樣率
        duration         double             % 總時長
        channel          int32              % 聲道數
        player           audioplayer        % 播放內容
        playStatement    logical = false    % 播放狀態
        recorder         audiorecorder      % 錄製內容
        recordStatement  logical = false    % 錄製狀態
        filter           digitalFilter      % 濾波器種類
    end
    
    methods (Access = private)
        
        % 繪製波形圖
        function Plot_waveform(app)
            % 計算x軸(時間)
            t = (0:length(app.yCurrent) - 1)/app.fsCurrent;
            
            % 繪製圖表
            plot(app.UIAxes, t, app.yCurrent, 'b');
            title(app.UIAxes, 'Waveform');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Amplitude');
        end
        
        % 繪製頻譜圖
        function Plot_spectrum(app)
            % 傅立葉轉換
            temp1 = fft(app.yCurrent);
            len = length(app.yCurrent);
            temp2 = abs(temp1/len); % 標準化
            temp3 = temp2(1:floor(len / 2 + 1)); % FFT對稱，取一半就好
            temp3(2:end-1) = 2 * temp3(2:end-1); % 能量守恆，要把另外一半的能量補回來
            xFreq = app.fsCurrent * (0:floor(len / 2)) / len;
            yMag = temp3;

            % TODO 可能要限制頻譜圖輸出範圍，集中在有意義的資料區間

            % 繪製圖表
            plot(app.UIAxes, xFreq, yMag, 'r');
            title(app.UIAxes, 'Spectrum');
            xlabel(app.UIAxes, 'Frequency (Hz)');
            ylabel(app.UIAxes, 'Amplitude');

            % 設定x軸範圍 
            maxFreq = 20000;
            if app.fsCurrent / 2 < maxFreq
                maxFreq = app.fsCurrent / 2;
            end
            
            xlim(app.UIAxes, [0, maxFreq]); % 人類聽力範圍或Nyquist頻率
        end
        
        % 繪製時頻譜
        function Plot_spectrogram(app)
            % 雙聲道處理，只畫左聲道
            if app.channel > 1
                dataToPlot = app.yCurrent(:,1);
            else
                dataToPlot = app.yCurrent;
            end

            % 計算強度、頻率、時間
            [s, f, t] = spectrogram(dataToPlot, hamming(512), 256, 1024, app.fsCurrent);

            % 繪製圖表
            imagesc(app.UIAxes, t, f, 20 * log10(abs(s)));
            
            title(app.UIAxes, 'Spectrogram');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Frequency (Hz)');
            colorbar(app.UIAxes);

            xlim(app.UIAxes, [0, t(end)]);
            ylim(app.UIAxes, [0, app.fsCurrent / 2]);
        end
        
        % 重製圖表
        function Reset_graph(app)
            % 清除繪製內容
            cla(app.UIAxes);
            
            % 重製座標軸
            app.UIAxes.XScale = 'linear';
            app.UIAxes.YScale = 'linear';
            axis(app.UIAxes, 'xy');
            app.UIAxes.XLimMode = 'auto'; 
            app.UIAxes.YLimMode = 'auto';
            
            % 刪除colorbar
            cbar = findall(app.UIAxes.Parent, 'Type', 'ColorBar');
            if ~isempty(cbar)
                delete(cbar);
            end
        end
        
        % 根據按鈕繪製圖表
        function Plot_graph(app)
            % reset圖表
            app.Reset_graph();

            % 繪製圖表
            if app.WaveformButton.Value
                app.Plot_waveform();
            elseif app.SpectrumButton.Value
                app.Plot_spectrum();
            else
                app.Plot_spectrogram();
            end
        end
        
        % 創建濾波器
        function Create_filter(app)
            switch app.FiltersFIRDropDown.Value
                case 'Low-pass'
                    app.filter = designfilt('lowpassfir', ...
                                    PassbandFrequency = 3000, ...
                                    StopbandFrequency = 5000, ...
                                    SampleRate = app.fsCurrent);
                case 'High-pass'
                    app.filter = designfilt('highpassfir', ...
                                    StopbandFrequency = 1000, ...
                                    PassbandFrequency = 3000, ...
                                    SampleRate = app.fsCurrent);
                case 'Band-pass'
                    app.filter = designfilt('bandpassfir', ...
                                    StopbandFrequency1 = 500, ...
                                    PassbandFrequency1 = 1000, ...
                                    PassbandFrequency2 = 5000, ...
                                    StopbandFrequency2 = 6000, ...
                                    SampleRate = app.fsCurrent);
                case 'Band-stop'
                    app.filter = designfilt('bandstopfir', ...
                                    PassbandFrequency1 = 500, ...
                                    StopbandFrequency1 = 1000, ...
                                    StopbandFrequency2 = 5000, ...
                                    PassbandFrequency2 = 6000, ...
                                    SampleRate = app.fsCurrent);
            end
        end
        
        % 處理沒有載入資料就碰其他物件的情形
        function permission = Nload_first_data(app)
            if isempty(app.fsCurrent)
                uialert(app.UIFigure, 'Audio not loaded.', 'Warning');
                permission = false;
            else
                permission = true;
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            uialert(app.UIFigure, 'Please load or record audio first.', 'Welcome', 'Icon', 'info');
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            % 選取檔案
            [fileName, filePath] = uigetfile({'*.wav', 'wav音訊檔 (*.wav)'}, '選擇檔案');
                        
            % 讀取檔案
            fullPath = [filePath, fileName];
            [app.yOriginal, app.fsOriginal] = audioread(fullPath);
            app.yCurrent = app.yOriginal;
            app.fsCurrent = app.fsOriginal;

            % 儲存資訊
            audioInfo = audioinfo(fullPath);
            app.channel = audioInfo.NumChannels;
            app.duration = audioInfo.Duration;
            bits = audioInfo.BitsPerSample;

            % 防止音訊太大爆音
            %if max(abs(app.yOriginal)) > 0.9
            %    warning('音訊振幅過大，可能會失真');
            %    app.yOriginal = app.yOriginal * 0.9 / max(abs(app.yOriginal));
            %end
    
            % 顯示資訊
            fprintf(['檔案名稱: %s \n' ...
                     '時間長度: %.2f 秒 \n' ...
                     '採樣率: %.2f 取樣點/秒 \n' ...
                     '解析度 %d 位元/取樣點 \n' ...
                     '聲道數: %d \n'], fileName, app.duration, app.fsCurrent, bits, app.channel);

            % 重製物件
            app.VolumeSlider.Value = 1;
            app.SpeedSlider.Value = 1;

            % 繪製圖形
            app.Plot_graph();
        end

        % Selection changed function: GraphButtonGroup
        function GraphButtonGroupSelectionChanged(app, event)
            % 還沒讀資料不能用
            if ~app.Nload_first_data()
                app.GraphButtonGroup.SelectedObject = app.WaveformButton;
                return;
            end
            
            % 重新繪圖
            app.Plot_graph();
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            % 還沒讀資料不能用
            if ~app.Nload_first_data()
                return;
            end
            
            % 如果想要播放(按按鈕 + 目前沒播)
            if ~app.playStatement
                % 改變按鈕的字(先改，確定不是當機)
                app.PlayButton.Text = 'Stop';

                % 播放音訊
                app.player = audioplayer(app.yCurrent, app.fsCurrent);
                play(app.player);
                
                % 開始播放之後再改Lamp和播放狀態
                app.PlaystatementLamp.Color = 'green';
                app.playStatement = true;
            else
                app.PlayButton.Text = 'Play';
                
                % 停止播放
                stop(app.player);
                
                app.PlaystatementLamp.Color = 'red';
                app.playStatement = false;
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % 如果還播放
            if app.playStatement
                try
                    % 先停止
                    stop(app.player);
                catch
                    
                end
            end
        % 再關畫面
        delete(app.UIFigure);
        end

        % Value changed function: VolumeSlider
        function VolumeSliderValueChanged(app, event)
            % 還沒讀資料不能用
            if ~app.Nload_first_data()
                app.VolumeSlider.Value = 1;
                return;
            end
            
            % 更新震幅和速度
            app.yCurrent = app.yOriginal * app.VolumeSlider.Value;
            app.fsCurrent = app.fsOriginal * app.SpeedSlider.Value;

            % 顯示資訊
            maxAmplitude = max(app.yCurrent);
            app.duration = length(app.yCurrent) / app.fsCurrent;
            
            
            fprintf(['最大振幅: %.2f \n' ...
                     '時間長度: %.2f 秒 \n'], maxAmplitude(1), app.duration);

            % 重新繪圖
            app.Plot_graph();
        end

        % Value changed function: SpeedSlider
        function SpeedSliderValueChanged(app, event)
            % 還沒讀資料不能用
            if ~app.Nload_first_data()
                app.SpeedSlider.Value = 1;
                return;
            end

            % 不能為0
            if app.SpeedSlider.Value <= 0
                app.SpeedSlider.Value = 0.1;
            end
            
            % 更新震幅和速度
            app.yCurrent = app.yOriginal * app.VolumeSlider.Value;
            app.fsCurrent = app.fsOriginal * app.SpeedSlider.Value;
            
            % 顯示資訊
            maxAmplitude = max(app.yCurrent);
            app.duration = length(app.yCurrent) / app.fsCurrent;
            
            fprintf(['最大振幅: %.2f \n' ...
                     '時間長度: %.2f 秒 \n'], maxAmplitude(1), app.duration);

            % 重新繪圖
            app.Plot_graph();
        end

        % Button pushed function: RecordButton
        function RecordButtonPushed(app, event)
            % 如果想要錄音(按按鈕 + 目前沒在錄)
            if ~app.recordStatement
                fs = 44100;
                bits = 16;
                channels = 1;
                
                % 開始錄音
                app.recorder = audiorecorder(fs, bits, channels);
                record(app.recorder);

                app.recordStatement = true;
                app.RecordButton.Text = 'Stop';
            else
                % 停止錄音
                stop(app.recorder);
                
                % 儲存結果
                yRecorded = getaudiodata(app.recorder);
                app.yOriginal = yRecorded;
                app.yCurrent = app.yOriginal;

                app.fsOriginal = app.recorder.SampleRate;
                app.fsCurrent = app.fsOriginal;
        
                app.duration = length(app.yOriginal) / app.fsOriginal;
                bits = app.recorder.BitsPerSample;
                app.channel = app.recorder.NumChannels;
                
                fprintf(['時間長度: %.2f 秒 \n ' ...
                         '採樣率: %.2f 取樣點/秒 \n' ...
                         '解析度 %d 位元/取樣點 \n' ...
                         '聲道數: %d \n'], app.duration, app.fsCurrent, bits, app.channel);
                
                % 重製物件
                app.VolumeSlider.Value = 1;
                app.SpeedSlider.Value = 1;
                app.recordStatement = false;
                app.RecordButton.Text = 'Record';

                % 重新繪圖
                app.Plot_graph();
            end
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            % 還沒讀資料不能用
            if ~app.Nload_first_data()
                return;
            end
            
            % 選擇路徑
            [fileName, filePath] = uiputfile('*.wav', '儲存音訊檔案');

            % 儲存檔案
            fullPath = fullfile(filePath, fileName);
            audiowrite(fullPath, app.yCurrent, app.fsCurrent);
        end

        % Value changed function: FiltersFIRDropDown
        function FiltersFIRDropDownValueChanged(app, event)
            % 還沒讀資料不能用
            if ~app.Nload_first_data()
                app.FiltersFIRDropDown.Value = 'None';
                return;
            end

            % 創建濾波器
            app.Create_filter();
            
            % 套用濾波器
            if (isequal(app.FiltersFIRDropDown.Value, 'None'))
                app.yCurrent = app.yOriginal * app.VolumeSlider.Value;
            else
                app.yCurrent = filtfilt(app.filter, app.yOriginal) * app.VolumeSlider.Value;
            end

            % 重新繪圖
            app.Plot_graph();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [60 50 680 530];
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
            app.UIAxes.Position = [25 238 632 273];

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [191 213 68 22];
            app.Label.Text = 'Filters (FIR)';

            % Create FiltersFIRDropDown
            app.FiltersFIRDropDown = uidropdown(app.UIFigure);
            app.FiltersFIRDropDown.Items = {'None', 'Low-pass', 'High-pass', 'Band-pass', 'Band-stop'};
            app.FiltersFIRDropDown.ValueChangedFcn = createCallbackFcn(app, @FiltersFIRDropDownValueChanged, true);
            app.FiltersFIRDropDown.Position = [274 213 147 22];
            app.FiltersFIRDropDown.Value = 'None';

            % Create GraphButtonGroup
            app.GraphButtonGroup = uibuttongroup(app.UIFigure);
            app.GraphButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @GraphButtonGroupSelectionChanged, true);
            app.GraphButtonGroup.Title = 'Graph';
            app.GraphButtonGroup.Position = [63 143 106 96];

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
            app.Label_5.Position = [63 91 84 22];
            app.Label_5.Text = 'Play statement';

            % Create PlaystatementLamp
            app.PlaystatementLamp = uilamp(app.UIFigure);
            app.PlaystatementLamp.Position = [162 91 20 20];
            app.PlaystatementLamp.Color = [1 0 0];

            % Create PlayButton
            app.PlayButton = uibutton(app.UIFigure, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.Position = [203 90 100 23];
            app.PlayButton.Text = 'Play';

            % Create SaveButton
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [557 90 100 23];
            app.SaveButton.Text = 'Save';

            % Create LoadButton
            app.LoadButton = uibutton(app.UIFigure, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [321 90 100 23];
            app.LoadButton.Text = 'Load';

            % Create VolumeSlider_2Label
            app.VolumeSlider_2Label = uilabel(app.UIFigure);
            app.VolumeSlider_2Label.HorizontalAlignment = 'right';
            app.VolumeSlider_2Label.Position = [435 214 45 22];
            app.VolumeSlider_2Label.Text = 'Volume';

            % Create VolumeSlider
            app.VolumeSlider = uislider(app.UIFigure);
            app.VolumeSlider.Limits = [0 5];
            app.VolumeSlider.MajorTicks = [0 1 2 3 4 5];
            app.VolumeSlider.ValueChangedFcn = createCallbackFcn(app, @VolumeSliderValueChanged, true);
            app.VolumeSlider.Position = [501 223 145 3];
            app.VolumeSlider.Value = 1;

            % Create SpeedSliderLabel
            app.SpeedSliderLabel = uilabel(app.UIFigure);
            app.SpeedSliderLabel.HorizontalAlignment = 'right';
            app.SpeedSliderLabel.Position = [435 165 40 22];
            app.SpeedSliderLabel.Text = 'Speed';

            % Create SpeedSlider
            app.SpeedSlider = uislider(app.UIFigure);
            app.SpeedSlider.Limits = [0 5];
            app.SpeedSlider.ValueChangedFcn = createCallbackFcn(app, @SpeedSliderValueChanged, true);
            app.SpeedSlider.Position = [496 174 150 3];
            app.SpeedSlider.Value = 1;

            % Create RecordButton
            app.RecordButton = uibutton(app.UIFigure, 'push');
            app.RecordButton.ButtonPushedFcn = createCallbackFcn(app, @RecordButtonPushed, true);
            app.RecordButton.Position = [435 90 100 23];
            app.RecordButton.Text = 'Record';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Audio_filter_v2

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