%% clear workspace and command window
clearvars -except delta theta alpha sigma Participant all_corr outlier_trials freq_epoched all_pow All_pow;
clc;

%% path 
restoredefaultpath
addpath('C:\Users\kbrei\Downloads\fieldtrip-20230125\fieldtrip-20230125')
addpath('C:\Users\kbrei\Downloads\fieldtrip-20230125\fieldtrip-20230125\external\brewermap')
addpath('C:\Users\kbrei\Downloads\fieldtrip-20230125\fieldtrip-20230125\external\matplotlib')
addpath('C:\Users\kbrei\Downloads\fieldtrip-20230125\fieldtrip-20230125\external\cmocean')
addpath('C:\BA\DreamMachineTesting\Recordings');
dir_tmp='C:\BA\DreamMachineTesting\Recordings';
A=cd(dir_tmp);
ft_defaults

%% loading data set
Filename= sprintf('ts_tim_%s.csv', Participant);
YY=readtable(Filename);
y=table2array(YY);

% change directory
dir_tmp='C:\BA\DreamMachineTesting';
A=cd(dir_tmp);

%% aligning DreamMachine recording start with SOMNO HD eco recording start
% shortening the data set to 100 minutes
detail_file = 'Details.xlsx'; % get correct timestamps for each Participant from Details.xlsx 
sheet = 'Length of measurements';
tableData = readtable(detail_file, 'Sheet', sheet);
rowIndex = find(strcmp(tableData.Dataset, Participant)); % find row index where 'Dataset' matches current 'Participant'
startEndValue = tableData.StartToEnd(rowIndex); % access 'StartToEnd' column value for the matched row
dy=y(str2num(startEndValue{1,1}),3:26); % shorten data set to 100 minutes
t=y(str2num(startEndValue{1,1}),2); % shorten data set to 100 minutes
%dy=y(:,3:26); % used for Aligning the Start of the Measurements instead of line 28
%t=y(:,2); % used for Aligning the Start of the Measurements instead of line 29
t=t/4+1; % getting the correct sample number

%% Interpolating missing Data
nan_indices = find(isnan(dy));
% perform interpolation if data set contains missing values
if ~isempty(nan_indices)
    non_nan_indices = setdiff(1:(length(dy)*24), nan_indices);
    dy = interp1(non_nan_indices, dy(non_nan_indices), 1:(length(dy)*24), 'spline'); % use interpolation method 'spline' for smooth curve estimation
    dy = reshape(dy, [], 24); % bring dy back into its original format
end

%% bringing Data into readable format
Y=dy';
T=t'/250; % sec
Data.hdr.Fs=250;
Data.hdr.nChans=24;
Data.hdr.label=[{'M1'} {'E1'} {'F3'}  {'C3'} {'O1'} {'O2'} {'C4'} {'F4'} {'E2'} {'M2'} {'EMG1'} {'ECG1'} {'EMGref'} {'ECG2'} {'EMG2'} {'Gnd'} {'Cz'} {'0'} {'1'} {'2'} {'3'} {'4'} {'5'} {'6'}]';
Data.hdr.nSamples=length(dy);
Data.hdr.nSamplesPre=0;
Data.hdr.nTrials=1;
Data.hdr.chantype=[{'EEG'} {'EEG'} {'EEG'}  {'EEG'} { 'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'}]';
Data.hdr.chanunit=[{'unknown'} {'unknown'} {'unknown'}  {'unknown'} { 'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'}]';
Data.label=[{'M1'} {'E1'} {'F3'} {'C3'} { 'O1'} {'O2'} {'C4'} {'F4'} {'E2'} {'M2'} {'EMG1'} {'ECG1'} {'EMGref'} {'ECG2'} {'EMG2'} {'Gnd'} {'Cz'} {'0'} {'1'} {'2'} {'3'} {'4'} {'5'} {'6'}]';
Data.trial{1,1}=Y;
Data.time{1,1}= T;
Data.cfg.trl=[1 Data.hdr.nSamples 0]; 
Data.fsample=250;
Data.sampleinfo=[1 Data.hdr.nSamples];
Data.cfg.headerformat='csv';

%% Post-processing
cfg            = [];
cfg.bpfilter   = 'yes';
cfg.bpfreq     = [0.3 16]; % apply bandpass filter of 0.3-16 Hz
cfg.continuous = 'yes';
cfg.channel    = {'F3', 'F4', 'C3', 'C4', 'O1', 'O2', 'Cz', 'E1', 'E2'}; % choose EEG & EOG channels for preprocessing
Data_proc = ft_preprocessing(cfg, Data);

