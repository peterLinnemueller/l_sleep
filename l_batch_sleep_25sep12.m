% List of open inputs
% Change Directory: Directory - cfg_files
% M/EEG Epoching: File Name - cfg_files
% M/EEG Epoching: File Name - cfg_files
% M/EEG Epoching: Padding - cfg_entry
nrun = X; % enter the number of runs here
jobfile = {'/data1/sleep/meg/scripts/l_batch_sleep_25sep12_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(4, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Change Directory: Directory - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % M/EEG Epoching: File Name - cfg_files
    inputs{3, crun} = MATLAB_CODE_TO_FILL_INPUT; % M/EEG Epoching: File Name - cfg_files
    inputs{4, crun} = MATLAB_CODE_TO_FILL_INPUT; % M/EEG Epoching: Padding - cfg_entry
end
spm('defaults', 'EEG');
spm_jobman('serial', jobs, '', inputs{:});
