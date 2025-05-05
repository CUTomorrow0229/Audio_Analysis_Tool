function plot_audio_graphs(y, Fs, t)
    % 畫波形圖
    subplot(2, 1, 1);
    plot(t, y, 'b');
    grid on;
    title('波形圖');
    xlabel('時間 (s)');
    ylabel('振幅');
    
    % FFT計算
    temp1 = fft(y);
    len = length(y);
    temp2 = abs(temp1/len);
    temp3 = temp2(1:floor(len/2+1));
    temp3(2:end-1) = 2*temp3(2:end-1);
    x_freq = Fs * (0:floor(len/2)) / len;
    y_mag = temp3;
    
    % 畫頻譜圖
    subplot(2, 1, 2);
    plot(x_freq, y_mag, 'r');
    grid on;
    title('振幅頻譜');
    xlabel('頻率 (Hz)');
    ylabel('|Y(f)|');

    % 設定x軸範圍 
    max_freq = 20000;
    if Fs/2 < max_freq
        max_freq = Fs/2;
    end
    xlim([0, max_freq]); % 人類聽力範圍或Nyquist頻率
end