%% Segmenting Data into Trials
cfg = [];
cfg.trials  = 'all'; % only 200 trials available
cfg.length  = 30; % second
cfg.overlap = 0; % between 0 and 1
Data_final = ft_redefinetrial(cfg, Data_proc);

%% reorder EEG & EOG channels to match order of SOMNO HD eco
order = [3, 6, 4, 5, 2, 7, 1, 8, 9];
Data_final.hdr.label = Data_final.hdr.label(order, :);
Data_final.label = Data_final.label(order, :);
for trls= 1:200
    Data_final.trial{1,trls} = Data_final.trial{1,trls}(order, :);
end

%% visually inspect the data
cfg           = [];
cfg.viewmode  = 'vertical';
cfg.blocksize = 30; % show 30 sec intervals
cfg.channel   = {'all', '-Cz'};
cfg.ylim      = [-200 200]; % amplitude limit for better comparison
ft_databrowser(cfg, Data_final);

%% power analysis of trial-based data (in frequency domain)
cfg            = [];
cfg.output     = 'pow';
cfg.channel    = {'all' '-Cz', '-E1', '-E2'};
cfg.method     = 'mtmfft'; % use mtmfft as method for calculating the spectra
cfg.taper      = 'dpss'; % use dpss tapers (amount of tapers determined by ft_freqanalysis)
cfg.tapsmofrq  = 0.5; % spectral smoothing *2 = 1 Hz
cfg.foi        = 0.5:0.05:16; % in 0.05 Hz steps
cfg.keeptrials = 'yes';
Freq_epoched = ft_freqanalysis(cfg, Data_final);

%% constructing time component and adding the information to power spectrum
begsample = Data_final.sampleinfo(:,1);
endsample = Data_final.sampleinfo(:,2);
time      = ((begsample+endsample)/2) / Data_final.fsample;

freq_continuous           = Freq_epoched;
freq_continuous.powspctrm = permute(Freq_epoched.powspctrm, [2, 3, 1]); % change order to labels x freq x trials
freq_continuous.dimord    = 'chan_freq_time';
freq_continuous.time      = time;             % add the description of the time dimension

%% plot time-frequency spectrogram over all trials
figure('Name', strcat('DreamMachine:  ', Participant))
cfg                = [];
cfg.baseline       = [min(freq_continuous.time) max(freq_continuous.time)]; % baseline window
cfg.baselinetype   = 'db'; % take decibel as baselinetype (computation done in ft_freqbaseline)
cfg.zlim           = [-10 10];
ft_singleplotTFR(cfg, freq_continuous);

%% get average power over each frequency band
freq_bands = [
  0.5  4    % delta band
  4    8    % theta band
  8   13    % alpha band
  11  16    % sigma band
  ];

cfg                   = [];
cfg.frequency         = freq_bands(1,:);
cfg.avgoverfreq       = 'yes';
freq_continuous_delta = ft_selectdata(cfg, freq_continuous);

cfg                   = [];
cfg.frequency         = freq_bands(2,:);
cfg.avgoverfreq       = 'yes';
freq_continuous_theta = ft_selectdata(cfg, freq_continuous);

cfg                   = [];
cfg.frequency         = freq_bands(3,:);
cfg.avgoverfreq       = 'yes';
freq_continuous_alpha = ft_selectdata(cfg, freq_continuous);

cfg                   = [];
cfg.frequency         = freq_bands(4,:);
cfg.avgoverfreq       = 'yes';
freq_continuous_sigma = ft_selectdata(cfg, freq_continuous);

%% save EEG channel information time and average power per trial for all relevant frequency bands
Delta          = [];
Delta.label    = freq_continuous_delta.label;
Delta.time{1}  = freq_continuous_delta.time;
Delta.trial{1} = squeeze(freq_continuous_delta.powspctrm)';

Theta          = [];
Theta.label    = freq_continuous_theta.label;
Theta.time{1}  = freq_continuous_theta.time;
Theta.trial{1} = squeeze(freq_continuous_theta.powspctrm)';

Alpha          = [];
Alpha.label    = freq_continuous_alpha.label;
Alpha.time{1}  = freq_continuous_alpha.time;
Alpha.trial{1} = squeeze(freq_continuous_alpha.powspctrm)';

Sigma          = [];
Sigma.label    = freq_continuous_sigma.label;
Sigma.time{1}  = freq_continuous_sigma.time;
Sigma.trial{1} = squeeze(freq_continuous_sigma.powspctrm)';