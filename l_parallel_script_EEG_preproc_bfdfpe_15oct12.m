clear all
addpath /home/leonhard/spm8_r4667/
spm('defaults','eeg'); 
addpath('/data1/sleep/meg/scripts')

global rootDir
rootDir = '/data1/sleep/meg';

cd(rootDir)
s = ['find -L -mindepth 3 -maxdepth 4 -type d '...
    '| grep -E ".*subj[0-9].*sleep.*_0[1-2]\.ds$" '...
    '| sort -n > folderList_subjMegDirs.txt']
system(s);
folderList = importdata('folderList_subjMegDirs.txt') % create cellarray of input dirs

currDir = pwd % should be e.g. ./scripts
%matlabpool open 7
numFiles=size(folderList,1);

in=[];
in=cell(size(folderList,1),1);
for i=1:size(folderList,1)
%   in{i}=folderList(i)
  in{i}=folderList{i}(2:end) % remove leading '.'
end 
inShort=in(1)

parallel.defaultClusterProfile('local');
c = parcluster();
job1 = createJob(c)
get(job1)
% createTask(job1, @rand, 1, {{3,3} {3,3} {3,3} {3,3} {3,3}});
createTask(job1, @l_function_parallel_script_EEG_preproc_bfdfpe_15oct12, 1,inShort');

get(job1,'Tasks')
submit(job1)
wait(job1)
% results = fetchOutputs(job1)
c
job1
get(job1,'Tasks')