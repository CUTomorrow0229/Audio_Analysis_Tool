function plotSpectrogram(y, Fs)
    figure('Name', 'Spectrogram', 'Position', [150, 150, 800, 600]);
    
    % 雙聲道在搞（spectrogram不能處理矩陣）
    if size(y, 2) > 1
        % 左聲道
        subplot(2, 1, 1);
        spectrogram(y(:, 1), hamming(512), 256, 1024, Fs, 'yaxis');
        title('左聲道時頻譜');
        colorbar;
        
        % 右聲道
        subplot(2, 1, 2);
        spectrogram(y(:, 2), hamming(512), 256, 1024, Fs, 'yaxis');
        title('右聲道時頻譜');
        colorbar;
    else
        % 單聲道
        spectrogram(y, hamming(512), 256, 1024, Fs, 'yaxis');
        title('時頻譜');
        colorbar;
    end
end