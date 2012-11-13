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
% parfor i = 2:numFiles
for i = 2:numFiles
  workDir=[rootDir,'/',folderList{i}(3:end)]
 
  ret=l_function_EEG_bfdfpe_15oct12(currDir,workDir)

end % parfor

% matlabpool close