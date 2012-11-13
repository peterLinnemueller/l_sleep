clear all
addpath /home/leonhard/spm8_r4667/
spm('defaults','eeg'); 
addpath('/data1/sleep/meg/scripts')

rootDir = '/data1/sleep/meg';

cd(rootDir)
% s = ['find -L -mindepth 3 -maxdepth 4 -type d '...
%     '| grep -E ".*subj[0-9].*sleep.*_0[1-2]\.ds$" '...
%     '| sort -n > folderList_subjMegDirs.txt']
s = ['find -type d '...
    '| grep -E ".*\/s0[6-9]_new.*" '...
    '| sort -n > folderList_subjMegDirs.txt']
system(s);

folderList = importdata('folderList_subjMegDirs.txt') % create cellarray of input dirs

currDir = pwd % should be e.g. ./scripts

% if (matlabpool('size') == 0)
%   matlabpool open 4
% end

numFiles=size(folderList,1);


tic
for i=1:numFiles
  try
    fprintf('i=%d\n',i);
    workDir = [rootDir,'/',folderList{i}(3:end)]
%     workDir =folderList{i}
    % ------------------------
    % basic hp-filtering and downsampling:
    DATA_FILE       = '^spm8_subj.*.mat$' % spm_select() searchstring within subject folder
    HP_FREQ         = 1
    DOWNSAMPLE_FREQ = 400
    ret = l_function_df_19oct12(currDir,workDir,HP_FREQ,DOWNSAMPLE_FREQ)
    % ------------------------

%     % ------------------------
%     % epoching:
%     DATA_FILE     = '^df_spm8_subj.*.mat$' % spm_select() searchstring within subject folder
%     PSI_START_MS  = -3000 % milliseconds
%     PSI_END_MS    = 3000  % milliseconds
%     OVERLAP       = 0     % are epochs allowed to overlap? 0:no, 1:yes
%                           % (0 means: throw overlapping epochs away!)
%     ret = l_function_epoch_19oct12(currDir, workDir, DATA_FILE, PSI_START_MS, PSI_END_MS, OVERLAP)
      
    
%     % ------------------------
%     % 
%     DATA_FILE='^espm8_subj.*.mat$' % spm_select() searchstring within subject folder
%     ret = l_function_EEG_bfdfpe_15oct12(currDir,workDir)
      
  catch err
%     if (matlabpool('size') == 0)
%       matlabpool close
%     end
  end
      
end % parfor
toc

% if (matlabpool('size') == 0)
%   matlabpool close
% end