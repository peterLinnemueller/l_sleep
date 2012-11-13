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
matlabpool % open 2 is maximum (and default) on fridi
numFiles=size(folderList,1);
parfor i = 1:numFiles
% for i = 1:numFiles
workDir=[rootDir,'/',folderList{i}(3:end)]
cd(workDir)
fprintf('...moving to %s\n',pwd);
fprintf('start processing...\n');

%  =============
%% load data set
D = spm_eeg_load(spm_select('FPList',workDir,'^spm8_subj.*.mat$'))

%  =====
%% epoch

%  ____________________________________________
% help spm_eeg_epochs
%   Epoching continuous M/EEG data
%   FORMAT D = spm_eeg_epochs(S)
%  
%   S                     - input structure (optional)
%   (optional) fields of S:
%     S.D                 - MEEG object or filename of M/EEG mat-file with
%                           continuous data
%     S.bc                - baseline-correct the data (1 - yes, 0 - no).
%  
%   Either (to use a ready-made trial definition):
%     S.epochinfo.trl             - Nx2 or Nx3 matrix (N - number of trials)
%                                   [start end offset]
%     S.epochinfo.conditionlabels - one label or cell array of N labels
%     S.epochinfo.padding         - the additional time period around each
%                                   trial for which the events are saved with
%                                   the trial (to let the user keep and use
%                                   for analysis events which are outside) [in ms]
%  
%   Or (to define trials using (spm_eeg_definetrial)):
%     S.pretrig           - pre-trigger time [in ms]
%     S.posttrig          - post-trigger time [in ms]
%     S.trialdef          - structure array for trial definition with fields
%       S.trialdef.conditionlabel - string label for the condition
%       S.trialdef.eventtype      - string
%       S.trialdef.eventvalue     - string, numeric or empty
%  
%     S.reviewtrials      - review individual trials after selection
%     S.save              - save trial definition
%  
%   Output:
%   D                     - MEEG object (also written on disk)
%  __________________________________________________________________________
%  
%   spm_eeg_epochs extracts single trials from continuous EEG/MEG data. The
%   length of an epoch is determined by the samples before and after stimulus
%   presentation. One can limit the extracted trials to specific trial types.
%  ____________________________________________
S = [];
S.D = D;
S.bc = 0;

% load(spm_select('FPList',workDir,'^trials_.*all.mat$'));
epochinfo=load(spm_select('FPList',workDir,'^trials_spindels.*_Cz.mat$')); % CAVE: parfor needs load to put result into struct for transparency!!
S.epochinfo.trl = epochinfo.trl;
S.epochinfo.conditionlabels = epochinfo.conditionlabels; 
S.epochinfo.padding = 0 % how does this work??? 50;%[50;50;50;50]

S.reviewtrials = 0;
S.save = 0;

tic
eD = spm_eeg_epochs(S)
toc 

D = eD;

%% correct channeltypes
indEEG_EOGhor=find(strcmp(D.chanlabels,'EOGhor'))
indEEG_EOGver=find(strcmp(D.chanlabels,'EOGver'))
indEEG_EMG=find(strcmp(D.chanlabels,'EMG'))
indEEG_ECG=find(strcmp(D.chanlabels,'ECG'))

D=chantype(D,indEEG_EOGhor,'EOG');
D=chantype(D,indEEG_EOGver,'EOG');
D=chantype(D,indEEG_EMG,'EMG');
D=chantype(D,indEEG_ECG,'ECG');

channelTypesOrig=D.chantype;
D.save;

%% separate processing for EEG and MEG channels

% ========================================================================
% ========================================================================
%%===== focus on EEG (object E) ==========================================
% ========================================================================
% ========================================================================

%  __________________________________________________________________________
%  spm_eeg_copy
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

%% choose EEG channels
indAllEEG=find(strcmp(E.chantype,'EEG')); % find indices of EEG-type channels
% more easy: indAllEEG=E.meegchannels('EEG');

