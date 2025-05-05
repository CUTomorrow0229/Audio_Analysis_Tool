function [y, Fs, file_name] = read_audio()
    % 讀取.wav檔案
    [file_name, file_path] = uigetfile({'*.wav', 'wav音訊檔 (*.wav)'}, '選擇檔案');
    
    if isequal(file_name, 0)|| isequal(file_path, 0)
        disp('未選擇檔案');
        y = [];
        Fs = [];
        return;
    end
    
    % 讀取音訊檔
    full_path = [file_path, file_name];
    [y, Fs] = audioread(full_path);
    
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