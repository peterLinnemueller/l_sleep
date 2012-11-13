% l_script_create_trialdef_spindelPeaks_17sep12.m, leo 17sep12
% creates trialdef_xxx.mat files for all subjects and spindle conditions (i.e.
% eeg sensor positions) within the meg data folder. PSI is fixed to
% +/-3sec.

clear all

cd /data1/sleep/meg

% s = ['find `pwd` -mindepth 2 -maxdepth 2 -type d  | grep -i -v -E "(ID519|ID533)/pre1" | sort -n > folderList_subj_ohneID519pre1_ohne533pre1.txt']
% s = ['find -mindepth 3 -maxdepth 3 -type d  | grep -E "^\.\/s[0-1][0-9]\/Vp[0-1][0-9]\/Vp[0-1][0-9]$" | sort -n > folderList_spindelData.txt']
s = ['find -mindepth 4 -maxdepth 4 -type f  | grep -E "^\.\/s[0-1][0-9]\/Vp[0-1][0-9].*\/Vp[0-1][0-9]\/vp.*400Hz_.*\.txt$" | sort -n > fileList_spindelData.txt']
system(s);
fileList = importdata('fileList_spindelData.txt') % create cellarray of input dirs

sensorLabels = cellstr(['C3';'C4';'Cz';'F3';'F4';'Fz']);

currDir = pwd;
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
  [status, result]=system(['find ',pathstr,'/.. -type f | grep -E "\/spm8.*\.mat$"']);
  D = spm_eeg_load(result);  % load respective spm8 megfile
  
  spindelSamples = D.indsample(spindles.data(1:sum(~isnan(D.indsample(spindles.data)))));

  trl = [spindelSamples'-D.fsample*3 spindelSamples'+D.fsample*3 (-1)*ones(size(spindelSamples,2),1)*D.fsample*3]; % peristim interv [start end relativeStartOffset]-/+ 3sec
  conditionlabels = cell(size(trl,1),1);
  
  for j=1:size(sensorLabels,1)
    if ~isempty(strfind(name,sensorLabels{j}))
      for k=1:size(conditionlabels,1)
        conditionlabels{k} = ['spindelPeak_',sensorLabels{j}];
      end
    end
  end

  % save each spindle condition (i.e. sensor) to separate file:
  saveToFile = [fileparts(result),'/trials_spindels_',name];  % save to spm8 meg data directory
  save(saveToFile, 'trl', 'conditionlabels');
  disp(sprintf('...saved to %s.mat',saveToFile));

  % save combined spindle conditions (i.e. all sensors) per subject, too:
  trlAll = [trlAll;trl];
  conditionlabelsAll = [conditionlabelsAll;conditionlabels];
  if mod(i,size(sensorLabels,1)) == 0
    saveAllToFile = [fileparts(result),'/trials_spindels_all'];  % save to spm8 meg data directory
    trl = trlAll;
    conditionlabels = conditionlabelsAll;
    save(saveAllToFile, 'trl', 'conditionlabels');
    disp(sprintf('...saved combined spindel conditions to %s.mat',saveAllToFile));
    trlAll = [];
    conditionlabelsAll = [];
  end
end