indSleepEEG=indAllEEG(find( (indAllEEG.*(~strncmp(E.chanlabels(indAllEEG),'EEG',3))) ~= 0 )); % find indices of pure 'EEG'-chanlabels from EEG-chantypes (Cz,Fz,...)

%% create reduced EEG object E (filename _EEG_*)
% EEG 1: set all but sleepEEG channels to type 'Other'

channelTypesNew = cell(size(channelTypesOrig));
for i=1:length(channelTypesNew)
  channelTypesNew{i} = 'Others';
end
for i=1:length(indSleepEEG)
  channelTypesNew{indSleepEEG(i)} = 'EEG'; 
end

E=E.chantype(1:length(channelTypesOrig),channelTypesNew); 
E.save;

%  __________________________________________________________________________
%  spm_eeg_crop
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
S.timewin=[-Inf Inf];
S.freqwin=[-Inf Inf];
S.channels=E.chanlabels(E.meegchannels('EEG'));
pE=spm_eeg_crop(S) % writes new file with prefix 'p'


%% 1. EEG: filter HP>1Hz (necessary before downsampling because of edge effects!)
%  ____________________________________________
% >> help spm_eeg_filter
%   Filter M/EEG data
%   FORMAT D = spm_eeg_filter(S)
%  
%   S           - input structure (optional)
%   (optional) fields of S:
%     S.D       - MEEG object or filename of M/EEG mat-file
%     S.filter  - struct with the following fields:
%        type       - optional filter type, can be
%                      'but' Butterworth IIR filter (default)
%                      'fir' FIR filter using Matlab fir1 function
%        order      - filter order (default - 5 for Butterworth)
%        band       - filterband [low|high|bandpass|stop]
%        PHz        - cutoff frequency [Hz]
%        dir        - optional filter direction, can be
%                     'onepass'         forward filter only
%                     'onepass-reverse' reverse filter only, i.e. backward in time
%                     'twopass'         zero-phase forward and reverse filter
%                  
%   D           - MEEG object (also written to disk)
%  ____________________________________________

S = [];
S.D = pE;
S.filter.band = 'high';
S.filter.PHz = 11;

tic
fpE = spm_eeg_filter(S);
toc

% E = fE;

%  =============
%% 2. EEG: downsample
%  ____________________________________________
% >> help spm_eeg_downsample
%   Downsample M/EEG data
%   FORMAT D = spm_eeg_downsample(S)
%  
%   S               - optional input struct
%   (optional) fields of S:
%     S.D           - MEEG object or filename of M/EEG mat-file
%     S.fsample_new - new sampling rate, must be lower than the original one
%     S.prefix      - prefix of generated file
%  
%   D               - MEEG object (also written on disk)
%  ____________________________________________
S = [];
S.D = fpE;
S.fsample_new = 200;
S.prefix = 'd';

tic
dfpE = spm_eeg_downsample(S);
toc

% E = dfE;

%  ==========================
%% 3. filter LP (e.g. <45Hz):
S = [];
S.D = dfpE;
S.filter.band = 'low';
S.filter.PHz = 16;

tic
fdfpE = spm_eeg_filter(S);
toc


% baseline correction
spindelDur=importdata('spindel_durations.txt');
spindelDurMax=max(spindelDur); %taken as common offset to all events for following bc
bcTimeEnd=(-pE.timeonset*1000 - round((spindelDurMax/2)*1000));
bcTimeStart=bcTimeEnd-1000;
if bcTimeStart<0
  sprintf('\nCAVE: baseline start is negative (%dms)!!!\n\n',bcTimeStart)
end

