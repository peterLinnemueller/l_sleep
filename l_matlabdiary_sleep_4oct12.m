%% l_matlabdiary_sleep, leo 20sep12
% snippets collection

%% general matlab
% start without GUI
matlab -nodisplay -nojvm -r l_script_strokeMEG_mot_analysis_13jun12 

% show installed toolboxes
ver

% multiciore processing
matlabpool open ncores
parfor i=1:10
end
matlabpool close

%% example data set:
D=spm_eeg_load('/data1/sleep/meg/s02/Vp03/subj2_sleep_20090312_01.ds/mfdfespm8_subj2_sleep_20090312_01.mat')

%% find positions of all matching channeltypes:
find(strcmp(D.chantype,'MEGGRAD'))
%%
% e.g. plot all MEGGRAD channels from sample 1000:1400 for condition 3:
size(D)
plot(D(find(strcmp(D.chantype,'MEGGRAD')),1000:1400,3)')
hold on;
plot(mean(D(find(strcmp(D.chantype,'MEGGRAD')),1000:1400,3))','*r')

%% plot all averaged eeg channels over conditions

figure(201);
pos=1;
for i=1:6 % channels
  for j=1:6 % conditions
    subplot(6,6,pos)
      plot(D(find(strcmp(D.chanlabels,['EEG00',num2str(i)])),1000:1400,j)')
    pos=pos+1;
  end
end
   
%% choose channels
indEEG=find(strcmp(D.chantype,'EEG')) % find indices of EEG-type channels
indSleepEEG=indEEG(~strncmp(D.chanlabels(indEEG),'EEG',3)) % find indices of non-EEG-labeled channels from EEG-type channels (our sleep data!)

%%  spm_eeg_copy
%   Copy EEG/MEG data to new files
%   FORMAT D = spm_eeg_copy(S)
%   S           - input struct (optional)
%   (optional) fields of S:
%     S.D       - MEEG object or filename of MEEG mat-file
%     S.newname - filename for the new dataset
%     S.updatehistory - update history information [default: true]
%  
%   D           - MEEG object of the new dataset
%  __________________________________________________________________________
%   Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

S=[];
S.D=D;
S.newname=['_EEG_',D.fname];
E = spm_eeg_copy(S)  % leo: E variable depicts EEG-object (D is still MEG or combined)

%%  spm_eeg_crop
%   Reduce the data size by cutting in time and frequency.
%   FORMAT D = spm_eeg_crop(S)
%  
%   S        - optional input struct
%   (optional) fields of S:
%   D        - MEEG object or filename of M/EEG mat-file with epoched data
%   timewin  - time window to retain (in PST ms)
%   freqwin  - frequency window to retain
%   channels - cell array of channel labels or 'all'.
%  
%   Output:
%   D        - MEEG object (also written on disk)
%  
%  __________________________________________________________________________
%   Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
S=[];
S.D=E;
S.timewin=inf;
S.freqwin=inf;
S.channels=E.chanlabels(indSleepEEG);
E=spm_eeg_crop(S) % writes new file with prefix 'p'

%%


% %%  spm_eeg_channelselection
% %   Function for selection of channels
% %   FORMAT S = spm_eeg_channelselection(S)
% %   S - existing configuration struct (optional)
% %   Fields of S:
% %   S.channels - can be 'MEG', 'EEG', 'file', 'gui' or cell array of labels
% %   S.chanfile - filename (used in case S.channels = 'file')
% %   S.dataset - MEEG dataset name
% %   S.inputformat - data type (optional) to force the use of specific data
% %   reader
% %  
% %   OUTPUT:
% %     S.channels - cell array of labels
% %  __________________________________________________________________________
% %   Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
% 
% S=[];
% S.channels = D.chanlabels(indSleepEEG);
% S.dataset = D;


%% plot spectogram
D = spm_eeg_load(tf_*spm8*.mat)
d = squeeze(D(142,:,:,21));
imagesc(d)