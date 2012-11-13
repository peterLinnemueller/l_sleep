% List of open inputs
% M/EEG Conversion: File Name - cfg_files
% M/EEG Epoching: File Name - cfg_files
% M/EEG Filter: Cutoff - cfg_entry
% M/EEG Filter: Cutoff - cfg_entry
nrun = X; % enter the number of runs here
jobfile = {'/home/leonhard/MEG_HH/data/meg/scripts/l_batch_sleep_17sep12_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(4, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % M/EEG Conversion: File Name - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % M/EEG Epoching: File Name - cfg_files
    inputs{3, crun} = MATLAB_CODE_TO_FILL_INPUT; % M/EEG Filter: Cutoff - cfg_entry
    inputs{4, crun} = MATLAB_CODE_TO_FILL_INPUT; % M/EEG Filter: Cutoff - cfg_entry
end
spm('defaults', 'EEG');
spm_jobman('serial', jobs, '', inputs{:});
