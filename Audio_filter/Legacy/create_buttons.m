function create_buttons(y, Fs)
    % 播放音訊的按鈕
    play_button = uicontrol('Style', 'pushbutton');
    play_button.Position = [50, 20, 100, 30];
    play_button.String = '播放';
    play_button.Callback = @(src, event) playAudio(y, Fs, play_button);
    
    % 顯示時頻譜的按鈕
    spec_button = uicontrol('Style', 'pushbutton');
    spec_button.Position = [200, 20, 150, 30];
    spec_button.String = '顯示時頻圖';
    spec_button.Callback = @(src, event) showSpectrogram(y, Fs);
    
end