%% import meg4
clear all
addpath /home/leonhard/MATLAB/usertoolboxes/spm8_r4667/
spm('defaults','eeg'); 
addpath('/home/leonhard/48/scripts')

rootDir = '/home/leonhard/48/mot'
dirList=dir(rootDir)
dirList(1:2)=[] % delete '.' and '..' from folder list
% dirList(1:6)=[] % delete '.' and '..' from folder list

currDir = pwd % should be e.g. ./scripts
matlabpool % open 2 is maximum (and default) on fridi
numFiles=size(dirList,1);
parfor i = 1:numFiles
% for i = 1:numFiles
workDir=[rootDir,'/',dirList(i).name]
cd(workDir)
fprintf('...moving to %s\n',pwd);
fprintf('start processing...\n');

S = [];
S.dataset = workDir % '../ID140-Pre3_BCI_20100907_04.ds';
S.continuous = 1; % force reading trialdef from raw data
S.checkboundary = 0
S.saveorigheader = 1

tic
D = spm_eeg_convert(S) 
toc

EVENTS_DURATION_SECONDS = D.events.duration/D.fsample % all equally long (spm limitation)

% clear S    % clear is not working in parfor!!!!
S = [];

% modify trial labels (uses l_function_strokeMEG_convertTrialLabels_13jun12, leo):
% D = spm_eeg_load 

tic
lD = l_function_strokeMEG_convertTrialLabels_13jun12(D);
toc

D = lD;

%% 1. filter HP>1Hz (necessary before downsampling because of edge effects!)
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
S.D = D;
S.filter.band = 'high';
S.filter.PHz = 2;

tic
flD = spm_eeg_filter(S);
toc

D = flD;

%% 2. downsample
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
S.D = D;
S.fsample_new = 200;
S.prefix = 'd';

tic
dflD = spm_eeg_downsample(S);
toc

D = dflD;

% 3. filter LP (e.g. <45Hz):

S = [];
S.D = D;
S.filter.band = 'low';
S.filter.PHz = 70;

tic
fdflD = spm_eeg_filter(S);
toc

D = fdflD;

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



%% 4. epoch

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
S.bc = 1;
S.pretrig = -100;
S.posttrig = 600;

hand = D.conditions{1}(1:2); % RH or LH condition
S.trialdef(1).conditionlabel = 'rest';
S.trialdef(1).eventtype = [hand,'_rest_auf'];
S.trialdef(1).eventvalue = [];
S.trialdef(2).conditionlabel = 'rest';
S.trialdef(2).eventtype = [hand,'_rest_zu'];
S.trialdef(2).eventvalue = [];
S.trialdef(3).conditionlabel = 'MP';
S.trialdef(3).eventtype = [hand,'_MP_auf'];
S.trialdef(3).eventvalue = [];
S.trialdef(4).conditionlabel = 'MP';
S.trialdef(4).eventtype = [hand,'_MP_zu'];
S.trialdef(4).eventvalue = [];
S.trialdef(5).conditionlabel = 'MI';
S.trialdef(5).eventtype = [hand,'_MI_auf'];
S.trialdef(5).eventvalue = [];
S.trialdef(6).conditionlabel = 'MI';
S.trialdef(6).eventtype = [hand,'_MI_zu'];
S.trialdef(6).eventvalue = [];
S.trialdef(7).conditionlabel = 'eyeblink';
S.trialdef(7).eventtype = 'artefact';
S.trialdef(7).eventvalue = [];
S.reviewtrials = 0;
S.save = 0;

tic
eafdflD = spm_eeg_epochs(S)
toc 

D = eafdflD;

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