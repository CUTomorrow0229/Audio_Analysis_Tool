function main1_1()
    % 初始化
    clear;
    clc;
    close all;
    figure('Name', '音訊分析器', 'Position', [500, 500, 1200, 1000]);
    
    % 讀取音訊檔案
    [y, Fs, file_name] = read_audio();
    if isempty(y)
        return;
    end
    
    t = (0:length(y)-1) / Fs;
    
    % 繪製圖形
    plot_audio_graphs(y, Fs, t);
    
    % 創建按鈕
    create_buttons(y, Fs);
end