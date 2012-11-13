rootDir = '/home/leonhard/MEG_HH/data/meg/'
folders = dir(rootDir)
subjFolders = 

% List of open inputs
% M/EEG Conversion: File Name - cfg_files
nrun = X; % enter the number of runs here
jobfile = {'/home/leonhard/MEG_HH/data/meg/scripts/l_batch_conversion_sleep_13sep12_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(1, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % M/EEG Conversion: File Name - cfg_files
end
spm('defaults', 'EEG');
spm_jobman('serial', jobs, '', inputs{:});
