%% Sigma-Delta Modulator Analysis Script
clear; clc; close all;

% --- 核心系统参数 ---
filename = 'sdm_output_data.txt'; % 数据文件名
Fs = 3.2e6;              % 采样率 3.2 MHz
Fsig = 10e3;             % 信号频率 10 kHz
BW = 20e3;               % 信号带宽 20 kHz (用于计算带内噪声)

% --- 读取与预处理数据 ---
try
    dout = load(filename);
catch
    error('找不到文件！请确认当前文件夹里有 sdm_output_data.txt');
end

% 去除前1000个点，避开刚上电时的瞬态不稳定响应
if length(dout) > 1000
    dout = dout(1000:end);
end

N = length(dout);
t = (0:N-1)/Fs; % 时间轴

% --- 1. 画时域图 (阶梯图) ---
figure('Color', 'w', 'Position', [100, 100, 800, 600]);
subplot(2,1,1);
stairs(t(1:min(200,N))*1e6, dout(1:min(200,N)), 'LineWidth', 1.5, 'Color', '#0072BD');
title('Output Waveform (First 200 samples)', 'FontSize', 12);
xlabel('Time (\mus)'); ylabel('Digital Output');
grid on;

% --- 2. 频域分析 (FFT & PSD) ---
subplot(2,1,2);
% 加窗：Blackman-Harris 窗旁瓣极低，非常适合看高动态范围的信噪比
win = blackmanharris(N);
spectrum = fft(dout .* win);
mag = abs(spectrum(1:floor(N/2)+1));

% 归一化幅度到 dB (以最高峰为 0dB)
psd_db = 20*log10(mag / max(mag));
f = linspace(0, Fs/2, length(psd_db));

semilogx(f, psd_db, 'b', 'LineWidth', 1);
grid on; hold on;
title('Power Spectral Density (PSD)', 'FontSize', 12);
xlabel('Frequency (Hz)'); ylabel('Normalized Magnitude (dB)');
xlim([100 Fs/2]); 

% --- 3. 核心：正确计算 SNDR 和 ENOB ---
% 频点索引转换
bw_idx = round(BW / (Fs/N)) + 1;      % 带宽截止频率的索引
peak_idx = round(Fsig / (Fs/N)) + 1;  % 10kHz 信号频率的索引

% 在频谱图上用红点标出计算的信号峰值位置
plot(f(peak_idx), psd_db(peak_idx), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
xline(BW, 'r--', 'Bandwidth Limit', 'LabelVerticalAlignment', 'bottom');

% 3.1 计算信号能量 (主瓣)
% Blackman-Harris 窗主瓣较宽，左右各取 8 个频点以包揽全部信号能量
idx_range = max(1, peak_idx-8) : min(length(mag), peak_idx+8);
sig_power = sum(mag(idx_range).^2);

% 3.2 计算【带内】总能量 (从 DC 附近到带宽 BW)
% 从第 5 个频点开始算，是为了避开不可避免的直流(DC)失调干扰
inband_idx = 5 : bw_idx;
inband_power = sum(mag(inband_idx).^2);

% 3.3 计算带内噪声能量
noise_power = inband_power - sig_power;

% 容错处理：防止数值精度问题导致负数
if noise_power <= 0
    noise_power = 1e-12; 
end

% 3.4 计算最终指标
sndr = 10*log10(sig_power / noise_power);
enob = (sndr - 1.76) / 6.02;

% --- 4. 打印分析报告 ---
fprintf('\n=================================\n');
fprintf('      Sigma-Delta 分析报告      \n');
fprintf('=================================\n');
fprintf('采样率 (Fs)   : %.2f MHz\n', Fs/1e6);
fprintf('信号频率 (Fsig): %.1f kHz\n', Fsig/1e3);
fprintf('分析带宽 (BW)  : %.1f kHz\n', BW/1e3);
fprintf('过采样率 (OSR) : %d\n', round(Fs/(2*BW)));
fprintf('---------------------------------\n');
fprintf('SNDR          = %.2f dB\n', sndr);
fprintf('ENOB          = %.2f bits\n', enob);
fprintf('=================================\n\n');