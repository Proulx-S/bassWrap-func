function deconStruct = afni_3dDeconvolve_readStats(deconStruct)
global src


% Read desgn matrix
deconStruct.dsgn.xMat = afni_readDsgnMat(deconStruct.files.xmat,deconStruct.dsgn);

% Write stats to nifti files
if ~isfield(deconStruct.res,'stats') || isempty(deconStruct.res.stats)
    stats = afni_3dDeconvolve_writeStats(deconStruct.files.stats);
    deconStruct.res.files.bucket = stats.bucket;
    fieldList = fieldnames(deconStruct.res.files); fieldList{end} = 'bucket'; fieldList = fieldList([1 length(fieldList) 2:length(fieldList)-1]);
    deconStruct.res.files = orderfields(deconStruct.res.files, fieldList);
    deconStruct.res.files = cell2struct([struct2cell(deconStruct.res.files); struct2cell(stats.files)], ...
                                        [fieldnames(deconStruct.res.files) ; fieldnames(stats.files) ]);
    deconStruct.res.stats = stats.files;
    clear stats;
end

% % inputType = 'afni bucket file path'
% if ismember(class(stats), {'struct'})
%     if all(ismember({'files' 'bucket'},fields(stats)))
%         inputType = '3dDeconvolve results struct';
%     elseif all(ismember({'files' 'stats'},fields(stats)))
%         inputType = '3dDeconvolve full struct';
%     else
%         inputType = '3dDeconvolve file struct';
%     end
% else
%     error('stats must be a string or a struct');
% end


% switch inputType
%     case '3dDeconvolve file struct'
%         stats = afni_3dDeconvolve_writeStats(stats.stats);
%         stats = afni_3dDeconvolve_readStats(stats);

%         % fieldList = fields(stats.file);
%         % fieldList = fieldList(~ismember(fieldList, {'bucket'}));
%         % for i = 1:numel(fieldList)
%         %     delete(stats.file.(fieldList{i}));
%         %     stats.file = rmfield(stats.file, fieldList{i});
%         % end

%         return
%     case '3dDeconvolve results struct'
%         % do nothing
%     case '3dDeconvolve full struct'
%         stats.stats = afni_3dDeconvolve_readStats(stats.stats);
%         return
%     otherwise
%         error('stats must be a string or a struct');
% end

% Read back to matlab
labelList = {'FullR2', 'FullFstat', 'TaskR2', 'TaskFstat'};
for i = 1:numel(labelList)
    stats.mri     = MRIread(deconStruct.res.files.(labelList{i}));
    stats.statAux = getStatAux(deconStruct.res.files.bucket.file, deconStruct.res.files.bucket.brikIdx.(labelList{i}));
    deconStruct.res.stats.(labelList{i}) = stats;
    % deconStruct.res.stats.(labelList{i}).mri = MRIread(deconStruct.res.files.(labelList{i}));
    % deconStruct.res.(labelList{i}).statAux = getStatAux(deconStruct.res.bucket.file, deconStruct.res.bucket.brikIdx.(labelList{i}));
end




function statAux = getStatAux(bucketFile, bucketIdx)
global src
cmd = {src.afni};
cmd{end+1} = ['3dAttribute BRICK_STATAUX ' bucketFile '+orig[' num2str(bucketIdx) ']'];
[statcodeStr,status] = runSysCmd(cmd);
statAux = str2double(strsplit(strtrim(statcodeStr),' '));







