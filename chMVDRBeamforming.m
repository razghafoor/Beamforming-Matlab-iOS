%% Simulation of the MVDR beamforming algorithm
%% CONSTANTS USED
clear all; close all; clc;
load('recordings.mat')
% Array geometry
d = 0.08575; % Inter-element spacing
N = 2; % Total number of microphones

% Physical constants
c = 343; % Speed of sound in air in meter/seconds

% Properties of the incoming signal
freq = 300; % Frequency of the 1st desired signal to be filtered
freqNoise = 700; % Frequency of the 2nd interfering unwanted signal
theta = pi/2; % Angle of arrival of the desired signal
thetaNoise = 140*pi/180; % Angle of arrival of the unwanted 2nd signal

% Properties for the sampling
fs = 80000; % Sampling frequency
time_frame = 0.02; % Duration of 1 time frame
samplesptf = fs * time_frame; % The amount of samples per time frame
noise_amp = 0.1; % The noise amplitude
L = 2^(ceil(log2(samplesptf))); % Number of bin frequencies used for the fft. has to be a power of 2
totalTime = 1; % The total duration of the incoming signal in seconds
%% INPUT SIGNALS
t = linspace(0, totalTime, fs * totalTime).'; % Samples till total time

tau2Signal = d / c * cos(theta); % Time delay to mic 2 for signal
tau2Noise = d / c * cos(thetaNoise); % Time delay to mic 2 for noise

noise1 = 4 * sin(2 * pi * freqNoise * t) + noise_amp * randn(totalTime * fs, 1); % Unwanted signal and white noise input to mic 1
noise2 = 4 * sin(2 * pi * freqNoise * (t - tau2Noise)) + noise_amp * randn(totalTime * fs, 1); % Unwanted signal and white noise input to mic 2

signal1 = sin(2 * pi * freq * t) + noise1 ;
signal2 = sin(2 * pi * freq * (t - tau2Signal)) + noise2 ;

noise = [noise1, noise2];
signal = [signal1, signal2];

signal1 = data1(1000:201000);


%% CALCULATING  THE NOISE  CORRELATION MATRIX
nb_frames = floor((length(signal1) - samplesptf) / (samplesptf/2));
Rnoise_cor = zeros(2, 2, L / 2 + 1, 11); % preallocation for speed
win = [sqrt(hanning(samplesptf)), sqrt(hanning(samplesptf))]; % We make use of the Hann windowing function here
for J = 1 : 10 + 1 % J is a time frame index. The autocorrelation matrix is computed over the first 10 time frames
    
    % Dividing noise signals in time frames and computing its fft
    
    frame_noise = noise((samplesptf / 2) * (J - 1) + 1 : (samplesptf / 2) * (J - 1) + samplesptf, :).*(win); % Defines the rows of matrix noise
                                                                                      % that are included in time frame I.
    fft_noise = fft(frame_noise, L);
    fft_noise([1, L / 2 + 1], :) = real(fft_noise([1, L / 2 + 1], :));
    part1 = fft_noise(1 : L / 2 + 1, :);

    for I = 1 : L / 2 + 1 % I is the time index
        Rnoise_cor(1, 1, I, J) = abs(part1(I, 1)).^2; % part1(.,1)=fft_noise mic 1 and each row of part1 corrsponds to a time value I
        Rnoise_cor(2, 2, I, J) = abs(part1(I, 2)).^2; % part1(.,2)=fft_noise mic 2
        Rnoise_cor(1, 2, I, J) = part1(I, 1) * conj(part1(I, 2));
        Rnoise_cor(2, 1, I, J) = part1(I, 2) * conj(part1(I, 1));
    end

end
Rnoise_cor = mean(Rnoise_cor, 4); % The auto correlation matrix R is taken 
                                  % as the mean of the Rs over the first 10 time frames
                                  % here the time frame index is J and it
                                  % is the 4th dimension
                                  % Rnoise_cor is a 3dimensional matrix,
                                  % the third simension being time

