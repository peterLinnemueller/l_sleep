function ret = l_function_create_spindleInfos_26oct12(S)
% function ret = l_function_create_spindleInfos_22oct12(currDir,workDir)
% create struct 'spindleInfo' from subject's (workDir) spindle info files 
% (vpXX_400Hz_{Cz,C3,C4,F3,F4,Fz}.txt) and sleep stage files (vpXX.txt) 
% and saves it to 'spindleInfos.mat'
% --------------------
% Version: v0.7, 01nov12, leo

workDir = S.workDir;
currDir = S.currDir;

% % testing:
% clear all
% workDir='/data1/sleep/meg/s01/Vp01/subj1_sleep_20090114_01.ds'
% currDir=pwd

cd(workDir)

  fprintf(['\nexecuting l_function_create_spindleInfos_22oct12(\n\tworkDir=%s,',...
          '\n\tcurrDir=%s)\n'], workDir, currDir);
  fprintf('\n...moving to %s\n',pwd);
  fprintf('\nstart processing...\n');
  
  NAME_FILE_LIST=['fileList_spindelData_',date,'.txt']

s = ['find -L ../Vp* -mindepth 1 -maxdepth 1 -type f  | ',...
    'grep -E ".*_400Hz_.*\.txt$" |',...
    'sort -n > ',NAME_FILE_LIST]

system(s);
fileList = importdata(NAME_FILE_LIST) % create cellarray of input dirs

sensorLabels = cellstr(['C3';'C4';'Cz';'F3';'F4';'Fz']);
  
spindleInfo = [];
for i = 1:size(fileList,1)
  [pathstr,name,ext] = fileparts(fileList{i});
  %   spindles = importdata(fileList{i},'',4)  % load spindel file, ignore 4 header lines,
  
  fid = fopen(fileList{i});
  spindles = textscan(fid,'%s','Delimiter','\n')
  fclose(fid);
  
  %     indInfoLabels = find(~strncmp('',spindles.textdata(:,2),1)) %find text separators
  tmp_labels=[]
  for l=1:size(spindles{1,1},1)
    tmp_labels(l) = isempty(str2num(spindles{1,1}{l})); %find text lines
  end
  indInfo = find(diff(tmp_labels)==-1) +1 %ind of first value per spindle information (peaks, rms, duration,p2p)
  
  
  if length(indInfo) ~= 4 %check, if number info types (peaks, rms, duration,p2p) equals 4
    fprintf('\nLeo: error: number infoLabels ~= 4 in file %s!!!\n',fileList{i});
  end
  
  %   for k=1:length(indInfo)
  spindleInfo(i).info(1).subjectDir = workDir;
  spindleInfo(i).info(1).samplingFreq = 400;  % sampling frequency hardcoded 400Hz!
  spindleInfo(i).info(1).fileDir = fileList{i};
  spindleInfo(i).sensor = sensorLabels(strcmp(name(end-1:end), sensorLabels)) %find sensor corresponding to last two leters in 'name'
  
  peak1 = 0;
  for peak2=indInfo(1):indInfo(2)-3
    peak1=peak1+1;
    spindleInfo(i).peakOnsets(peak1) = spindles{1,1}(peak2);
  end
  peak1 = 0;
  for peak2=indInfo(2):indInfo(3)-3
    peak1=peak1+1;
    spindleInfo(i).p2p(peak1) = spindles{1,1}(peak2);
  end
  peak1 = 0;
  for peak2=indInfo(3):indInfo(4)-3
    peak1=peak1+1;
    spindleInfo(i).rms(peak1) = spindles{1,1}(peak2);
  end
  peak1 = 0;
  for peak2=indInfo(4):size(spindles{1,1},1)
    peak1=peak1+1;
    spindleInfo(i).duration(peak1) = spindles{1,1}(peak2);
  end
  
  %   end
  
  
%   for l=1:size(sensorLabels,1)
%     if ~isempty(strfind(name,sensorLabels{l}))
%       for m=1:size(conditionlabels,1)
%         conditionlabels{m} = ['spindelPeak_',sensorLabels{l}];
%         conditionlabelsNonoverlap{m} = ['spindelPeak_',sensorLabels{l},'_nonoverlap'];
%       end
%     end
%   end
  
end

save spindleInfo spindleInfo

cd(currDir)
ret = 1;