clear all

cd /data1/sleep/meg

% s = ['find `pwd` -mindepth 2 -maxdepth 2 -type d  | grep -i -v -E "(ID519|ID533)/pre1" | sort -n > folderList_subj_ohneID519pre1_ohne533pre1.txt']
s = ['find -mindepth 1 -maxdepth 1 -type d  | grep -E "^\./s[0-1][0-9]$" | sort -n > folderList_subj.txt']
system(s);
folderList = importdata('folderList_subj.txt') % create cellarray of input dirs

currdir = pwd;

% List of open inputs
% M/EEG Conversion: File Name - cfg_files
% M/EEG Epoching: File Name - cfg_files
% M/EEG Filter: Cutoff - cfg_entry
% M/EEG Filter: Cutoff - cfg_entry
nrun = size(folderList,1); % enter the number of runs here
jobfile = {'/home/leonhard/MEG_HH/data/meg/scripts/l_batch_sleep_17sep12_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(4, nrun);
for crun = 1:nrun
    inputs{1, crun} = cellstr(folderList{1}); % M/EEG Conversion: File Name - cfg_files
    
    inputs{2, crun} = cellstr(spm_select('FPList',char(folderList(crun)),'^trials_.*.mat$')); % M/EEG Epoching: File Name - cfg_files
    inputs{3, crun} = 1; % M/EEG Filter: Cutoff - cfg_entry
    inputs{4, crun} = 140; % M/EEG Filter: Cutoff - cfg_entry
end
spm('defaults', 'EEG');
spm_jobman('serial', jobs, '', inputs{:});
