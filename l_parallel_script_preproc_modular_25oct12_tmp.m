clear all
addpath /home/leonhard/MATLAB/usertoolboxes/spm8_r4667/
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

% if (matlabpool('size') == 0)
%   matlabpool open 4
% end

numFiles=size(folderList,1);


tic
for i=1:numFiles %:numFiles
%   try
    fprintf('i=%d\n',i);
    workDir = [rootDir,'/',folderList{i}(3:end)]
    
%     % ------------------------
%     % create mat-struct from subject spindle info file (vpXX_400Hz_Cz.txt):
%     S = [];
%     S.workDir = workDir
%     S.currDir = currDir
%     ret = l_function_create_spindleInfos_26oct12(S)
%     % ------------------------
    
%     % ------------------------
%     % basic hp-filtering and downsampling:
%     DATA_FILE       = '^spm8_subj.*.mat$' % spm_select() searchstring within subject folder
%     HP_FREQ         = 1
%     DOWNSAMPLE_FREQ = 200
%     ret = l_function_df_19oct12(currDir,workDir,HP_FREQ,DOWNSAMPLE_FREQ)
%     % ------------------------

    % ------------------------
    % epoching:
    S               = [];
    S.workDir       = workDir
    S.currDir       = currDir
    S.DATA_FILE     = '^dfspm8_subj.*.mat$' % spm_select() searchstring within subject folder
    S.PSI_START_MS  = 2000  % milliseconds, pos. time before event
    S.PSI_END_MS    = 2000  % milliseconds
    S.CONDITION     = 'Cz'  % sensor to detect spindel events ('C3';'C4';'Cz';'F3';'F4';'Fz';'all')
    S.OVERLAP       = 0     % are epochs allowed to overlap? 0:no, 1:yes
                            % (0 means: don't use overlapping epochs!)
    ret = l_function_epoch_26oct12(S)
    % ------------------------
    
    
%     % ------------------------
%     % 
%     DATA_FILE='^espm8_subj.*.mat$' % spm_select() searchstring within subject folder
%     ret = l_function_EEG_bfdfpe_15oct12(currDir,workDir)
      
%   catch err
%     if (matlabpool('size') == 0)
%       matlabpool close
%     end
%   end
      
end % parfor
toc

% if (matlabpool('size') == 0)
%   matlabpool close
% end