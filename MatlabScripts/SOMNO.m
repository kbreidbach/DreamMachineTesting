%% clear workspace, command window and close all figures
clearvars;
close all;
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
cfg         = [];
cfg.dataset = 'hsoa_removedfilters.edf'; % adjust participant acronym
Filename    = erase(cfg.dataset,'.edf');
Participant = erase(Filename,'_removedfilters');

%% Segmenting Data into Trials
% The segmenting is done previous to preprocessing because ft_redefinetrial
% does not have the option to shorten data set to 200 trials.
% The difference of the result of the functions ft_definetrial and ft_redefinetrial 
% does not affect the data analysis 
cfg.trialdef.ntrials = 200; % desired number of trials
cfg.trialdef.length  = 30;
cfg.trialdef.overlap = 0;
cfg = ft_definetrial(cfg);

%% Post-processing
cfg.bpfilter   = 'yes';
cfg.bpfreq     = [0.3 16]; % apply bandpass filter of 0.3-16 Hz
cfg.continuous = 'yes';
cfg.channel    = {'F3', 'F4', 'C3', 'C4', 'O1', 'O2', 'E1', 'E2'}; % choose EEG & EOG channels for preprocessing

data_final = ft_preprocessing(cfg);

%% visually inspect the data
cfg            = [];
cfg.viewmode   = 'vertical';
cfg.blocksize  = 30; % show 30 sec intervals
cfg.ylim       = [-200 200]; % amplitude limit for better comparison
ft_databrowser(cfg, data_final);

%% power analysis of trial-based data (in frequency domain) 
cfg            = [];
cfg.output     = 'pow';
cfg.channel    = {'all', '-E1', '-E2'}; % keep only EEG data
cfg.method     = 'mtmfft'; % use mtmfft as method for calculating the spectra
cfg.taper      = 'dpss'; % use dpss tapers (amount of tapers determined by ft_freqanalysis)
cfg.tapsmofrq  = 0.5; % spectral smoothing *2 = 1 Hz
cfg.foi        = 0.5:0.05:16; % in 0.05 Hz steps
cfg.keeptrials = 'yes';
freq_epoched = ft_freqanalysis(cfg, data_final);

%% constructing time component and adding the information to power spectrum
begsample = data_final.sampleinfo(:,1);
endsample = data_final.sampleinfo(:,2);
time      = ((begsample+endsample)/2) / data_final.fsample;

freq_continuous           = freq_epoched;
freq_continuous.powspctrm = permute(freq_epoched.powspctrm, [2, 3, 1]); % change order to labels x freq x trials
freq_continuous.dimord    = 'chan_freq_time';
freq_continuous.time      = time; % add the description of the time dimension

%% plot time-frequency spectrogram over all trials
figure('Name', strcat('SOMNO HD eco:  ', Participant))
cfg              = [];
cfg.baseline     = [min(freq_continuous.time) max(freq_continuous.time)]; % baseline window
cfg.baselinetype = 'db'; % take decibel as baselinetype (computation done in ft_freqbaseline)
cfg.zlim         = [-10 10];
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
delta          = [];
delta.label    = freq_continuous_delta.label;
delta.time{1}  = freq_continuous_delta.time;
delta.trial{1} = squeeze(freq_continuous_delta.powspctrm)';

theta          = [];
theta.label    = freq_continuous_theta.label;
theta.time{1}  = freq_continuous_theta.time;
theta.trial{1} = squeeze(freq_continuous_theta.powspctrm)';

alpha          = [];
alpha.label    = freq_continuous_alpha.label;
alpha.time{1}  = freq_continuous_alpha.time;
alpha.trial{1} = squeeze(freq_continuous_alpha.powspctrm)';

sigma          = [];
sigma.label    = freq_continuous_sigma.label;
sigma.time{1}  = freq_continuous_sigma.time;
sigma.trial{1} = squeeze(freq_continuous_sigma.powspctrm)';

