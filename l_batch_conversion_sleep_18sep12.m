clear all

cd /data1/sleep/meg

% s = ['find `pwd` -mindepth 2 -maxdepth 2 -type d  | grep -i -v -E "(ID519|ID533)/pre1" | sort -n > folderList_subj_ohneID519pre1_ohne533pre1.txt']
% s = ['find -mindepth 3 -maxdepth 3 -type d  | grep -E "^\./subj[0-1].*\.ds$" | sort -n > folderList_subjMegDirs.txt']
s = ['find -mindepth 3 -maxdepth 4 -type d  | grep -E ".*subj[0-9].*sleep.*_0[1-2]\.ds$" | sort -n > folderList_subjMegDirs.txt']
system(s);
folderList = importdata('folderList_subjMegDirs.txt') % create cellarray of input dirs

currDir = pwd;

% List of open inputs
% Change Directory: Directory - cfg_files
% M/EEG Conversion: File Name - cfg_files
% Change Directory: Directory - cfg_files
nrun = size(folderList,1); % enter the number of runs here
jobfile = {'/data1/sleep/meg/scripts/l_batch_conversion_sleep_18sep12_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(3, nrun);
for crun = 1:nrun
    inputs{1, crun} = cellstr(folderList{crun}); % Change Directory: Directory - cfg_files
    inputs{2, crun} = cellstr(folderList{crun}); % M/EEG Conversion: File Name - cfg_files
    inputs{3, crun} = currDir; % Change Directory: Directory - cfg_files
end
spm('defaults', 'EEG');
spm_jobman('serial', jobs, '', inputs{:});