function ret = l_function_create_trialdef_30oct12(S)
% function ret = l_function_create_trialdef_30oct12(D, PSI_START_MS, PSI_END_MS)
% creates trialdef_xxx.mat files for all spindle peak conditions (i.e. 6
% eeg sensor positions) plus control condition in two versions (non-/overlap) 
% within the actual subject folder.
% NB: info is read from spindleInfo.mat file (created by
%     l_function_create_spindleInfos_26oct12.m)
% --------------------
% Version: v0.6, 30oct12, leo

% % testing:
% clear all
% workDir      =  '/data1/sleep/meg/s01/Vp01/subj1_sleep_20090114_01.ds'
% cd(workDir)
% currDir      = workDir;
% D            = spm_eeg_load('dfspm8_subj1_sleep_20090114_01.mat')
% PSI_START_MS = 1400
% PSI_END_MS   = 1400



workDir      = S.workDir;
currDir      = S.currDir;
D            = S.D;
PSI_START_MS = S.PSI_START_MS;
PSI_END_MS   = S.PSI_END_MS;


cd(workDir)

fprintf(['\nexecuting l_function_create_trialdef_26oct12(\n\tworkDir=%s,',...
  '\n\tcurrDir=%s, \n\tD=%s, \n\tPSI_START_MS=%d,',...
  '\n\tPSI_END_MS=%d)\n'], workDir, currDir,...
  D.fname, PSI_START_MS, PSI_END_MS);
fprintf('\n...moving to %s\n',pwd);
fprintf('\nstart processing...\n');

load('spindleInfo.mat','spindleInfo')

% sensorLabels = cellstr(['C3';'C4';'Cz';'F3';'F4';'Fz']);

trlAll=[];
conditionlabelsAll=[];

for i = 1:size(spindleInfo,2) % over conditions i.e. sensors
  data = spindleInfo(i).peakOnsets';
  
  spindles=[];
  for k=1:size(data,1)
    spindles(k)= str2num(cell2mat(data(k)));
  end
  spindles=spindles';
  
  spindleSamples = D.indsample(spindles);
  
  trl = [spindleSamples'-D.fsample*(PSI_START_MS*1e-3),...  % peristim interv:
    spindleSamples'+D.fsample*(PSI_END_MS*1e-3),...         % [start end relativeStartOffset]
    (-1)*ones(size(spindleSamples,2),1)*D.fsample*(PSI_START_MS*1e-3)];

  conditionlabels = cell(size(trl,1),1);
  conditionlabelsNonoverlap = cell(size(trl,1),1); % used later for nonoverlap condition
  conditionlabelsControl = cell(size(trl,1),1);    % used later for control condition
  
  for m=1:size(conditionlabels,1)
    conditionlabels{m} = ['spindlePeak_',spindleInfo(i).sensor{1}];
    conditionlabelsNonoverlap{m} = ['spindlePeak_',spindleInfo(i).sensor{1},'_nonoverlap'];
    conditionlabelsControl{m} = ['spindlePeak_',spindleInfo(i).sensor{1},'_control'];
  end
  
  conditionNumber = i;
  trlControl = f_createControlTrials(trl, spindleInfo, conditionNumber);
  
  
  % -------------------------------
  % 1. save each spindle condition (i.e. sensor) plus controlConditions
  % to separate file:
  % -------------------------------
  trl_help = trl;
  conditionlabels_help = conditionlabels;
    
  trl = [trl; trlControl];
  conditionlabels = [conditionlabels; conditionlabelsControl];
  
  saveToFile = [D.path,'/trials_spindels_psi',num2str(PSI_START_MS),'_',num2str(PSI_END_MS),'_overlap_',num2str(D.fsample),'Hz_',spindleInfo(i).sensor{1}];  % save to spm8 meg data directory
  save(saveToFile, 'trl', 'conditionlabels');
  fprintf('...saved to %s.mat\n',saveToFile);
  
  trl = trl_help;
  conditionlabels = conditionlabels_help;
  
  % -------------------------------
  % 2. remove overlapping events: save each spindle condition (i.e. sensor)
  % plus controlConditions to separate file:
  % -------------------------------
  k=1;
  trl2=[];
  for p=1:size(trl,1)
    trl2(k)=trl(p,1);
    k=k+1;
    trl2(k)=trl(p,2);
    k=k+1;
  end
  dtrl2=diff(trl2);
  dtrl2=dtrl2(2:2:end);
  
  % epoch indices in trl that nonoverlap with precessor epoch:
  trlNonoverlap = trl(find(dtrl2>0),:);
  
  numRejected=sum(dtrl2<0);
  numAll=size(trl,1);
  figure(301); plot(dtrl2(find(dtrl2<0))/D.fsample,'r*')
  title([num2str(numRejected),' rejected trials, ratio=',num2str(numRejected/numAll)])
  
  trl = trlNonoverlap;
  conditionlabels = conditionlabelsNonoverlap(1:size(trl,1));

  trl_nonoverlap_help = trl;
  conditionlabels_nonoverlap_help = conditionlabels;
  
  trlControl = f_createControlTrials(trl, spindleInfo, conditionNumber);    
  trl = [trl; trlControl];
  conditionlabels = [conditionlabels; conditionlabelsControl(1:size(trlControl,1))];
  
  saveToFile = [D.path,'/trials_spindels_psi',num2str(PSI_START_MS),'_',num2str(PSI_END_MS),'_nonoverlap_',num2str(D.fsample),'Hz_',spindleInfo(i).sensor{1}];  % save to spm8 meg data directory
  save(saveToFile, 'trl', 'conditionlabels');
  fprintf('...saved to %s.mat\n',saveToFile);
    
  trl = trl_help;
  conditionlabels = conditionlabels_help;
  
  trlAll = [trlAll;trl];
  conditionlabelsAll = [conditionlabelsAll;conditionlabels];
  
  
