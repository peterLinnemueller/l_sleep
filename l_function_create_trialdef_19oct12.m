function ret = l_function_create_trialdef_19oct12(S)%D, PSI_START_MS, PSI_END_MS, OVERLAP)
% function ret = l_function_create_trialdef_19oct12(D, PSI_START_MS, PSI_END_MS, OVERLAP)
% creates trialdef_xxx.mat files for all spindle peak conditions (i.e. 6
% eeg sensor positions) within the actual subject folder. 
% NB: condition files are supposed to be in ../Vpxx/ folder

workDir      = S.workDir;
currDir      = S.currDir;
D            = S.D;
PSI_START_MS = S.PSI_START_MS;
PSI_END_MS   = S.PSI_END_MS;
OVERLAP      = S.OVERLAP;

  fprintf(['\nexecuting l_function_create_trialdef_19oct12(\n\tworkDir=%s,',...
          '\n\tcurrDir=%s, \n\tD=%s, \n\tPSI_START_MS=%d,',...
          '\n\tPSI_END_MS=%d, \n\tOVERLAP=%d)\n'], workDir, currDir,...
          D.fname, PSI_START_MS, PSI_END_MS, OVERLAP); 
  fprintf('\n...moving to %s\n',pwd);
  fprintf('\nstart processing...\n');
  
  
  
  
  
NAME_FILE_LIST=['fileList_spindelData_',date,'.txt']

% s = ['find `pwd` -mindepth 2 -maxdepth 2 -type d  | grep -i -v -E "(ID519|ID533)/pre1" | sort -n > folderList_subj_ohneID519pre1_ohne533pre1.txt']
% s = ['find -mindepth 3 -maxdepth 3 -type d  | grep -E "^\.\/s[0-1][0-9]\/Vp[0-1][0-9]\/Vp[0-1][0-9]$" | sort -n > folderList_spindelData.txt']
% s = ['find -mindepth 4 -maxdepth 4 -type f  | grep -E "^\.\/s[0-1][0-9]\/Vp[0-1][0-9].*\/Vp[0-1][0-9]\/vp.*400Hz_.*\.txt$" | sort -n > fileList_spindelData.txt']
% s = ['find -L -mindepth 4 -maxdepth 4 -type f  | ',...
%     'grep -E "^\.\/s[0-1][0-9]\/Vp[0-1][0-9].*\/Vp[0-1][0-9]\/vp.*400Hz_.*\.txt$" |',...
%     'sort -n > ',NAME_FILE_LIST]
s = ['find -L ../Vp* -mindepth 1 -maxdepth 1 -type f  | ',...
    'grep -E ".*_400Hz_.*\.txt$" |',...
    'sort -n > ',NAME_FILE_LIST]
  

system(s);
fileList = importdata(NAME_FILE_LIST) % create cellarray of input dirs

sensorLabels = cellstr(['C3';'C4';'Cz';'F3';'F4';'Fz']);

% currDir = pwd;
trlAll=[];
conditionlabelsAll=[];
for i = 1:size(fileList,1)
  [pathstr,name,ext] = fileparts(fileList{i});
  spindles = importdata(fileList{i},'',5)  % load spindel file, ignore 5 header lines, 
                                          % CAVE: reads rows from the beginning after header
                                          % only until dash-row-separator
                                          % appears, which is good in our
                                          % case because the files contain
                                          % information about peak2peak
                                          % amp. etc. in the following
                                          % rows, too.
%   [status, result]=system(['find ',pathstr,'/.. -type f | grep -E "\/spm8.*\.mat$"']);
%   D = spm_eeg_load(result);  % load respective spm8 megfile
  
  spindelSamples = D.indsample(spindles.data(1:sum(~isnan(D.indsample(spindles.data)))));

%   trl = [spindelSamples'-D.fsample*3 spindelSamples'+D.fsample*3,...
%                     (-1)*ones(size(spindelSamples,2),1)*D.fsample*3]; % peristim interv [start end relativeStartOffset]-/+ 3sec
  trl = [spindelSamples'-D.fsample*(PSI_START_MS*1e-3),...  % peristim interv:
         spindelSamples'+D.fsample*(PSI_END_MS*1e-3),...    %  [start end relativeStartOffset]
         (-1)*ones(size(spindelSamples,2),1)*D.fsample*(PSI_START_MS*1e-3)];
  conditionlabels = cell(size(trl,1),1);
  conditionlabelsNonoverlap = cell(size(trl,1),1); % used later for nonoverlap condition
  
  for l=1:size(sensorLabels,1)
    if ~isempty(strfind(name,sensorLabels{l}))
      for m=1:size(conditionlabels,1)
        conditionlabels{m} = ['spindelPeak_',sensorLabels{l}];
        conditionlabelsNonoverlap{m} = ['spindelPeak_',sensorLabels{l},'_nonoverlap'];
      end
    end
  end

  % 1. save each spindle condition (i.e. sensor) to separate file:
%   saveToFile = [D.path,'/trials_spindels_',name];  % save to spm8 meg data directory

%   if OVERLAP
%       sOVERLAP='overlap';
%   else sOVERLAP='nonoverlap';
%   end

  saveToFile = [D.path,'/trials_spindels_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_overlap_',num2str(D.fsample),'Hz_',name];  % save to spm8 meg data directory
  save(saveToFile, 'trl', 'conditionlabels');
  fprintf('...saved to %s.mat\n',saveToFile);

  trl_help = trl;
  conditionlabels_help = conditionlabels;
  
  % 2. remove overlapping events: save each spindle condition (i.e. sensor) to separate file:
  k=1;
  trl2=[];
  for i=1:size(trl,1)
    trl2(k)=trl(i,1);
    k=k+1;
    trl2(k)=trl(i,2);
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
  saveToFile = [D.path,'/trials_spindels_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_nonoverlap_',num2str(D.fsample),'Hz_',name];  % save to spm8 meg data directory
  save(saveToFile, 'trl', 'conditionlabels');
  fprintf('...saved to %s.mat\n',saveToFile);

  trl = trl_help;
  conditionlabels = conditionlabels_help;
  
  % 3. save combined spindle conditions (i.e. all sensors + (non)overlap) per subject, too:
  trlAll = [trlAll;trl];
  conditionlabelsAll = [conditionlabelsAll;conditionlabels];
  if mod(i,size(sensorLabels,1)) == 0
%     saveAllToFile = [fileparts(result),'/trials_spindels_all'];  % save to spm8 meg data directory
    saveAllToFile = [D.path,'/trials_spindels_all_psi',num2str(PSI_START_MS),'-',num2str(PSI_END_MS),'_',num2str(D.fsample),'Hz'];  % save to spm8 meg data directory
    trl = trlAll;
    conditionlabels = conditionlabelsAll;
    save(saveAllToFile, 'trl', 'conditionlabels');
    fprintf('...saved combined spindel conditions to %s.mat\n',saveAllToFile);
%     trlAll = [];
%     conditionlabelsAll = [];
  end
end
ret = 1;