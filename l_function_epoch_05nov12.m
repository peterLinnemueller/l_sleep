function ret = l_function_epoch_05nov12(S)
% function ret = l_function_epoch_05nov12(currDir, anaDir, workDir, DATA_FILE,
% PSI_START_MS, PSI_END_MS, CONDITION, OVERLAP, BC)
% Leo: trialdefinition and epoching
% --------------------
% Version: v0.7, 05nov12, leo

workDir      = S.workDir;
anaDir       = S.anaDir;
currDir      = S.currDir;
DATA_FILE    = S.DATA_FILE;
PSI_START_MS = S.PSI_START_MS;
PSI_END_MS   = S.PSI_END_MS;
CONDITION    = S.CONDITION;
OVERLAP      = S.OVERLAP;
BC           = S.BC;

fprintf(['\nexecuting l_function_epoch_19oct12(\n\tcurrDir=%s,',...
  '\n\tworkDir=%s,\n\tanaDir=%s,\n\tDATA_FILE=%s, \n\tPSI_START_MS=%d,',...
  '\n\tPSI_END_MS=%d, \n\tCONDITION=%s, \n\tOVERLAP=%d, \n\tBC=%d)\n'],...
  currDir,workDir,anaDir,DATA_FILE, PSI_START_MS, PSI_END_MS, CONDITION,...
  OVERLAP,BC);


% try 
  mkdir(workDir, anaDir);
% mkdir('test');
% catch err
%   mkdir(workDir, anaDir);
%   fprintf('\creating new analysis directory %s...\n', [workDir,'/',anaDir]);
%   cd(anaDir);
% end  
  
fprintf('\n...moving to %s\n',pwd);
fprintf('\nstart processing...\n');

%  =============
%% load data set:
D = spm_eeg_load(spm_select('FPList',workDir,DATA_FILE))

%% create trial definitions:
S=[];
S.workDir       = workDir;
S.anaDir        = anaDir;
S.currDir       = currDir;
S.D             = D;
S.PSI_START_MS  = PSI_START_MS;
S.PSI_END_MS    = PSI_END_MS;

% write trial definition files for all conditions + (non)overlap:
tic
ret = l_function_create_trialdef_05nov12(S);
toc


% =========================================================
% =========== epoching: ===================================
% =========================================================

fprintf('\ndoing epoching now...\n');

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
%   epochinfo=load(spm_select('FPList',workDir,['^trials_spindels_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_',sOVERLAP,'_',num2str(D.fsample),'Hz.*_Cz.mat$'])); % CAVE: parfor needs load to put result into struct for transparency!!
epochinfo=load(spm_select('FPList',fullfile(workDir,anaDir),['^trials_spindels_psi',num2str(PSI_START_MS),'_',num2str(PSI_END_MS),'_',sOVERLAP,'_',num2str(D.fsample),'Hz_',CONDITION,'.mat$']));

S.epochinfo.trl = epochinfo.trl;
S.epochinfo.conditionlabels = epochinfo.conditionlabels;
S.epochinfo.padding = 0; % how does this work??? 50;%[50;50;50;50]

S.reviewtrials = 0;
S.save = 0;

tic
eD = spm_eeg_epochs(S);
toc


% move new meeg-object to anaDir (i.e. copy and delete old copy):
[dummy, fname, dummy] = fileparts(eD.fname);
Dnew = clone(eD, fullfile(workDir,anaDir,fname));
[r, msg] = copyfile(fullfile(eD.path, eD.fnamedat), ...
    fullfile(Dnew.path, Dnew.fnamedat), 'f');
if ~r
    error(msg);
end
Dnew.save;

delete(fullfile(eD.path,eD.fname)); 
delete(fullfile(eD.path,eD.fnamedat));





% =========================================================
% =========== baseline correction: ========================
% =========================================================

if BC==1 % do bc?
  
  fprintf('\ndoing baseline correction now...\n');
  
  load([workDir,'/spindleInfo.mat'],'spindleInfo')
  %   spindelDur=importdata('spindel_durations.txt');
  
  % find right sensor (CONDITION) index in spindleInfo struct
  ind = 0;
  for i=1:size(spindleInfo,2)
    if strcmp(CONDITION,spindleInfo(i).sensor)
      ind = i;
    end
  end
  
  spindleDurOrig = str2num(cell2mat(spindleInfo(ind).duration')); %duration in seconds
  % ------
  % read peakOnsets:
  dataPeak = spindleInfo(ind).peakOnsets'; % peakOnsets are chararray with rows
  % of different length => cell2mat()
  % is not working here! (duration has
  % only rows of common length =>
  % simpler solution(see above)...
  spindlePeakOrig=[];
  for k=1:size(dataPeak,1)
    spindlePeakOrig(k)= str2num(cell2mat(dataPeak(k)));
  end
  spindlePeakOrig=spindlePeakOrig';
  % ------
  
  % find indices of used spindles (depends on epoching params):
  ind2=[];
  for i=1:size(eD.trialonset,2)
    % 'round' might cause few misses!:
    if find(round(eD.trialonset(i)-eD.timeonset) == round(spindlePeakOrig))
      ind2=[ind2; find(round(eD.trialonset(i)-eD.timeonset) == round(spindlePeakOrig))]
    end
  end
  
  spindleDur = spindleDurOrig(ind2);
  
  spindleDurMax=max(spindleDur); %taken as common offset to all events for following bc
  
  bcTimeEnd=(eD.timeonset*1000 + round((spindleDurMax*1000)/2)); %in ms
  bcTimeStart=bcTimeEnd-1000; %in ms
  
  if bcTimeStart<eD.timeonset*1000
    fprintf('\nCAVE: baseline start is negative (%dms)!!!\n\n',bcTimeStart);
  end
  fprintf('\nbc: psi=%d to %dms\n\n',bcTimeStart, bcTimeEnd);
  %  __________________________________________________________________________
  %  spm_eeg_bc
  %   'Baseline Correction' for M/EEG data
  %   FORMAT D = spm_eeg_bc(S)
  %
  %   S        - optional input struct
  %   (optional) fields of S:
  %     S.D    - MEEG object or filename of M/EEG mat-file with epoched data
  %     S.time - 2-element vector with start and end of baseline period [ms]
  %     S.save - save the baseline corrected data in a separate file [default: true]
  %     S.updatehistory - update history information [default: true]
  %
  %   D        - MEEG object (also saved on disk if requested)
  %  __________________________________________________________________________
  %
  %   Subtract average baseline from all M/EEG and EOG channels
  %  __________________________________________________________________________
  %   Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
  
  S=[];
  S.D=eD;
  S.time=[bcTimeStart, bcTimeEnd] %ms
  S.save=true;
  S.updatehistory=true;
  
  beD=spm_eeg_bc(S);
  
  
end % bc

fprintf('finished %s!\n',pwd);
cd(currDir)
ret=1