%  __________________________________________________________________________
%  spm_eeg_bc
%   'Baseline Correction' for M/EEG data
%   FORMAT D = spm_eeg_bc(S)
%  
%   S        - optional input struct
%   (optional) fields of S:
%     S.D    - MEEG object or filename of M/EEG mat-file with epoched data
%     S.time - 2-element vector with start and end of baseline period [ms]
%     S.save - save the baseline corrected data in a separate file [default: true]
%     S.updatehistory - update history information [default: true]
%  
%   D        - MEEG object (also saved on disk if requested)
%  __________________________________________________________________________
%  
%   Subtract average baseline from all M/EEG and EOG channels
%  __________________________________________________________________________
%   Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

S=[];
S.D=fdfpE;
S.time=[bcTimeStart, bcTimeEnd] %ms
S.save=true;
S.updatehistory=true;

bfdfpE=spm_eeg_bc(S);


% ========================================================================
% ========================================================================
%%===== focus on MEG (object M) ==========================================
% ========================================================================
% ========================================================================

%% choose MEG channels
indAllMEG=[find(strcmp(D.chantype,'EEG')),...
           find(strcmp(D.chantype,'EOG')),...
           find(strcmp(D.chantype,'ECG')),...
           find(strcmp(D.chantype,'EMG'))]; % find indices of ~MEG-type channels
% would be more easy: indAllEEG=D.meegchannels('MEG'); CAVE: type 'MEG' not present. also not working for types 'MEGRAD' 'REFGRAD' 'REFMAG'


% indSleepEEG=indAllEEG(find( (indAllEEG.*(~strncmp(D.chanlabels(indAllEEG),'EEG',3))) ~= 0 )); % find indices of pure 'EEG'-chanlabels from EEG-chantypes (Cz,Fz,...)



%% create reduced EEG object M (filename _MEG_*)
% EEG 1: set all but sleepEEG channels to type 'Other'

channelTypesNew=[];
channelTypesNew = cell(size(channelTypesOrig));
for i=1:length(channelTypesNew)
  channelTypesNew{i} = 'Others';
end
% for i=1:length(indSleepEEG)
%   channelTypesNew{indSleepEEG(i)} = 'EEG'; 
% end

D=D.chantype(1:length(channelTypesOrig),channelTypesNew); 

%  __________________________________________________________________________
%  spm_eeg_copy
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

%  __________________________________________________________________________
%  spm_eeg_crop
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
S.timewin=[-Inf Inf];
S.freqwin=[-Inf Inf];
S.channels=E.chanlabels(E.meegchannels('EEG'));
pE=spm_eeg_crop(S) % writes new file with prefix 'p'


%% 1. EEG: filter HP>1Hz (necessary before downsampling because of edge effects!)
%  ____________________________________________
% >> help spm_eeg_filter
%   Filter M/EEG data
%   FORMAT D = spm_eeg_filter(S)
%  
%   S           - input structure (optional)
%   (optional) fields of S:
%     S.D       - MEEG object or filename of M/EEG mat-file
%     S.filter  - struct with the following fields:
%        type       - optional filter type, can be
%                      'but' Butterworth IIR filter (default)
%                      'fir' FIR filter using Matlab fir1 function
%        order      - filter order (default - 5 for Butterworth)
%        band       - filterband [low|high|bandpass|stop]
%        PHz        - cutoff frequency [Hz]
%        dir        - optional filter direction, can be
%                     'onepass'         forward filter only
%                     'onepass-reverse' reverse filter only, i.e. backward in time
%                     'twopass'         zero-phase forward and reverse filter
%                  
%   D           - MEEG object (also written to disk)
%  ____________________________________________

S = [];
S.D = pE;
S.filter.band = 'high';
S.filter.PHz = 11;

tic
fpE = spm_eeg_filter(S);
toc

% E = fE;

%  =============
%% 2. EEG: downsample
%  ____________________________________________
% >> help spm_eeg_downsample
%   Downsample M/EEG data
%   FORMAT D = spm_eeg_downsample(S)
%  
%   S               - optional input struct
%   (optional) fields of S:
%     S.D           - MEEG object or filename of M/EEG mat-file
%     S.fsample_new - new sampling rate, must be lower than the original one
%     S.prefix      - prefix of generated file
%  
%   D               - MEEG object (also written on disk)
%  ____________________________________________
S = [];
S.D = fpE;
S.fsample_new = 200;
S.prefix = 'd';

