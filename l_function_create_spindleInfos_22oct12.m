function ret = l_function_create_spindleInfos_22oct12(S)
% function ret = l_function_create_spindleInfos_22oct12(currDir,workDir)
% create mat-struct from subject spindle info file (vpXX_400Hz_Cz.txt)

workDir = S.workDir;
currDir = S.currDir;

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
  
spindlesInfo = [];
for i = 1:size(fileList,1)
  [pathstr,name,ext] = fileparts(fileList{i});
  spindles = importdata(fileList{i},'',4)  % load spindel file, ignore 4 header lines, 
  indInfoLabels = find(~strncmp('',spindles.textdata(:,2),1)) %find text separators
 
  if length(indInfoLabels) ~= 4
    fprintf('\nLeo: error: number infoLabels ~= 4 in file %s!!!\n',fileList{i});
  end
  
    for k=1:length(indInfoLabels)
    spindlesInfo
    end
  
  
  for l=1:size(sensorLabels,1)
    if ~isempty(strfind(name,sensorLabels{l}))
      for m=1:size(conditionlabels,1)
        conditionlabels{m} = ['spindelPeak_',sensorLabels{l}];
        conditionlabelsNonoverlap{m} = ['spindelPeak_',sensorLabels{l},'_nonoverlap'];
      end
    end
  end
  
end