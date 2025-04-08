function playAudio(y, Fs, play_button, main_fig)
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
        % 播放（先改字，避免誤以為當機）
        play_button.String = '停止';
        player = audioplayer(y, Fs);
        play(player);

        % 保存播放狀態
        setappdata(main_fig, 'player_handle', player);
        playing = 1;
    else
        % 停止
        play_button.String = '播放';
        if ~isempty(player)
            stop(player);
        end

        % 保存播放狀態
        setappdata(main_fig, 'player_handle', []);
        playing = 0;
    end

    % TODO 顯示目前播放位置的滑桿，可以知道播放到哪裡
    
end