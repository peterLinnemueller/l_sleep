function ret = l_function_df_19oct12(currDir, workDir, hp_freq, downsample_freq)
% function ret = l_function_df_19oct12(currDir,workDir,hp_freq_downsample_freq)
% Leo: basic preprocessing (HP-filter, downsample) of raw converted spm8 file

 cd(workDir)
  fprintf('\nexecuting l_function_df_19oct12(currDir=s%,workDir=%s,hp_freq=%d,downsample_freq=%d',currDir,workDir,hp_freq,downsample_freq); 
  fprintf('\n...moving to %s\n',pwd);
  fprintf('\nstart processing...\n');
%  =============
  %% load data set
  D = spm_eeg_load(spm_select('FPList',workDir,'^spm8_subj.*.mat$'))

  
  %% correct channeltypes
  %  CAVE: not checked if channellabel assigments (derived from subj01) are valid for all datasets!!!!!!
  %  set used EEG/EOG/EMG/ECG channels to their respective channeltype. set
  %  unused channels of type 'EEG' to 'Other'.
  eegChannels.chanNumber=[306:313,362:365];
  eegChannels.chanLabel={'Cz','Fz','C3','C4','F3','F4','A1','A2','EOGhor','EOGver','EMG','ECG'};
  eegChannels.chanType={'EEG','EEG','EEG','EEG','EEG','EEG','EEG','EEG','EOG','EOG','EMG','ECG'}
  
  D=D.chantype(D.meegchannels('EEG'),'Other');
  D=D.chantype(eegChannels.chanNumber,eegChannels.chanType);
  D=D.chanlabels(eegChannels.chanNumber,eegChannels.chanLabel);
  D.save;

  channelTypesOrig=D.chantype;

  fprintf('\nLeo: Corrected for missing EEG/EOG/EMG/ECG channel label/type...\n',...
         'CAVE:not checked if channellabel assigments (derived from subj01) are valid for all datasets!!!!!!\n');

%% 1. filter HP>1Hz ( HP-filtering necessary before downsampling because of edge effects!)
  %  ____________________________________________
  % >> help spm_eeg_filter
  %   Filter M/EEG data
  %   FORMAT D = spm_eeg_filter(S)
  %  
  %   S           - input structure (optional)
  %   (optional) fields of S:
  %     S.D       - MEEG object or filename of M/EEG mat-file
  %     S.filter  - struct with the following fields:
  %        type       - optional filter type, can be
  %                      'but' Butterworth IIR filter (default)
  %                      'fir' FIR filter using Matlab fir1 function
  %        order      - filter order (default - 5 for Butterworth)
  %        band       - filterband [low|high|bandpass|stop]
  %        PHz        - cutoff frequency [Hz]
  %        dir        - optional filter direction, can be
  %                     'onepass'         forward filter only
  %                     'onepass-reverse' reverse filter only, i.e. backward in time
  %                     'twopass'         zero-phase forward and reverse filter
  %                  
  %   D           - MEEG object (also written to disk)
  %  ____________________________________________

  S = [];
  S.D = D;
  S.filter.band = 'high';
  S.filter.PHz = hp_freq;

  fprintf('\nLeo: HP filtering (cutoff: %dHz)...\n',hp_freq);
         
  tic
  fD = spm_eeg_filter(S);
  toc

  D = fD;

  %  =============
  %% 2. downsample
  %  ____________________________________________
  % >> help spm_eeg_downsample
  %   Downsample M/EEG data
  %   FORMAT D = spm_eeg_downsample(S)
  %  
  %   S               - optional input struct
  %   (optional) fields of S:
  %     S.D           - MEEG object or filename of M/EEG mat-file
  %     S.fsample_new - new sampling rate, must be lower than the original one
  %     S.prefix      - prefix of generated file
  %  
  %   D               - MEEG object (also written on disk)
  %  ____________________________________________
  S = [];
  S.D = D;
  S.fsample_new = downsample_freq;
  S.prefix = 'd';

  fprintf('\nLeo: downsampling to %dHz...\n',downsample_freq);
  
  tic
  dfD = spm_eeg_downsample(S);
  toc

  D = dfD;


  fprintf('\nLeo: finished %s!\n',pwd);
  cd(currDir)
  ret = 1