%% load data
clear variables;
close all;
clc;

restoredefaultpath
addpath('/Users/pariasamimi/fieldtrip')
addpath('/Users/pariasamimi/Downloads/MATLAB/xdf')
addpath('/Users/pariasamimi/fieldtrip/external/brewermap')
addpath('/Users/pariasamimi/fieldtrip/external/matplotlib')
addpath('/Users/pariasamimi/fieldtrip/external/cmocean')
addpath('/Users/pariasamimi/fieldtrip/utilities/private');
addpath('/Applications/brainstorm3')
addpath('/Users/pariasamimi/Documents/PhD/Kyra Project/data/25_01_2023 ');
dir_tmp='/Users/pariasamimi/Documents/PhD/Kyra Project/data/25_01_2023 ';
A=cd(dir_tmp);
ft_defaults

%% define trials edf file
cfg            = [];
cfg.lpfreq        = 50;                %lowpass  frequency in Hz
cfg.hpfreq        = 2;              %highpass frequency in Hz
cfg.dataset    = 'Massia.edf';
namE=erase(cfg.dataset,'.edf'); %% for removing the edf name
cfg.continuous = 'yes';
cfg.channel    = 'all';
data           = ft_preprocessing(cfg);
save(strcat((namE),'_Preprocessing','.mat'),'data') % save the trial definition
% %% visually inspect the data
% cfg            = [];
% cfg.viewmode   = 'vertical';
% ft_databrowser(cfg, data);
%% define trials csv file
Filename='Massia';
YY=readtable('Massia.csv');
y=table2array(YY);
dy=y(:,3:26);
Y=dy';
t=y (:,1);
T=t'/256; %s
% header
Data.hdr.Fs=250;
Data.hdr.nChans=24;
Data.hdr.label=[{'FP1'} {'FPZ'} {'FP2'}  {'F7'} { 'F3'}  {'Fz'}  {'F4'}  {'F8'}  {'M1'}  {'T7'}  {'C3'}  {'CZ'}  {'C4'}  {'T8'}  {'M2'} {'P7'} {'P3'} {'Pz'} {'P4'} {'P8'} {'POZ'} {'O1'} {'OZ'} {'O2'}]';
Data.trial{1, 1}=Y;
Data.hdr.nSamples=length(dy);
Data.hdr.nSamplesPre=0;
Data.hdr.nTrials=1;
Data.hdr.chantype=[{'EEG'} {'EEG'} {'EEG'}  {'EEG'} { 'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'}  {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'} {'EEG'}]';
Data.hdr.chanunit=[{'unknown'} {'unknown'} {'unknown'}  {'unknown'} { 'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'}  {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'} {'unknown'}]';
Data.label=[{'FP1'} {'FPZ'} {'FP2'}  {'F7'} { 'F3'}  {'Fz'}  {'F4'}  {'F8'}  {'M1'}  {'T7'}  {'C3'}  {'CZ'}  {'C4'}  {'T8'}  {'M2'} {'P7'} {'P3'} {'Pz'} {'P4'} {'P8'} {'POZ'} {'O1'} {'OZ'} {'O2'}]';
Data.time{1, 1}= T;
Data.cfg.trl=[1 Data.hdr.nSamples 0];
Data.fsample=250;
Data.sampleinfo=[1 Data.hdr.nSamples];
Data.cfg.headerformat='csv';

%% preprocessing
cfg            = [];
cfg.lpfreq        = 50;                %lowpass  frequency in Hz
cfg.hpfreq        = 2;              %highpass frequency in Hz
%cfg.refchannel      = subjectdata.refchannel; % {'TP10'};

preproc = ft_preprocessing(cfg, Data);
save(strcat((Filename),'_Data_Preprocessing','.mat'),'Data') % save the trial definition
%% visually inspect the data
cfg            = [];
cfg.linewidth =1;
cfg.channel         = {'all','-CZ','-T8','-Pz','-P4','-P8','-POZ','-O1','-OZ','-O2'}; % remove bad channels
cfg.viewmode   = 'vertical';
ft_databrowser(cfg, preproc);