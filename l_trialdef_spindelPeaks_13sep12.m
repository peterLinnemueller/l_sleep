% spindles=importdata('/data/MEG_HH/data/meg/subj1_sleep_20090114_01.ds/spindelPeaks_Vp01.txt');
spindles=importdata(spm_select);
D = spm_eeg_load(spm_select);
spindelSamples=D.indsample(spindles(1:sum(~isnan(D.indsample(spindles)))));

trl=[spindelSamples'-D.fsample*3 spindelSamples'+D.fsample*3 (-1)*ones(size(spindelSamples,2),1)*D.fsample*3];

conditionlabels = cell(size(trl,1),1);
for i=1:size(conditionlabels,1)
    conditionlabels{i} = 'spindelPeak';
end

save trials_vp03 trl conditionlabels