function [y, Fs] = readAudio()
    % 讀取檔案
    [file_name, file_path] = uigetfile({'*.wav', 'wav音訊檔 (*.wav)'}, '選擇檔案');
    if isequal(file_name, 0)|| isequal(file_path, 0)
        disp('未選擇檔案');
        y = [];
        Fs = [];
        return;
    end
    
    full_path = [file_path, file_name];
    [y, Fs] = audioread(full_path);

    % 防止音訊太大爆音
    if max(abs(y)) > 0.9
        warning('音訊振幅過大，可能會失真');
        y = y * 0.9 / max(abs(y));
    end
    
    % 計算聲道數
    if size(y, 2) == 2
        channels = 2;
    else
        channels = 1;
    end

    % 顯示檔案資訊
    duration = length(y) / Fs;
    disp(['檔案名稱: ', file_name]);
    disp(['採樣率: ', num2str(Fs), ' Hz']);
    disp(['時間長度: ', num2str(duration), ' 秒']);
    disp(['樣本數: ', num2str(length(y))]);
    disp(['聲道數: ', num2str(channels)]);
end