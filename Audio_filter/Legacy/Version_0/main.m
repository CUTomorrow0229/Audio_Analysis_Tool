function main()
    % 開新figure
    main_fig = figure('Name', '音訊分析器', 'Position', [500, 500, 1200, 1000]);

    % 讀取音訊檔案
    [y, Fs] = readAudio();
    if isempty(y)
        return;
    end

    t = (0:length(y)-1) / Fs;

    % 繪製圖形、按鈕
    plotGraphs(y, Fs, t);
    createButtons(y, Fs, main_fig);

    main_fig.CloseRequestFcn = @closing;

    % 關閉視窗時結束正在播放的音訊
    function closing(src, ~)
        player_handle = getappdata(src, 'player_handle');
        if ~isempty(player_handle)
            try
                if isplaying(player_handle)
                    stop(player_handle);
                end
            catch
                
            end
        end
        delete(src);
    end
end