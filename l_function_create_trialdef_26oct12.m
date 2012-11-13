function ret = l_function_create_trialdef_26oct12(S)
% function ret = l_function_create_trialdef_26oct12(D, PSI_START_MS, PSI_END_MS)
% creates trialdef_xxx.mat files for all spindle peak conditions (i.e. 6
% eeg sensor positions) in two versions (non-/overlap) within the actual subject folder.
% NB: info is read from spindleInfo.mat file (created by
%     l_function_create_spindleInfos_26oct12.m)
% --------------------
% Version: v0.5, 26oct12,leo)


% clear all
% workDir      =  '/media/leo_data/sleep/meg/s01/Vp01/subj1_sleep_20090114_01.ds'
% currDir      = workDir;
% D            = spm_eeg_load('dfspm8_subj1_sleep_20090114_01.mat')
% PSI_START_MS = 3000
% PSI_END_MS   = 3000
% OVERLAP      = 0


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




%
% NAME_FILE_LIST=['fileList_spindelData_',date,'.txt']
%
% % s = ['find `pwd` -mindepth 2 -maxdepth 2 -type d  | grep -i -v -E "(ID519|ID533)/pre1" | sort -n > folderList_subj_ohneID519pre1_ohne533pre1.txt']
% % s = ['find -mindepth 3 -maxdepth 3 -type d  | grep -E "^\.\/s[0-1][0-9]\/Vp[0-1][0-9]\/Vp[0-1][0-9]$" | sort -n > folderList_spindelData.txt']
% % s = ['find -mindepth 4 -maxdepth 4 -type f  | grep -E "^\.\/s[0-1][0-9]\/Vp[0-1][0-9].*\/Vp[0-1][0-9]\/vp.*400Hz_.*\.txt$" | sort -n > fileList_spindelData.txt']
% % s = ['find -L -mindepth 4 -maxdepth 4 -type f  | ',...
% %     'grep -E "^\.\/s[0-1][0-9]\/Vp[0-1][0-9].*\/Vp[0-1][0-9]\/vp.*400Hz_.*\.txt$" |',...
% %     'sort -n > ',NAME_FILE_LIST]
% s = ['find -L ../Vp* -mindepth 1 -maxdepth 1 -type f  | ',...
%     'grep -E ".*_400Hz_.*\.txt$" |',...
%     'sort -n > ',NAME_FILE_LIST]
%
%
% system(s);
% fileList = importdata(NAME_FILE_LIST) % create cellarray of input dirs

load('spindleInfo.mat','spindleInfo')

% sensorLabels = cellstr(['C3';'C4';'Cz';'F3';'F4';'Fz']);