tic
dfpE = spm_eeg_downsample(S);
toc

% E = dfE;

%  ==========================
%% 3. filter LP (e.g. <45Hz):
S = [];
S.D = dfpE;
S.filter.band = 'low';
S.filter.PHz = 16;

tic
fdfpE = spm_eeg_filter(S);
toc


% baseline correction
spindelDur=importdata('spindel_durations.txt');
spindelDurMax=max(spindelDur); %taken as common offset for following bc
bcTimeEnd=(-pE.timeonset*1000 - round((spindelDurMax/2)*1000));
bcTimeStart=bcTimeEnd-1000;
if bcTimeStart<0
  sprintf('\nCAVE: baseline start is negative (%dms)!!!\n\n',bcTimeStart)
end

%  __________________________________________________________________________
%  spm_eeg_bc
%   'Baseline Correction' for M/EEG data
%   FORMAT D = spm_eeg_bc(S)
%  
%   S        - optional input struct
%   (optional) fields of S:
%     S.D    - MEEG object or filename of M/EEG mat-file with epoched data
%     S.time - 2-element vector with start and end of baseline period [ms]
%     S.save - save the baseline corrected data in a separate file [default: true]
%     S.updatehistory - update history information [default: true]
%  
%   D        - MEEG object (also saved on disk if requested)
%  __________________________________________________________________________
%  
%   Subtract average baseline from all M/EEG and EOG channels
%  __________________________________________________________________________
%   Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

S=[];
S.D=fdfpE;
S.time=[bcTimeStart, bcTimeEnd] %ms
S.save=true;
S.updatehistory=true;

bfdfpE=spm_eeg_bc(S);


























%  =========================================================================

%  ========================================================================
%% 4. eyeblinks meeg-tools (Nolte 2001: 'Partial signal space projection for artefact removal in MEG measurements: a theoretical analysis')
% (includes new "artefact" events, value "eyeblink"):
%  ____________________________________________
% >> help spm_eeg_detect_eyeblinks
%   Detects eyeblinks in spm continuous data file
%   FORMAT  D = spm_eeg_detect_eyeblinks(S)
%  
%   S                    - input structure (optional)
%   (optional) fields of S:
%            .stdthresh  - threshold to reject things that look like
%                           eye-blinks but probably aren't (default: 3)
%            .overwrite  - 1 - replace previous eybelink events (default)
%                          0 - append
%   Output:
%   D                 - MEEG object with added eyeblink events(also
%                       written on disk)
%  ____________________________________________

S = [];
S.D = D;
S.eogchan = 'MZF02';
S.stdthresh = 3;
S.overwrite = 1;

tic
afdflD = spm_eeg_detect_eyeblinks(S);
toc

D = afdflD;





%% 4: EMG 
% emg = [];
% emg{1} = D.selectdata({'EEG061'; 'EEG062';'EEG063'; 'EEG064'},[-0.1 0.6],'rest');
% emg{2} = D.selectdata({'EEG061'; 'EEG062';'EEG063'; 'EEG064'},[-0.1 0.6],'MP');
% emg{3} = D.selectdata({'EEG061'; 'EEG062';'EEG063'; 'EEG064'},[-0.1 0.6],'MI');
% 
% for j = 1:3
%     figure(100+j);
%     clf;
%     if size(emg{j},2)>80
%         maxNum = 80
%     else maxNum = size(emg{j},2)
%     end
%     
%     for i = 1:maxNum %size(emg{2},2)
%         subplot(8,10,i)
%             plot(emg{j}(1,:,i))
%         i = i+1;
%     end
%     switch j 
%         case 1
%             suptitle('EEG061 rest, all trials');
%         case 2
%             suptitle('EEG061 MP, all trials');
%         case 3
%             suptitle('EEG061 MI, all trials');
%     end
%     j = j+1;
% end


