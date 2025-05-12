function createButtons(y, Fs, main_fig)
    % 播放音訊的按鈕
    play_button = uicontrol('Style', 'pushbutton');
    play_button.Position = [50, 20, 100, 30];
    play_button.String = '播放';
    play_button.Callback = @(src, event) playAudio(y, Fs, play_button, main_fig);
    
    % 顯示時頻譜的按鈕
    spec_button = uicontrol('Style', 'pushbutton');
    spec_button.Position = [200, 20, 150, 30];
    spec_button.String = '顯示時頻譜';
    spec_button.Callback = @(src, event) plotSpectrogram(y, Fs);
    
    % TODO 儲存輸出結果
    % save_button = uicontrol('Style', 'pushbutton');
    % save_button.Position = [350, 20, 100, 30];
    % save_button.String = '儲存結果';
    % save_button.Callback = @(src, event) exportData(y, Fs);
end