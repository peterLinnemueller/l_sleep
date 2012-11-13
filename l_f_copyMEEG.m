function ret = l_f_copyMEEG(S)
% ret = function l_f_copyMEEG(S.D, S.dirName, S.fileName)
% D: MEEG object, 
% optional: 
%     dirName : target dir, 
%     fileName: target filename 
%
% copy new meeg-object to anaDir:
% CAVE: works for XYT data (3D) only!
% --------------
% ver. 0.1, leo, 7nov12

D = S.D;

if ~isfield(S, 'dirName')
  S.dirName = D.path;
end
if ~isfield(S, 'fileName')
  S.fileName = ['copy_',D.fname];
end

dirName = S.dirName;
fileName = S.fileName;

Dnew = clone(D, fullfile(dirName,fileName));
fprintf('copying %s to %s... \n', fullfile(D.path,D.fname),fullfile(Dnew.path,Dnew.fname));
[r, msg] = copyfile(fullfile(D.path, D.fnamedat), ...
    fullfile(Dnew.path, Dnew.fnamedat), 'f');
if ~r
    error(msg);
end
Dnew.save;

fprintf('...finished!\n');

ret = 1;