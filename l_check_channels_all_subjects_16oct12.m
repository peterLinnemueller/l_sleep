%% import meg4
clear all
addpath /home/leonhard/spm8_r4667/
spm('defaults','eeg'); 
addpath('/data1/sleep/meg/scripts')

rootDir = '/data1/sleep/meg';
cd(rootDir)
s = ['find -L -mindepth 3 -maxdepth 4 -type d '...
    '| grep -E ".*subj[0-9].*sleep.*_0[1-2]\.ds$" '...
    '| sort -n > folderList_subjMegDirs.txt']
system(s);
folderList = importdata('folderList_subjMegDirs.txt') % create cellarray of input dirs

currDir = pwd % should be e.g. ./scripts
% matlabpool open 4
numFiles=size(folderList,1);

eegChannels.chanNumber=[306:313,362:365]
eegChannels.chanLabel={'Cz','Fz','C3','C4','F3','F4','A1','A2','EOG_hor','EOG_ver','EMG','ECG'}
% figure(201); clf;
% parfor i = 2:numFiles
for i = 1:numFiles
  workDir=[rootDir,'/',folderList{i}(3:end)]
  cd(workDir)
  fprintf('...moving to %s\n',pwd);
  fprintf('start processing...\n');
  
  % 1:
  D = spm_eeg_load(spm_select('FPList',workDir,'^spm8_subj.*.mat$'))
  
  figure(201);
  subplot(5,3,i)
    plot(squeeze((D(306,1000:4000,1))));
  
%   indEEG_EOGhor=find(strcmp(D.chanlabels,'EOGhor'))
%   indEEG_EOGver=find(strcmp(D.chanlabels,'EOGver'))
%   indEEG_EMG=find(strcmp(D.chanlabels,'EMG'))
%   indEEG_ECG=find(strcmp(D.chanlabels,'ECG'))
%   find(strcmp(D.chanlabels,'Cz'))
%   find(strcmp(D.chanlabels,'F3'))
%   find(strcmp(D.chanlabels,'F4'))
%   find(strcmp(D.chanlabels,'Fz'))
%   find(strcmp(D.chanlabels,'C3'))
%   find(strcmp(D.chanlabels,'C4'))
%   find(strcmp(D.chanlabels,'A1'))
%   find(strcmp(D.chanlabels,'A2'))

%   pause

  % 2:
  E = spm_eeg_load(spm_select('FPList',workDir,'^spm8_subj.*.mat$'))

end % parfor

cd(rootDir)


%save to txt file:
filename = 'R/eegdata.csv';
fid = fopen(filename, 'w');
fprintf(fid, '%s,', eegChannels.chanLabel{1,1:end-1});
fprintf(fid,'%s\n',eegChannels.chanLabel{1,end});
data = D(eegChannels.chanNumber,1e+4:2e+4,1)';
[nrows,ncolums]= size(data);
for row=1:nrows-1
    fprintf(fid, '%d,', data(row,1:end-1));
    fprintf(fid, '%d\n', data(row,end));
end
% fprintf(fid, '%d\n', data(end,end));
fclose(fid);

% matlabpool close