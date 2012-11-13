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
% matlabpool open 7
numFiles=size(folderList,1);

% parfor i = 1:numFiles
% for i = 1:numFiles
i=1
workDir=[rootDir,'/',folderList{i}(3:end)]
cd(workDir)
fprintf('...moving to %s\n',pwd);
fprintf('start processing...\n');

%  =============
%% load data set
E = spm_eeg_load(spm_select('FPList',workDir,'^bfdfp.*spm8_subj.*.mat$'))

size(E)

pst=(-1:1/E.fsample:1); %in seconds
pstSamples=E.indsample(pst);
data=squeeze(E(find(strcmp(E.chanlabels,'Cz')),pstSamples,:)).*1e6;
mData=mean(data');

figure(101);
clf;
plot(pst,data);
hold on;
  hline1=plot(pst,mData,'k'); 
  set(hline1,'lineWidth',5');
hold off
title(['EEG Cz ',folderList(i),'n=',size(data,2)])
% title('$\beta$','interpreter','latex')
xlabel('spindlePeaks pst[s]')
ylabel('amplitude[myV?] (data.*1e6)')


%% check for overlapping events
ton=[D.trialonset'-3,D.trialonset'+3];
j=1;
ton2=[];
for i=1:size(ton,1)
   ton2(j)=ton(i,1);
   j=j+1;
   ton2(j)=ton(i,2);
   j=j+1;
end
sum(size(find(diff(ton2)<0)),2)
% end %parfor