%   trl = trl_help;
%   conditionlabels = conditionlabels_help;
  
  % -------------------------------
  % 3. save combined spindle conditions (i.e. all sensors + (non)overlap) 
  % per subject (without controlConditions!):
  % -------------------------------
  trlAll = [trlAll;trl];
  conditionlabelsAll = [conditionlabelsAll;conditionlabels];

  if mod(i,size(spindleInfo,2)) == 0
    saveAllToFile = [D.path,'/trials_spindels_all_psi',num2str(PSI_START_MS),'_',num2str(PSI_END_MS),'_',num2str(D.fsample),'Hz_all'];  % save to spm8 meg data directory
    trl = trlAll;
    conditionlabels = conditionlabelsAll;
    save(saveAllToFile, 'trl', 'conditionlabels');
    fprintf('...saved combined spindel conditions to %s.mat\n',saveAllToFile);
  end
end
ret = 1;
end


% ===================== local subfunctions ===================================

function trlControl = f_createControlTrials(trl, spindleInfo, conditionNumber)

  % determine maximal range around spindlePeak, i.e.
  % [min(spindlePeak-spindleDur, psiStart) max(spindlePeak+spindleDur,
  % psiEnd)] (this is the safe version operating without exact
  % spindleOnset/-Offset information!)
  % in addition a 1000ms distance is added on both ends.
  
  ADD_DIST = 1000; % in ms; additional distance around spindles (both ends) 
  
  samplingFreq = spindleInfo(conditionNumber).info.samplingFreq;
  spindleDur = str2num(cell2mat(spindleInfo(conditionNumber).duration')); % duration in seconds
  spindleDurSamples = spindleDur*samplingFreq;
  
  addDistSamples = (ADD_DIST/1000)*samplingFreq;
  
  trlMax = zeros(size(trl,1),2);
  for i=1:size(trl,1)
    trlMax(i,:) = ...
      [min( trl(i,1), trl(i,1)-trl(i,3)-spindleDurSamples(i) ) - addDistSamples,...
      max( trl(i,2), trl(i,1)-trl(i,3)+spindleDurSamples(i) ) + addDistSamples];
  end
    
  totalRangeSamples = [trlMax(1,2):trlMax(end,1)]; % sample range from 
                                                   % end of first spindle to 
                                                   % beginning of last spindle 
  nonSpindleSamples_tmp = totalRangeSamples; % init
%   % slow algorithm!:
%   for i=2:(size(trlMax,1)-1) % start from second epoch until epoch before last epoch
%     indSamplesEpoch = [];
%     indSamplesEpoch = [trlMax(i,1):trlMax(i,2)];
%     for j=1:size(indSamplesEpoch,2)
%       indSamples = [indSamples, find(indSamplesEpoch(j) == totalRangeSamples)];
%     end
%   end
  for i=2:(size(trlMax,1)-1) % start with second spindle until second last spindle
    fprintf('i=%d\n',i);
    nonSpindleSamples_tmp(trlMax(i,1):trlMax(i,2))=0; % set all spindle samples to 0
  end  
  nonSpindleSamples = nonSpindleSamples_tmp(find(nonSpindleSamples_tmp)); % keep non-spindle samples only

  
  nonREM_Epoch_ind = find(spindleInfo(1).sleepStages(:,1));
  EMG_ind = [];
  for i=1:size(nonREM_Epoch_ind,1)
    if spindleInfo(1).sleepStages(nonREM_Epoch_ind(i),2)==1 % second column indicates EMG artifact (0=no, 1=yes)
      EMG_ind = [EMG_ind;i]
    end
  end
  nonREM_Epoch_ind(EMG_ind) = []; % keep only those states without EMG artifact
  
%   nonREM_Epoch_SampleOnsets = nonREM_Epoch_ind*(samplingFreq*30); % add sample distance per contained 30s-epoch 
nonREM_Epoch_SampleOnsets = (nonREM_Epoch_ind - 1)...
                            *(samplingFreq*30) + 1; % add sample distance per contained 30s-epoch:
                                                    % shift epoch_ind value by -1 and add 1 to result,
                                                    % i.e. start with sample #1                      
  
  nonREM_samples = [];
  for i=1:size(nonREM_Epoch_SampleOnsets,1)
    nonREM_samples = [nonREM_samples nonREM_Epoch_SampleOnsets(i):nonREM_Epoch_SampleOnsets(i)+samplingFreq*30];
  end
  controlSamples = intersect(nonSpindleSamples, nonREM_samples); % interesction between nonSpindel and nonREM samples
  
  % cut randomly controlEpochs of sample length (trlMax(1,2) - trlMax(1,1)) from controlSamples vector:
%   controlSampleLength = trlMax(1,2) - trlMax(1,1);
  controlSampleLength = trl(1,2) - trl(1,1); % use length of original trials
  controlSamplesShuffled = controlSamples(randperm(length(controlSamples(1:end-2*controlSampleLength)))); % skip last controlSampleLength-indices
  
  trlControl = [];
  i = 0;
%   j = 0;
  while size(trlControl,1) < size(trl,1) % number of controlEpochs to collect
    i = i+1;
    %     if ~find(diff(controlSamples(controlSamplesShuffled(i):controlSamplesShuffled(i)+controlSampleLength))-1)
    ind = find(controlSamplesShuffled(i)==controlSamples);
    if isempty(find(diff(controlSamples(ind:ind+controlSampleLength))-1))
%       j = j+1
      trlControl = [trlControl; [controlSamples(ind) controlSamples(ind)+controlSampleLength trl(1,3)]];
    end
  end
  
  
end % function
  
  
  