%% 5. artifacts (different methods for different conditions possible):
%  ____________________________________________
% >> help spm_eeg_artefact
%   Simple artefact detection, optionally with robust averaging
%   FORMAT D = spm_eeg_artefact(S)
%  
%   S                     - input structure
%  
%   fields of S:
%     S.D                 - MEEG object or filename of M/EEG mat-file with
%     S.badchanthresh     - fraction of trials with artefacts above which a 
%                           channel is declared as bad (default: 0.2)
%  
%     S.methods           - a structure array with configuration parameters
%                           for artefact detection plugins.
%   Output:
%   D                     - MEEG object (also written on disk)
%  __________________________________________________________________________
%   This is a modular function for which plugins can be developed to detect
%   artefacts with any algorithm. There are 3 basic plugins presently
%   implemented and they can be used as templates for new plugins.
%   The name of a plugin function should start with 'spm_eeg_artefact_'
%  
%   peak2peak (spm_eeg_artefact_peak2peak) - thresholds peak-to-peak
%                                            amplitude
%  
%   jump (spm_eeg_artefact_jump)           - thresholds the difference
%                                            between adjacent samples.
%  
%   flat (spm_eeg_artefact_flat)           - detects flat segments in the
%                                            data
%  ____________________________________________
 S = []; S.D = D.fname;
       
    S.methods(1).fun = 'peak2peak';
    S.methods(1).channels = 'EOG';
    S.methods(1).settings.threshold = 200e-6;
    
    S.methods(end+1).fun = 'peak2peak';
    S.methods(end).channels = 'MEG';
    S.methods(end).settings.threshold = 20e-12;
     
    S.methods(end+1).fun = 'peak2peak';
    S.methods(end).channels = 'MEGPLANAR';
    S.methods(end).settings.threshold = 200e-12;
     
    S.methods(end+1).fun = 'peak2peak';
    S.methods(end).channels = 'EEG';
    S.methods(end).settings.threshold = 100e-6;
    
%     S.methods(end+1).fun = 'flat';
%     S.methods(end).channels = 'All';
%     S.methods(end).settings.threshold = 0; %100e-6;
%     S.methods(end).settings.seqlength = 4;

tic
aeafdflD = spm_eeg_artefact(S);
toc

D = aeafdflD;



%% 6. averaging: robust averaging if a) many trials, b) artifacts are nonoverlapping
% 	=> see meeg preprocessing video on spm website!!!
%  ____________________________________________
% >> help spm_eeg_average
%   Average each channel over trials or trial types
%   FORMAT D = spm_eeg_average(S)
%  
%   S        - optional input struct
%   (optional) fields of S:
%   D        - MEEG object or filename of M/EEG mat-file with epoched data
%   S.robust      - (optional) - use robust averaging
%                   .savew  - save the weights in an additional dataset
%                   .bycondition - compute the weights by condition (1,
%                                  default) or from all trials (0)
%                   .ks     - offset of the weighting function (default: 3)
%   review   - review data after averaging [default: true]
%  
%   Output:
%   D        - MEEG object (also written on disk)
%  ____________________________________________
S = [];
S.D = D;
S.robust.savew = 0;
S.robust.bycondition = 1;
S.robust.ks = 3

tic
maeafdflD = spm_eeg_average(S);
toc

D = maeafdflD;

%% 7. filter LP again after robust averaging (recommended!):

S = [];
S.D = D;
S.filter.band = 'low';
S.filter.PHz = 70;

tic
fmaeafdflD = spm_eeg_filter(S);
toc

D = fmaeafdflD;

fprintf('finished %s!\n',pwd);
cd(currDir)
end
matlabpool close