%% FFT, APPLYING WEIGTHS AND RECONSTRUCTING THE OUTPUT SIGNAL
fft_signal=zeros(L, nb_frames+1); % preallocating for speed
fft_beamformed_signal=zeros(L, nb_frames+1);
fft_beamformed_signal_ptf = zeros(L, 1);
beamformed_signal = zeros(size(signal1(:, 1))); % Initialises the vector in which the output will be saved
w_time=zeros(N,L/2+1);
for J = 1 : nb_frames + 1;
    
    % Dividing total signal in time frames and computing its fft
    % Recall win = [sqrt(hanning(samplesptf)), sqrt(hanning(samplesptf))];
    frame_signal = signal((samplesptf / 2) * (J - 1) + 1 : (samplesptf / 2) * (J - 1) + samplesptf, :).*(win);
    
    fft_signal_ptf = fft(frame_signal, L); % ff per time frame
    fft_signal_ptf([1, L / 2 + 1], :) = real(fft_signal_ptf([1, L / 2 + 1], :));
    part1 = fft_signal_ptf(1 : L / 2 + 1, :);
    fft_signal_ptf = [part1 ; conj(flipud(part1(2 : end - 1, :)))];
    
    fft_signal( :, J) = fft_signal_ptf( : , 1); % save the fft for each time frame in fft_signal_mat. size Lx(number of time frames)
    
    % Beamforming : computing the N weights for every time frame
    for I = 0 : L/2
        fCenter  =  I*fs/L ;
        gamma_n = -1i * 2 * pi * fCenter * d * cos(theta) / c; % The phase shift of the signal in the frequency domain equivalent to time delay tau in the time domain
                                                      % 1i replaces j as the complex number to improves speed and robustness
        %%A_n = 1 / N;
        C = [1; exp(gamma_n)];

        w  = (Rnoise_cor(:, :, I + 1) \ C) / ((C' / Rnoise_cor(:, :, I + 1)) * C);
        w = conj(w);
        w_time(:, I + 1) = w; % saving the weights for the polar plot

        fft_beamformed_signal_ptf(I + 1) = w.'* fft_signal_ptf(I + 1, :).';
    end

    fft_beamformed_signal(:, J) = fft_beamformed_signal_ptf;
    fft_beamformed_signal_ptf = fft_beamformed_signal_ptf(1 : L / 2 + 1);
    fft_beamformed_signal_ptf([1, L / 2 + 1], :) = real(fft_beamformed_signal_ptf([1, L / 2 + 1], :));
    fft_beamformed_signal_ptf = [fft_beamformed_signal_ptf ; flipud(conj(fft_beamformed_signal_ptf(2 : end - 1)))];
    td_estimate_signal = real( ifft(fft_beamformed_signal_ptf(1 : L)));
    beamformed_signal((samplesptf / 2) * (J - 1) + 1 : (samplesptf / 2) * (J - 1) + samplesptf) = beamformed_signal((samplesptf / 2)...
        * (J - 1) + 1 : (samplesptf / 2) * (J - 1) + samplesptf) + td_estimate_signal(1 : samplesptf) .* (sqrt(...
        hanning(samplesptf)));
end

%% ARRAY GAIN
% Can measure the speech enhancement by the array gain. The Array gain is the ratio of
% output signal-to-interference-plus-noise ratio (SINR) to input SINR.
% ArrayGain = mean((interference + random noise).^2)/mean((total filtered output - desired signal).^2))
ArrayGain = pow2db(mean((noise1).^2)/mean((beamformed_signal - sin(2 * pi * freq * t)).^2)) 
%% PLOTS
% Plot of signals in the frequency domain

subplot(2,1,1)
plot(linspace(1, fs, L), 10 * log10(mean(abs(fft_signal).^2, 2)),'b');
hold  on
plot(linspace(1, fs, L), 10 * log10(mean(abs(fft_beamformed_signal).^2, 2)),'r');
title({['Direction of arrival of unwanted signal = ',num2str(thetaNoise*180/pi),'°, Beamforming gain = ', num2str(ArrayGain),'dB'],'', ['Spectrum plot of the results']})
legend('Input signal','Beamformed output' )
axis([0 3000 0 70]);
xlabel('frequency (in Hz)');
ylabel('magnitude (in dB)');

% Plot of signals in the time domain
% Recall t = linspace(0, totalTime, totalTime * fs);
subplot(2,1,2) 
plot(linspace(0, totalTime, length(signal1)), signal1,'b');
hold  on
plot(linspace(0, totalTime, length(beamformed_signal)), beamformed_signal,'r');
plot (t, sin(2 * pi * freq * t),'--k');
legend('Input signal', 'Beamformed output', 'Signal of interest')
title('Time plot of the results')
axis([0.300 0.308 -6 6]);
xlabel('time (in s)');
ylabel('amplitude');

%% Polar directivity pattern of microphone array for DAS weight vector
% the polar response plot is obtained thanks to the phased array matlab toolbox
% using the weights computed above, in order to obtain more precise graphs
 figure;
 Mic = phased.OmnidirectionalMicrophoneElement('FrequencyRange',[200 5000]);
 Array = phased.ULA(N,'ElementSpacing',d,'Element',Mic);
 
 freq_to_plot = [freq freqNoise];
 W_n = mean(w_time,2); % average of the weights obtained for each time frame
 polarbin = zeros(1, length(freq_to_plot));
 for I = 1 : length(freq_to_plot);
     polarbin(I) = floor(freq_to_plot(I) / fs * L);
     subplot(ceil(length(freq_to_plot) / 2), 2, I)
     plotResponse(Array, freq_to_plot(I), c, 'Format', 'Polar', 'Unit', 'mag','RespCut','Az','CutAngle',0, 'Weights', w_time(:, polarbin(I))); % Default parameters are use of azimutal angle 
     xlabel('');
     ylabel('')
     title({['Frequency =', num2str(freq_to_plot(I)),'Hz, Main beam direction \theta = ',num2str(theta*180/pi),'°, Direction of arrival of interference = ',num2str(thetaNoise*180/pi),'°']})                                                                                                          % as variable and elevation and unit is decibels 0
                                                                                                                % (w(polarbin(I), :))' used to extract the weights corresponding to the frequency studied 
                                                                                                                % the function requires a column vector
 end; 
 
