function playAudio(y, Fs, play_button)
    persistent playing player
    
    % 初始化persistent variable
    if isempty(playing)
        playing = 0;
    end
    if isempty(player)
        player = [];
    end
    
    % 檢查播放狀態
    if playing == 0
        % 播放
        player = audioplayer(y, Fs);
        play(player);
        
        % 改變按鈕文字
        play_button.String = '停止';
        playing = 1;
    else
        % 停止
        if ~isempty(player)
            stop(player);
        end
        
        % 改變按鈕文字
        play_button.String = '播放';
        playing = 0;
    end
end