classdef Audio_filter < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        DarkmodeSwitch               matlab.ui.control.Switch
        DarkmodeSwitchLabel          matlab.ui.control.Label
        ApplyButton                  matlab.ui.control.Button
        CustomfilterDropDown         matlab.ui.control.DropDown
        CustomfilterDropDownLabel    matlab.ui.control.Label
        TimesEditField               matlab.ui.control.NumericEditField
        TimesEditFieldLabel          matlab.ui.control.Label
        MaxAmplitudeEditField        matlab.ui.control.NumericEditField
        MaxAmplitudeEditFieldLabel   matlab.ui.control.Label
        SampleRateEditField          matlab.ui.control.NumericEditField
        SampleRateEditFieldLabel     matlab.ui.control.Label
        StopbandFrequency2EditField  matlab.ui.control.NumericEditField
        StopbandFrequency2EditField_2Label  matlab.ui.control.Label
        PassbandFrequency2EditField  matlab.ui.control.NumericEditField
        PassbandFrequency2EditFieldLabel  matlab.ui.control.Label
        StopbandFrequencyEditField   matlab.ui.control.NumericEditField
        StopbandFrequencyEditFieldLabel  matlab.ui.control.Label
        PassbandFrequencyEditField   matlab.ui.control.NumericEditField
        PassbandFrequencyEditFieldLabel  matlab.ui.control.Label
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
        fileName         string             % 讀入檔名
        lineColor1       double             % 波形圖繪製顏色
        lineColor2       double             % 頻譜圖繪製顏色
        yOriginal        double             % 原始音訊
        yCurrent         double             % 修改後的音訊
        fsOriginal       double             % 原始採樣率
        fsCurrent        double             % 修改後的採樣率
        channel          int32              % (修改後的)聲道數
        duration         double             % (修改後的)總時長
        maxAmp           double             % (修改後的)最大震幅
        recorder         audiorecorder      % 錄音器
        recordStatement  logical = false    % 錄製狀態
        player           audioplayer        % 播放器
        playStatement    logical = false    % 播放狀態
        
        filter           digitalFilter      % 濾波器種類
        lowPassBand      double             % low-pass參數
        lowStopBand      double             % low-pass參數
        highPassBand     double             % high-pass參數
        highStopBand     double             % high-pass參數
        bpPassBand1      double             % band-pass參數
        bpPassBand2      double             % band-pass參數
        bpStopBand1      double             % band-pass參數
        bpStopBand2      double             % band-pass參數
        bsPassBand1      double             % band-stop參數
        bsPassBand2      double             % band-stop參數
        bsStopBand1      double             % band-stop參數
        bsStopBand2      double             % band-stop參數
        firstTimeCustom  logical = true     % 是否為第一次切到Custom(顯示說明)
        minTransition    double = 1000      % 檢查用的最小Transition
        minPassBandWidth double = 2000      % 檢查用的最小PassBand
        minStopBandWidth double = 2000      % 檢查用的最小StopBand
    end
    
    methods (Access = private)
        
        % 重製所有UI
        function Reset_UI(app)
            % 圖形選項
            app.GraphButtonGroup.SelectedObject = app.WaveformButton;
            
            % 濾波器選項
            app.FiltersFIRDropDown.Value = 'None';

            % 自訂濾波器選項
            app.CustomfilterDropDown.Visible = "off";
            app.CustomfilterDropDownLabel.Visible = "off";
            app.CustomfilterDropDown.Value = 'Low-pass';

            % 套用自訂濾波器按鈕
            app.ApplyButton.Visible = "off";
            
            % 兩個Slider
            app.VolumeSlider.Value = 1;
            app.SpeedSlider.Value = 1;

            % 播放狀態
            if app.playStatement
                stop(app.player);
                app.PlayButton.Text = 'Play';
                app.PlaystatementLamp.Color = 'red';
                app.playStatement = false;
            end

            % 底下四個Edit field
            app.PassbandFrequencyEditField.Visible = "off";
            app.PassbandFrequencyEditFieldLabel.Visible = "off";
            app.PassbandFrequencyEditField.Value = 3000;
            
            app.StopbandFrequencyEditField.Visible = "off";
            app.StopbandFrequencyEditFieldLabel.Visible = "off";
            app.StopbandFrequencyEditField.Value = 5000;

            app.PassbandFrequency2EditField.Visible = "off";
            app.PassbandFrequency2EditFieldLabel.Visible = "off";
            app.PassbandFrequency2EditField.Value = 6000;

            app.StopbandFrequency2EditField.Visible = "off";
            app.StopbandFrequency2EditField_2Label.Visible = "off";
            app.StopbandFrequency2EditField.Value = 8000;
        end
        
        % 顯示參數等資訊
        function Show_info(app)
            % 最大震幅、取樣率、時間(常態顯示)
            app.MaxAmplitudeEditField.Value = app.maxAmp;
            app.SampleRateEditField.ValueDisplayFormat = '%.0f';
            app.SampleRateEditField.Value = app.fsCurrent;
            app.TimesEditField.Value = app.duration;

            % 顯示物件
            app.Show_widget();

            % 填入濾波器數值(如果有用)
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
            end
        end
        
        % 管理物件的Visible和Editable
        function Show_widget(app)
            % 濾波器選項
            if isequal(app.FiltersFIRDropDown.Value, 'Low-pass') || isequal(app.FiltersFIRDropDown.Value, 'High-pass') 
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyEditFieldLabel.Visible = "on";
                app.PassbandFrequency2EditField.Editable = "off";

                app.StopbandFrequencyEditField.Visible = "on";
                app.StopbandFrequencyEditFieldLabel.Visible = "on";
                app.StopbandFrequencyEditField.Editable = "off";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2EditFieldLabel.Visible = "off";
                
                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2EditField_2Label.Visible = "off";

                app.CustomfilterDropDown.Visible = "off";
                app.CustomfilterDropDownLabel.Visible = "off";
                app.ApplyButton.Visible = "off";
            elseif isequal(app.FiltersFIRDropDown.Value, 'None')
                app.PassbandFrequencyEditField.Visible = "off";
                app.PassbandFrequencyEditFieldLabel.Visible = "off";

                app.StopbandFrequencyEditField.Visible = "off";
                app.StopbandFrequencyEditFieldLabel.Visible = "off";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2EditFieldLabel.Visible = "off";

                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2EditField_2Label.Visible = "off";

                app.CustomfilterDropDown.Visible = "off";
                app.CustomfilterDropDownLabel.Visible = "off";
                app.ApplyButton.Visible = "off";
            elseif isequal(app.FiltersFIRDropDown.Value, 'Band-pass') || isequal(app.FiltersFIRDropDown.Value, 'Band-stop')
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyEditFieldLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "off";

                app.StopbandFrequencyEditField.Visible = "on";
                app.StopbandFrequencyEditFieldLabel.Visible = "on";
                app.StopbandFrequencyEditField.Editable = "off";

                app.PassbandFrequency2EditField.Visible = "on";
                app.PassbandFrequency2EditFieldLabel.Visible = "on";
                app.PassbandFrequency2EditField.Editable = "off";

                app.StopbandFrequency2EditField.Visible = "on";
                app.StopbandFrequency2EditField_2Label.Visible = "on";
                app.StopbandFrequency2EditField.Editable = "off";

                app.CustomfilterDropDown.Visible = "off";
                app.CustomfilterDropDownLabel.Visible = "off";
                app.ApplyButton.Visible = "off";
            else
                app.CustomfilterDropDown.Visible = "on";
                app.CustomfilterDropDownLabel.Visible = "on";
                app.ApplyButton.Visible = "on";

                app.Show_widget_by_custom();
            end
        end
        
        % 管理物件的Visible和Editable(by custom)
        function Show_widget_by_custom(app)
            % 自訂濾波器選項
            if isequal(app.CustomfilterDropDown.Value, 'Low-pass') || isequal(app.CustomfilterDropDown.Value, 'High-pass') 
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyEditFieldLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "on";

                app.StopbandFrequencyEditField.Visible = "on";
                app.StopbandFrequencyEditFieldLabel.Visible = "on";
                app.StopbandFrequencyEditField.Editable = "on";

                app.PassbandFrequency2EditField.Visible = "off";
                app.PassbandFrequency2EditFieldLabel.Visible = "off";
                
                app.StopbandFrequency2EditField.Visible = "off";
                app.StopbandFrequency2EditField_2Label.Visible = "off";
            else
                app.PassbandFrequencyEditField.Visible = "on";
                app.PassbandFrequencyEditFieldLabel.Visible = "on";
                app.PassbandFrequencyEditField.Editable = "on";

                app.StopbandFrequencyEditField.Visible = "on";
                app.StopbandFrequencyEditFieldLabel.Visible = "on";
                app.StopbandFrequencyEditField.Editable = "on";

                app.PassbandFrequency2EditField.Visible = "on";
                app.PassbandFrequency2EditFieldLabel.Visible = "on";
                app.PassbandFrequency2EditField.Editable = "on";

                app.StopbandFrequency2EditField.Visible = "on";
                app.StopbandFrequency2EditField_2Label.Visible = "on";
                app.StopbandFrequency2EditField.Editable = "on";
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
        
        % 繪製波形圖
        function Plot_waveform(app)
            % 計算x軸(時間)
            t = (0:length(app.yCurrent) - 1)/app.fsCurrent;
            
            % 繪製圖表
            plot(app.UIAxes, t, app.yCurrent, Color=app.lineColor1);

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

            % 繪製圖表
            plot(app.UIAxes, xFreq, yMag, Color=app.lineColor2);

            title(app.UIAxes, 'Spectrum');
            xlabel(app.UIAxes, 'Frequency (Hz)');
            ylabel(app.UIAxes, 'Amplitude');

            % 設定x軸範圍(人類聽力範圍或Nyquist frequency)
            maxFreq = 20000;
            if app.fsCurrent / 2 < maxFreq
                maxFreq = app.fsCurrent / 2;
            end
            
            xlim(app.UIAxes, [0, maxFreq]);
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
        
        % 沒有載入資料就碰其他物件
        function permission = Nload_first_data(app)
            if isempty(app.fsCurrent)
                uialert(app.UIFigure, '尚未載入音訊資料', 'Error', 'Icon', 'error');
                permission = false;
            else
                permission = true;
            end
        end
        
        % 更新音訊資料
        function Update_audio(app)
            % 先暫停播放
            if app.playStatement
                stop(app.player);
                app.PlayButton.Text = 'Play';
                app.PlaystatementLamp.Color = 'red';
                app.playStatement = false;
            end

            % 調整取樣率
            app.fsCurrent = app.fsOriginal * app.SpeedSlider.Value;

            % 濾波
            app.Filter_audio();

            % 調整音量
            app.yCurrent = app.yCurrent * app.VolumeSlider.Value;

            % 更新duration
            app.duration = length(app.yCurrent) / app.fsCurrent;
            
            % 更新最大震幅
            app.maxAmp = max(abs(app.yCurrent), [], 'all');
        end
        
        % 濾波處理
        function Filter_audio(app)
            MAX_FS = 100000;
            nyquist = app.fsCurrent / 2;

            if (isequal(app.FiltersFIRDropDown.Value, 'None'))
                app.yCurrent = app.yOriginal;
            elseif app.fsCurrent > MAX_FS    % 限制最大取樣率，避免當機
                uialert(app.UIFigure, '取樣率過高，無法設計濾波器，已自動停用濾波器', 'Error', 'Icon', 'error');
                app.FiltersFIRDropDown.Value = 'None';
                app.yCurrent = app.yOriginal;
            elseif nyquist < 6000    % 限制最小取樣率，避免錯誤
                uialert(app.UIFigure, '取樣率過低，無法設計濾波器，已自動停用濾波器', 'Error', 'Icon', 'error');
                app.FiltersFIRDropDown.Value = 'None';
                app.yCurrent = app.yOriginal;
            else
                app.Create_filter();
                
                % 多聲道處理
                if app.channel > 1
                    app.yCurrent = zeros(size(app.yOriginal));
                    for i = 1:app.channel
                        app.yCurrent(:, i) = filtfilt(app.filter, app.yOriginal(:, i));
                    end
                else
                    app.yCurrent = filtfilt(app.filter, app.yOriginal);
                end
            end
        end

        % 創建濾波器
        function Create_filter(app)
            switch app.FiltersFIRDropDown.Value
                case 'Low-pass'
                    app.firstTimeCustom = true;

                    app.lowPassBand = 3000;
                    app.lowStopBand = 5000;

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
                case 'Custom'
                    if app.firstTimeCustom
                        uialert(app.UIFigure, '請選擇濾波器種類和參數', 'Customize filter', 'Icon', 'info');
                        app.firstTimeCustom = false;
                    end
                    app.Create_custom_filter();
            end
        end

        function Create_custom_filter(app)
            switch app.CustomfilterDropDown.Value
                case 'Low-pass'
                    % 讀取種類
                    customFilter = 'lowpassfir';
                    
                    % 確認輸入
                    app.Check_input();
                    
                    % 讀取數值
                    app.lowStopBand = app.StopbandFrequencyEditField.Value;
                    app.lowPassBand = app.PassbandFrequencyEditField.Value;

                    % 建立濾波器
                    app.filter = designfilt(customFilter, ...
                            StopbandFrequency = app.lowStopBand, ...
                            PassbandFrequency = app.lowPassBand, ...
                            SampleRate = app.fsCurrent);
                case 'High-pass'
                    % 讀取種類
                    customFilter = 'highpassfir';
                    
                    % 確認輸入
                    app.Check_input();
                    
                    % 讀取數值
                    app.highStopBand = app.StopbandFrequencyEditField.Value;
                    app.highPassBand = app.PassbandFrequencyEditField.Value;
                    
                    % 建立濾波器
                    app.filter = designfilt(customFilter, ...
                            StopbandFrequency = app.highStopBand, ...
                            PassbandFrequency = app.highPassBand, ...
                            SampleRate = app.fsCurrent);
                case 'Band-pass'
                    % 讀取種類
                    customFilter = 'bandpassfir';

                    % 確認輸入
                    app.Check_input();

                    % 讀取數值
                    app.bpStopBand1 = app.StopbandFrequencyEditField.Value;
                    app.bpPassBand1 = app.PassbandFrequencyEditField.Value;
                    app.bpPassBand2 = app.PassbandFrequency2EditField.Value;
                    app.bpStopBand2 = app.StopbandFrequency2EditField.Value;
                    
                    % 建立濾波器
                    app.filter = designfilt(customFilter, ...
                            PassbandFrequency1 = app.bpPassBand1, ...
                            StopbandFrequency1 = app.bpStopBand1, ...
                            StopbandFrequency2 = app.bpStopBand2, ...
                            PassbandFrequency2 = app.bpPassBand2, ...
                            SampleRate = app.fsCurrent);
                case 'Band-stop'
                    % 讀取種類
                    customFilter = 'bandstopfir';

                    % 確認輸入
                    app.Check_input();

                    % 讀取數值
                    app.bsPassBand1 = app.PassbandFrequencyEditField.Value;
                    app.bsStopBand1 = app.StopbandFrequencyEditField.Value;
                    app.bsStopBand2 = app.StopbandFrequency2EditField.Value;
                    app.bsPassBand2 = app.PassbandFrequency2EditField.Value;
                   
                    % 建立濾波器
                    app.filter = designfilt(customFilter, ...
                            PassbandFrequency1 = app.bsPassBand1, ...
                            StopbandFrequency1 = app.bsStopBand1, ...
                            StopbandFrequency2 = app.bsStopBand2, ...
                            PassbandFrequency2 = app.bsPassBand2, ...
                            SampleRate = app.fsCurrent);
            end
        end
        
        % 檢查自訂濾波器的輸入數值
        function Check_input(app)
            switch app.CustomfilterDropDown.Value
                case 'Low-pass'
                    % 檢查大小是否正確(PassBand < StopBand)
                    if app.StopbandFrequencyEditField.Value <= app.PassbandFrequencyEditField.Value
                        app.StopbandFrequencyEditField.Value = app.PassbandFrequencyEditField.Value + 1000;
                        uialert(app.UIFigure, '輸入值大小順序錯誤，已自動調整', 'Warning', 'Icon', 'warning');
                    end
                case 'High-pass'
                    % 檢查大小是否正確(StopBand < PassBand)
                    if app.StopbandFrequencyEditField.Value >= app.PassbandFrequencyEditField.Value
                        app.PassbandFrequencyEditField.Value = app.StopbandFrequencyEditField.Value + 1000;
                        uialert(app.UIFigure, '輸入值大小順序錯誤，已自動調整', 'Warning', 'Icon', 'warning');
                    end
                case 'Band-pass'
                    % 檢查是否遞增(StopBand1 < PassBand1 < PassBand2 < StopBand2)
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

                    % 檢查transition寬度
                    if app.PassbandFrequencyEditField.Value - app.StopbandFrequencyEditField.Value < app.minTransition
                        app.PassbandFrequencyEditField.Value = app.StopbandFrequencyEditField.Value + app.minTransition;
                        uialert(app.UIFigure, 'Passband1與Stopband1間距過小，已自動調整', 'Warning', 'Icon', 'warning');
                    end

                    if app.StopbandFrequency2EditField.Value - app.PassbandFrequency2EditField.Value < app.minTransition
                        app.StopbandFrequency2EditField.Value = app.PassbandFrequency2EditField.Value + app.minTransition;
                        uialert(app.UIFigure, 'Stopband2與Passband2間距過小，已自動調整', 'Warning', 'Icon', 'warning');
                    end

                    % 檢查PassBand寬度
                    if app.PassbandFrequency2EditField.Value - app.PassbandFrequencyEditField.Value < app.minPassBandWidth
                        app.PassbandFrequency2EditField.Value = app.PassbandFrequencyEditField.Value + app.minPassBandWidth;
                        
                        % 確定沒有超過StopBand2
                        if app.PassbandFrequency2EditField.Value >= app.StopbandFrequency2EditField.Value
                            app.StopbandFrequency2EditField.Value = app.PassbandFrequency2EditField.Value + app.minTransition;
                        end
                    
                        uialert(app.UIFigure, '通帶寬度不足，已自動調整', 'Warning', 'Icon', 'warning');
                    end
                case 'Band-stop'

                    % 檢查是否遞增(PassBand1 < StopBand1 < StopBand2 < PassBand2)
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

                    % 檢查transition寬度
                    if app.StopbandFrequencyEditField.Value - app.PassbandFrequencyEditField.Value < app.minTransition
                        app.StopbandFrequencyEditField.Value = app.PassbandFrequencyEditField.Value + app.minTransition;
                        uialert(app.UIFigure, 'Stopband1與Passband1間距過小，已自動調整', 'Warning', 'Icon', 'warning');
                    end

                    if app.PassbandFrequency2EditField.Value - app.StopbandFrequency2EditField.Value < app.minTransition
                        app.PassbandFrequency2EditField.Value = app.StopbandFrequency2EditField.Value + app.minTransition;
                        uialert(app.UIFigure, 'Passband2與Stopband2間距過小，已自動調整', 'Warning', 'Icon', 'warning');
                    end

                    % 檢查StopBand寬度
                    if app.StopbandFrequency2EditField.Value - app.StopbandFrequencyEditField.Value < app.minStopBandWidth
                        app.StopbandFrequency2EditField.Value = app.StopbandFrequencyEditField.Value + app.minStopBandWidth;

                        % 確定沒有超過PassBand2
                        if app.StopbandFrequency2EditField.Value >= app.PassbandFrequency2EditField.Value
                            app.PassbandFrequency2EditField.Value = app.StopbandFrequency2EditField.Value + app.minTransition;
                        end

                        uialert(app.UIFigure, 'Stopband 寬度不足，已自動調整', 'Warning', 'Icon', 'warning');
                    end
            end 
        end
        
        % 動態更新標題
        function Update_title(app)
            % 取得圖表類型
            graph = app.GraphButtonGroup.SelectedObject.Text;
            
            % 取得音量
            if app.VolumeSlider.Value == 1
                volume = "";
            else
                volume = "| Vol: " + num2str(app.VolumeSlider.Value) + "x";
            end

            % 取得速度
            if app.SpeedSlider.Value == 1
                speed = "";
            else
                speed = "| Spd: " + num2str(app.SpeedSlider.Value) + "x";
            end

            % 取得濾波器種類
            filterStr = "| Filter: [ " + app.FiltersFIRDropDown.Value + " ]";

            % 組合成標題
            title = sprintf("[ %s ] – [ %s ] %s %s %s", app.fileName, graph, volume, speed, filterStr);
    
            app.UIAxes.Title.Interpreter = "none";
            app.UIAxes.Title.String = title;
        end
        
        % 外觀主題
        function Change_theme(app)
            isDark = strcmp(app.DarkmodeSwitch.Value, 'On');
    
            % 設定顏色
            if isDark
                bgColor = [0.15 0.15 0.15];
                fgColor = [1 1 1];
                gridColor = [0.7 0.7 0.7];
                app.lineColor1 = [0 1 1];
                app.lineColor2 = [0.5 0.7 1];
                figureColor = [0.3 0.3 0.3];
                btnColor = [0.51 0.51 0.51];
            else
                bgColor = [1 1 1];           
                fgColor = [0 0 0];           
                gridColor = [0.6 0.6 0.6];   
                app.lineColor1 = [0.01 0.4 0.7];
                app.lineColor2 = [0.5 0.2 0.6];
                figureColor = [0.94,0.94,0.94];
                btnColor = [0.49 0.49 0.49];
            end

            % 重新繪圖
            app.Plot_graph();

            % 套用顏色
            % 背景
            app.UIFigure.Color = figureColor;
            
            % 表格
            app.UIAxes.Color = bgColor;
            app.UIAxes.XColor = fgColor;
            app.UIAxes.YColor = fgColor;
            app.UIAxes.GridColor = gridColor;
            app.UIAxes.Title.Color = fgColor;
            app.UIAxes.XLabel.Color = fgColor;
            app.UIAxes.YLabel.Color = fgColor;
            
            % 圖表選項
            app.GraphButtonGroup.ForegroundColor = fgColor;
            app.GraphButtonGroup.BackgroundColor = figureColor;
            app.GraphButtonGroup.BorderColor = btnColor;
            app.WaveformButton.FontColor = fgColor;
            app.SpectrumButton.FontColor = fgColor;
            app.SpectrogramButton.FontColor = fgColor;

            % 濾波器選項
            app.FiltersFIRDropDown.FontColor = fgColor;
            app.FiltersFIRDropDown.BackgroundColor = figureColor;
            app.Label.FontColor = fgColor;
            app.Label.BackgroundColor = figureColor;
            
            % 自訂濾波器選項
            app.CustomfilterDropDown.FontColor = fgColor;
            app.CustomfilterDropDown.BackgroundColor = figureColor;
            app.CustomfilterDropDownLabel.FontColor = fgColor;
            app.CustomfilterDropDownLabel.BackgroundColor = figureColor;

            % 套用按鈕
            app.ApplyButton.FontColor = fgColor;
            app.ApplyButton.BackgroundColor = figureColor;

            % 音量拉桿
            app.VolumeSlider.FontColor = fgColor;
            app.VolumeSlider_2Label.FontColor = fgColor;
            app.VolumeSlider_2Label.BackgroundColor = figureColor;

            % 速度拉桿
            app.SpeedSlider.FontColor = fgColor;
            app.SpeedSliderLabel.FontColor = fgColor;
            app.SpeedSliderLabel.BackgroundColor = figureColor;

            % 最大震幅
            app.MaxAmplitudeEditField.FontColor = fgColor;
            app.MaxAmplitudeEditField.BackgroundColor = figureColor;
            app.MaxAmplitudeEditFieldLabel.FontColor = fgColor;
            app.MaxAmplitudeEditFieldLabel.BackgroundColor = figureColor;

            % 採樣率
            app.SampleRateEditField.FontColor = fgColor;
            app.SampleRateEditField.BackgroundColor = figureColor;
            app.SampleRateEditFieldLabel.FontColor = fgColor;
            app.SampleRateEditFieldLabel.BackgroundColor = figureColor;

            % 時間
            app.TimesEditField.FontColor = fgColor;
            app.TimesEditField.BackgroundColor = figureColor;
            app.TimesEditFieldLabel.FontColor = fgColor;
            app.TimesEditFieldLabel.BackgroundColor = figureColor;

            % 播放狀態
            app.Label_5.FontColor = fgColor;
            app.Label_5.BackgroundColor = figureColor;
            
            % 播放按鈕
            app.PlayButton.FontColor = fgColor;
            app.PlayButton.BackgroundColor = figureColor;

            % 讀取按鈕
            app.LoadButton.FontColor = fgColor;
            app.LoadButton.BackgroundColor = figureColor;

            % 錄音按鈕
            app.RecordButton.FontColor = fgColor;
            app.RecordButton.BackgroundColor = figureColor;

            % 儲存按鈕
            app.SaveButton.FontColor = fgColor;
            app.SaveButton.BackgroundColor = figureColor;

            % Passband1
            app.PassbandFrequencyEditField.FontColor = fgColor;
            app.PassbandFrequencyEditField.BackgroundColor = figureColor;
            app.PassbandFrequencyEditFieldLabel.FontColor = fgColor;
            app.PassbandFrequencyEditFieldLabel.BackgroundColor = figureColor;

            % Passband2
            app.PassbandFrequency2EditField.FontColor = fgColor;
            app.PassbandFrequency2EditField.BackgroundColor = figureColor;
            app.PassbandFrequency2EditFieldLabel.FontColor = fgColor;
            app.PassbandFrequency2EditFieldLabel.BackgroundColor = figureColor;

            % Stopband1
            app.StopbandFrequencyEditField.FontColor = fgColor;
            app.StopbandFrequencyEditField.BackgroundColor = figureColor;
            app.StopbandFrequencyEditFieldLabel.FontColor = fgColor;
            app.StopbandFrequencyEditFieldLabel.BackgroundColor = figureColor;

            % Stopband2
            app.StopbandFrequency2EditField.FontColor = fgColor;
            app.StopbandFrequency2EditField.BackgroundColor = figureColor;
            app.StopbandFrequency2EditField_2Label.FontColor = fgColor;
            app.StopbandFrequency2EditField_2Label.BackgroundColor = figureColor;

            % 切換按鈕
            app.DarkmodeSwitch.FontColor = fgColor;
            app.DarkmodeSwitchLabel.FontColor = fgColor;
            app.DarkmodeSwitchLabel.BackgroundColor = figureColor;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % 設定主題
            app.Change_theme();
            % 初見提示
            uialert(app.UIFigure, '請先讀取或錄製音訊資料', 'Welcome', 'Icon', 'info');
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            % 選取檔案
            [fileNameToRead, filePath] = uigetfile({'*.wav', 'wav file (*.wav)'}, 'Selecting file');
            
            % 使用者按取消
            if isequal(app.fileName, 0)
                uialert(app.UIFigure, '未選取檔案', 'Warning', 'Icon', 'warning');
            else
                % 提示成功讀取
                uialert(app.UIFigure, '讀取成功！', 'Success', 'Icon', 'success');
                
                % 讀取檔案
                fullPath = [filePath, fileNameToRead];
                [app.yOriginal, app.fsOriginal] = audioread(fullPath);
                app.yCurrent = app.yOriginal;
                app.fsCurrent = app.fsOriginal;

                % 儲存資訊
                app.fileName = erase(fileNameToRead, '.wav');
                audioInfo = audioinfo(fullPath);
                app.channel = audioInfo.NumChannels;
                app.duration = audioInfo.Duration;
                app.maxAmp = max(abs(app.yCurrent), [], 'all');

                % 防止音訊太大爆音
                %if max(abs(app.yOriginal)) > 0.9
                %    warning('音訊振幅過大，可能會失真');
                %    app.yOriginal = app.yOriginal * 0.9 / max(abs(app.yOriginal));
                %end

                % 重製物件
                app.Reset_UI();

                % 顯示參數
                app.Show_info();

                % 繪製圖形
                app.Plot_graph();
                app.Update_title();
            end
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
            app.Update_title();
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
                % 停止播放比照辦理
                app.PlayButton.Text = 'Play';
                
                % 停止播放
                stop(app.player);
                
                app.PlaystatementLamp.Color = 'red';
                app.playStatement = false;
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % 如果正在播放
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
            
            % 更新音訊資料
            app.Update_audio();

            % 顯示參數
            app.Show_info();

            % 重新繪圖
            app.Plot_graph();
            app.Update_title();
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
            
            % 更新音訊資料
            app.Update_audio();

            % 顯示參數
            app.Show_info();

            % 重新繪圖
            app.Plot_graph();
            app.Update_title();
        end

        % Button pushed function: RecordButton
        function RecordButtonPushed(app, event)
            % 如果想要錄音(按按鈕 + 目前沒在錄)
            if ~app.recordStatement
                fs = 44100;
                bits = 16;
                channels = 1;
                
                % 開始錄音
                uialert(app.UIFigure, '開始錄音...', 'Recording', 'Icon', 'info');
                app.recorder = audiorecorder(fs, bits, channels);
                record(app.recorder);

                app.recordStatement = true;
                app.RecordButton.Text = 'Stop';
            else
                % 停止錄音
                stop(app.recorder);

                % 提示錄製成功
                uialert(app.UIFigure, '錄製成功！', 'Success', 'Icon', 'success');
                
                % 儲存結果
                yRecorded = getaudiodata(app.recorder);
                app.yOriginal = yRecorded;
                app.yCurrent = app.yOriginal;
                app.fsOriginal = app.recorder.SampleRate;
                app.fsCurrent = app.fsOriginal;

                % 儲存資訊
                app.duration = length(app.yOriginal) / app.fsOriginal;
                app.channel = app.recorder.NumChannels;
                app.maxAmp = max(abs(app.yCurrent), [], 'all');
                app.fileName = "User Recorded";
                
                % 重製錄製狀態
                app.recordStatement = false;
                app.RecordButton.Text = 'Record';

                % 重製物件
                app.Reset_UI();

                % 顯示參數
                app.Show_info();

                % 繪製圖形
                app.Plot_graph();
                app.Update_title();
            end
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            % 還沒讀資料不能用
            if ~app.Nload_first_data()
                return;
            end

            % 選擇路徑
            [saveFileName, filePath] = uiputfile('*.wav', '儲存音訊檔案');
            
            % 處理未選擇路徑的事件
            if isequal(saveFileName, 0)
                uialert(app.UIFigure, '未儲存檔案', 'Warning', 'Icon', 'warning');
            else
                % 儲存檔案
                fullPath = fullfile(filePath, saveFileName);
                audiowrite(fullPath, app.yCurrent, round(app.fsCurrent));

                % 提示成功儲存
                uialert(app.UIFigure, '儲存成功！', 'Success', 'Icon', 'success');
            end
        end

        % Value changed function: FiltersFIRDropDown
        function FiltersFIRDropDownValueChanged(app, event)
            % 還沒讀資料不能用
            if ~app.Nload_first_data()
                app.FiltersFIRDropDown.Value = 'None';
                return;
            end
            
            % 切到Custom時初始化底下4個值
            if isequal(app.FiltersFIRDropDown.Value, 'Custom')
                app.Show_info();
                app.PassbandFrequencyEditField.Value = 3000;
                app.StopbandFrequencyEditField.Value = 5000;
                app.PassbandFrequency2EditField.Value = 6000;
                app.StopbandFrequency2EditField.Value = 8000;
            end

            % 更新音訊資料
            app.Update_audio();

            % 顯示參數
            app.Show_info();

            % 重新繪圖
            app.Plot_graph();
            app.Update_title();
        end

        % Button pushed function: ApplyButton
        function ApplyButtonPushed(app, event)
            % 更新音訊資料
            app.Update_audio();

            % 顯示參數
            app.Show_info();

            % 重新繪圖
            app.Plot_graph();
            app.Update_title();
        end

        % Value changed function: CustomfilterDropDown
        function CustomfilterDropDownValueChanged(app, event)
            % 根據選的濾波器判斷要不要顯示底下兩個Edit field
            app.Show_info();
        end

        % Value changed function: DarkmodeSwitch
        function DarkmodeSwitchValueChanged(app, event)
            % 更改主題
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
            app.FiltersFIRDropDown.Items = {'None', 'Low-pass', 'High-pass', 'Band-pass', 'Band-stop', 'Custom'};
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

            % Create PassbandFrequencyEditFieldLabel
            app.PassbandFrequencyEditFieldLabel = uilabel(app.UIFigure);
            app.PassbandFrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.PassbandFrequencyEditFieldLabel.Visible = 'off';
            app.PassbandFrequencyEditFieldLabel.Position = [48 63 115 22];
            app.PassbandFrequencyEditFieldLabel.Text = 'PassbandFrequency';

            % Create PassbandFrequencyEditField
            app.PassbandFrequencyEditField = uieditfield(app.UIFigure, 'numeric');
            app.PassbandFrequencyEditField.Editable = 'off';
            app.PassbandFrequencyEditField.Visible = 'off';
            app.PassbandFrequencyEditField.Position = [185 63 81 22];
            app.PassbandFrequencyEditField.Value = 3000;

            % Create StopbandFrequencyEditFieldLabel
            app.StopbandFrequencyEditFieldLabel = uilabel(app.UIFigure);
            app.StopbandFrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.StopbandFrequencyEditFieldLabel.Visible = 'off';
            app.StopbandFrequencyEditFieldLabel.Position = [433 63 113 22];
            app.StopbandFrequencyEditFieldLabel.Text = 'StopbandFrequency';

            % Create StopbandFrequencyEditField
            app.StopbandFrequencyEditField = uieditfield(app.UIFigure, 'numeric');
            app.StopbandFrequencyEditField.Editable = 'off';
            app.StopbandFrequencyEditField.Visible = 'off';
            app.StopbandFrequencyEditField.Position = [568 63 81 22];
            app.StopbandFrequencyEditField.Value = 5000;

            % Create PassbandFrequency2EditFieldLabel
            app.PassbandFrequency2EditFieldLabel = uilabel(app.UIFigure);
            app.PassbandFrequency2EditFieldLabel.HorizontalAlignment = 'right';
            app.PassbandFrequency2EditFieldLabel.Visible = 'off';
            app.PassbandFrequency2EditFieldLabel.Position = [48 21 122 22];
            app.PassbandFrequency2EditFieldLabel.Text = 'PassbandFrequency2';

            % Create PassbandFrequency2EditField
            app.PassbandFrequency2EditField = uieditfield(app.UIFigure, 'numeric');
            app.PassbandFrequency2EditField.Editable = 'off';
            app.PassbandFrequency2EditField.Visible = 'off';
            app.PassbandFrequency2EditField.Position = [185 21 81 22];
            app.PassbandFrequency2EditField.Value = 6000;

            % Create StopbandFrequency2EditField_2Label
            app.StopbandFrequency2EditField_2Label = uilabel(app.UIFigure);
            app.StopbandFrequency2EditField_2Label.HorizontalAlignment = 'right';
            app.StopbandFrequency2EditField_2Label.Visible = 'off';
            app.StopbandFrequency2EditField_2Label.Position = [433 21 120 22];
            app.StopbandFrequency2EditField_2Label.Text = 'StopbandFrequency2';

            % Create StopbandFrequency2EditField
            app.StopbandFrequency2EditField = uieditfield(app.UIFigure, 'numeric');
            app.StopbandFrequency2EditField.Editable = 'off';
            app.StopbandFrequency2EditField.Visible = 'off';
            app.StopbandFrequency2EditField.Position = [568 21 81 22];
            app.StopbandFrequency2EditField.Value = 8000;

            % Create SampleRateEditFieldLabel
            app.SampleRateEditFieldLabel = uilabel(app.UIFigure);
            app.SampleRateEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleRateEditFieldLabel.Position = [255 154 71 22];
            app.SampleRateEditFieldLabel.Text = 'SampleRate';

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

            % Create CustomfilterDropDownLabel
            app.CustomfilterDropDownLabel = uilabel(app.UIFigure);
            app.CustomfilterDropDownLabel.HorizontalAlignment = 'right';
            app.CustomfilterDropDownLabel.Visible = 'off';
            app.CustomfilterDropDownLabel.Position = [191 219 72 22];
            app.CustomfilterDropDownLabel.Text = 'Custom filter';

            % Create CustomfilterDropDown
            app.CustomfilterDropDown = uidropdown(app.UIFigure);
            app.CustomfilterDropDown.Items = {'Low-pass', 'High-pass', 'Band-pass', 'Band-stop'};
            app.CustomfilterDropDown.ValueChangedFcn = createCallbackFcn(app, @CustomfilterDropDownValueChanged, true);
            app.CustomfilterDropDown.Visible = 'off';
            app.CustomfilterDropDown.Position = [278 219 147 22];
            app.CustomfilterDropDown.Value = 'Low-pass';

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
        function app = Audio_filter

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