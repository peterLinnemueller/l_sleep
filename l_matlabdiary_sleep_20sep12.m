%% l_matlabdiary_sleep, leo 20sep12
% snippets collection

%% general matlab
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
    
    