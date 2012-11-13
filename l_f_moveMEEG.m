function ret = l_f_moveMEEG(S)
% ret = function l_f_moveMEEG(S.D, S.dirName, S.fileName)
% D: MEEG object, 
% optional: 
%     dirName : target dir, 
%     fileName: target filename 
%
% move new meeg-object to anaDir (i.e. copy and delete old copy):
% CAVE: works for XYT data (3D) only!
% --------------
% ver. 0.1, leo, 7nov12

D = S.D;

if ~isfield(S, 'dirName')
  S.dirName = D.path;
end
if ~isfield(S, 'fileName')
  S.fileName = ['moved_',D.fname];
end

dirName = S.dirName;
fileName = S.fileName;

% [dummy, fname, dummy] = fileparts(eD.fname);
Dnew = clone(D, fullfile(dirName,fileName));
fprintf('moving %s to %s... \n', fullfile(D.path,D.fname),fullfile(Dnew.path,Dnew.fname));
[r, msg] = copyfile(fullfile(D.path, D.fnamedat), ...
    fullfile(Dnew.path, Dnew.fnamedat), 'f');
if ~r
    error(msg);
end
Dnew.save;

delete(fullfile(D.path,D.fname))
delete(fullfile(D.path,D.fnamedat))

fprintf('...finished!\n');

ret = 1;