% currDir = pwd;
trlAll=[];
conditionlabelsAll=[];
% for i = 1:size(fileList,1)
for i = 1:size(spindleInfo,2) %over conditions i.e. sensors
  %   [pathstr,name,ext] = fileparts(fileList{i});
  %   spindles = importdata(fileList{i},'',5)  % load spindel file, ignore 5 header lines,
  %                                           % CAVE: reads rows from the beginning after header
  %                                           % only until dash-row-separator
  %                                           % appears, which is good in our
  %                                           % case because the files contain
  %                                           % information about peak2peak
  %                                           % amp. etc. in the following
  %                                           % rows, too.
  % %   [status, result]=system(['find ',pathstr,'/.. -type f | grep -E "\/spm8.*\.mat$"']);
  % %   D = spm_eeg_load(result);  % load respective spm8 megfile
  data = spindleInfo(i).peakOnsets';
  %   spindleSamples = D.indsample(spindles.data(1:sum(~isnan(D.indsample(spindles.data)))));
  spindles=[];
  for k=1:size(data,1)
    spindles(k)= str2num(cell2mat(data(k)));
  end
  spindles=spindles';
  
  spindleSamples = D.indsample(spindles);
  
  %   trl = [spindleSamples'-D.fsample*3 spindleSamples'+D.fsample*3,...
  %                     (-1)*ones(size(spindleSamples,2),1)*D.fsample*3]; % peristim interv [start end relativeStartOffset]-/+ 3sec
  trl = [spindleSamples'-D.fsample*(PSI_START_MS*1e-3),...  % peristim interv:
    spindleSamples'+D.fsample*(PSI_END_MS*1e-3),...         % [start end relativeStartOffset]
    (-1)*ones(size(spindleSamples,2),1)*D.fsample*(PSI_START_MS*1e-3)];
  conditionlabels = cell(size(trl,1),1);
  conditionlabelsNonoverlap = cell(size(trl,1),1); % used later for nonoverlap condition
  
  
  %   for l=1:size(sensorLabels,1)
  %     if ~isempty(strfind(name,sensorLabels{l}))
  for m=1:size(conditionlabels,1)
    %         conditionlabels{m} = ['spindlePeak_',sensorLabels{l}];
    conditionlabels{m} = ['spindlePeak_',spindleInfo(i).sensor{1}];
    conditionlabelsNonoverlap{m} = ['spindlePeak_',spindleInfo(i).sensor{1},'_nonoverlap'];
  end
  %     end
  %   end
  
  %   for l=1:size(sensorLabels,1)
  %     if ~isempty(strfind(name,sensorLabels{l}))
  %       for m=1:size(conditionlabels,1)
  %         conditionlabels{m} = ['spindlePeak_',sensorLabels{l}];
  %         conditionlabelsNonoverlap{m} = ['spindlePeak_',sensorLabels{l},'_nonoverlap'];
  %       end
  %     end
  %   end
  
  % 1. save each spindle condition (i.e. sensor) to separate file:
  %   saveToFile = [D.path,'/trials_spindels_',name];  % save to spm8 meg data directory
  
  %   if OVERLAP
  %       sOVERLAP='overlap';
  %   else sOVERLAP='nonoverlap';
  %   end
  
  %   saveToFile = [D.path,'/trials_spindels_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_overlap_',num2str(D.fsample),'Hz_',name];  % save to spm8 meg data directory
  saveToFile = [D.path,'/trials_spindels_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_overlap_',num2str(D.fsample),'Hz_',spindleInfo(i).sensor{1}];  % save to spm8 meg data directory
  save(saveToFile, 'trl', 'conditionlabels');
  fprintf('...saved to %s.mat\n',saveToFile);
  
  trl_help = trl;
  conditionlabels_help = conditionlabels;
  
  % 2. remove overlapping events: save each spindle condition (i.e. sensor) to separate file:
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
  trlAll = [trlAll;trl];
  conditionlabelsAll = [conditionlabelsAll;conditionlabels];
  
  %   saveToFile = [fileparts(result),'/trials_spindels_nonoverlapping_',name];  % save to spm8 meg data directory
  %   saveToFile = [D.path,'/trials_spindels_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_nonoverlap_',num2str(D.fsample),'Hz_',name];  % save to spm8 meg data directory
  saveToFile = [D.path,'/trials_spindels_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_nonoverlap_',num2str(D.fsample),'Hz_',spindleInfo(i).sensor{1}];  % save to spm8 meg data directory
  save(saveToFile, 'trl', 'conditionlabels');
  fprintf('...saved to %s.mat\n',saveToFile);
  
  trl = trl_help;
  conditionlabels = conditionlabels_help;
  
  % 3. save combined spindle conditions (i.e. all sensors + (non)overlap) per subject, too:
  trlAll = [trlAll;trl];
  conditionlabelsAll = [conditionlabelsAll;conditionlabels];
%   if mod(i,size(sensorLabels,1)) == 0
  if mod(i,size(spindleInfo,2)) == 0
    
    %     saveAllToFile = [fileparts(result),'/trials_spindels_all'];  % save to spm8 meg data directory
    saveAllToFile = [D.path,'/trials_spindels_all_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_',num2str(D.fsample),'Hz_all'];  % save to spm8 meg data directory
    trl = trlAll;
    conditionlabels = conditionlabelsAll;
    save(saveAllToFile, 'trl', 'conditionlabels');
    fprintf('...saved combined spindel conditions to %s.mat\n',saveAllToFile);
    %     trlAll = [];
    %     conditionlabelsAll = [];
  end
end
ret = 1;