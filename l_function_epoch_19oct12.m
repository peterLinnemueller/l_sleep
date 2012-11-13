function ret = l_function_epoch_19oct12(currDir, workDir, DATA_FILE, PSI_START_MS, PSI_END_MS, OVERLAP)
% function ret = l_function_epoch_19oct12(currDir, workDir, DATA_FILE, PSI_START_MS, PSI_END_MS, OVERLAP)
% Leo: trialdefinition and epoching

 cd(workDir)

  fprintf(['\nexecuting l_function_epoch_19oct12(\n\tcurrDir=%s,',...
          '\n\tworkDir=%s,\n\tDATA_FILE=%s, \n\tPSI_START_MS=%d,',...
          '\n\tPSI_END_MS=%d, \n\tOVERLAP=%d)\n'],currDir,workDir,...
          DATA_FILE, PSI_START_MS, PSI_END_MS, OVERLAP);
  fprintf('\n...moving to %s\n',pwd);
  fprintf('\nstart processing...\n');
  
  %  =============
  %% load data set:
  D = spm_eeg_load(spm_select('FPList',workDir,DATA_FILE))

  %% create trial definitions:
  S=[];
  S.workDir       = workDir;
  S.currDir       = currDir;
  S.D             = D;
  S.PSI_START_MS  = PSI_START_MS;
  S.PSI_END_MS    = PSI_END_MS;
  S.OVERLAP       = OVERLAP;
  
  %   ret = l_function_create_trialdef_19oct12(D, PSI_START_MS, PSI_END_MS, OVERLAP)
  tic
  % write trial definition files for all conditions + (non)overlap:
  ret = l_function_create_trialdef_19oct12(S);  
  toc
  %  =====
  %% epoch

  %  ____________________________________________
  % help spm_eeg_epochs
  %   Epoching continuous M/EEG data
  %   FORMAT D = spm_eeg_epochs(S)
  %  
  %   S                     - input structure (optional)
  %   (optional) fields of S:
  %     S.D                 - MEEG object or filename of M/EEG mat-file with
  %                           continuous data
  %     S.bc                - baseline-correct the data (1 - yes, 0 - no).
  %  
  %   Either (to use a ready-made trial definition):
  %     S.epochinfo.trl             - Nx2 or Nx3 matrix (N - number of trials)
  %                                   [start end offset]
  %     S.epochinfo.conditionlabels - one label or cell array of N labels
  %     S.epochinfo.padding         - the additional time period around each
  %                                   trial for which the events are saved with
  %                                   the trial (to let the user keep and use
  %                                   for analysis events which are outside) [in ms]
  %  
  %   Or (to define trials using (spm_eeg_definetrial)):
  %     S.pretrig           - pre-trigger time [in ms]
  %     S.posttrig          - post-trigger time [in ms]
  %     S.trialdef          - structure array for trial definition with fields
  %       S.trialdef.conditionlabel - string label for the condition
  %       S.trialdef.eventtype      - string
  %       S.trialdef.eventvalue     - string, numeric or empty
  %  
  %     S.reviewtrials      - review individual trials after selection
  %     S.save              - save trial definition
  %  
  %   Output:
  %   D                     - MEEG object (also written on disk)
  %  __________________________________________________________________________
  %  
  %   spm_eeg_epochs extracts single trials from continuous EEG/MEG data. The
  %   length of an epoch is determined by the samples before and after stimulus
  %   presentation. One can limit the extracted trials to specific trial types.
  %  ____________________________________________
  S = [];
  S.D = D;
  S.bc = 0;

  % load(spm_select('FPList',workDir,'^trials_.*all.mat$'));
%   epochinfo=load(spm_select('FPList',workDir,'^trials_spindels.*_Cz.mat$')); % CAVE: parfor needs load to put result into struct for transparency!!
  sOVERLAP = 'overlap';
  if OVERLAP==0
    sOVERLAP = 'nonoverlap';
  end
  epochinfo=load(spm_select('FPList',workDir,['^trials_spindels_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_',sOVERLAP,'_',num2str(D.fsample),'Hz.*_Cz.mat$'])); % CAVE: parfor needs load to put result into struct for transparency!!

  S.epochinfo.trl = epochinfo.trl;
  S.epochinfo.conditionlabels = epochinfo.conditionlabels; 
  S.epochinfo.padding = 0 % how does this work??? 50;%[50;50;50;50]

  S.reviewtrials = 0;
  S.save = 0;

  tic
  eD = spm_eeg_epochs(S)
  toc 

  D = eD;

%   % baseline correction
%   spindelDur=importdata('spindel_durations.txt');
%   spindelDurMax=max(spindelDur); %taken as common offset to all events for following bc
%   bcTimeEnd=(-pE.timeonset*1000 - round((spindelDurMax/2)*1000));
%   bcTimeStart=bcTimeEnd-1000;
%   if bcTimeStart<0
%     sprintf('\nCAVE: baseline start is negative (%dms)!!!\n\n',bcTimeStart)
%   end
% 
%   %  __________________________________________________________________________
%   %  spm_eeg_bc
%   %   'Baseline Correction' for M/EEG data
%   %   FORMAT D = spm_eeg_bc(S)
%   %  
%   %   S        - optional input struct
%   %   (optional) fields of S:
%   %     S.D    - MEEG object or filename of M/EEG mat-file with epoched data
%   %     S.time - 2-element vector with start and end of baseline period [ms]
%   %     S.save - save the baseline corrected data in a separate file [default: true]
%   %     S.updatehistory - update history information [default: true]
%   %  
%   %   D        - MEEG object (also saved on disk if requested)
%   %  __________________________________________________________________________
%   %  
%   %   Subtract average baseline from all M/EEG and EOG channels
%   %  __________________________________________________________________________
%   %   Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
% 
%   S=[];
%   S.D=fdfpE;
%   S.time=[bcTimeStart, bcTimeEnd] %ms
%   S.save=true;
%   S.updatehistory=true;
% 
%   bfdfpE=spm_eeg_bc(S);



  fprintf('finished %s!\n',pwd);
  cd(currDir)
ret=1
