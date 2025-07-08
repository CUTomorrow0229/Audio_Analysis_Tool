fs = 44100;
duration = 3;
t = linspace(0, duration, fs * duration);

y = struct();
y.A = 0.01 * sin(2*pi*440*t);  % 純音 A4
y.B = 0.01 * (sin(2*pi*440*t) + sin(2*pi*880*t)); % 混合音
y.C = 0.01 * chirp(t, 100, duration, 8000); % Chirp sweep
y.D = 0.01 * randn(1, length(t)); % 白噪音
y.E_square = 0.01 * square(2*pi*440*t); % 方波
y.E_saw = 0.01 * sawtooth(2*pi*440*t); % 鋸齒波
y.F_stereo = [0.01 * sin(2*pi*440*t)', 0.01 * sin(2*pi*880*t)']; % 立體聲

audiowrite('A_sine_440Hz.wav', y.A, fs);
audiowrite('B_mixed_440Hz_880Hz.wav', y.B, fs);
audiowrite('C_chirp_100Hz_to_8000Hz.wav', y.C, fs);
audiowrite('D_white_noise.wav', y.D, fs);
audiowrite('E_square_440Hz.wav', y.E_square, fs);
audiowrite('E_sawtooth_440Hz.wav', y.E_saw, fs);
audiowrite('F_stereo_440Hz_880Hz.wav', y.F_stereo, fs);
