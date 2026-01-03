function stats = afni_3dDeconvolve_readStats(stats)
global src

switch class(stats)
    case 'char'
        stats = afni_3dDeconvolve_writeStats(stats);
        stats = afni_3dDeconvolve_readStats(stats);

        fieldList = fields(stats.file);
        fieldList = fieldList(~ismember(fieldList, {'bucket'}));
        for i = 1:numel(fieldList)
            delete(stats.file.(fieldList{i}));
            stats.file = rmfield(stats.file, fieldList{i});
        end

        return
    case 'struct'
        % do nothing
    otherwise
        error('stats must be a string or a struct');
end

% Read stats back to matlab
labelList = {'FullR2', 'FullFstat', 'TaskR2', 'TaskFstat'};
for i = 1:numel(labelList)
    stats.stats.(labelList{i}).statAux = getStatAux(stats.file.bucket, stats.fileBucketIdx.(labelList{i}));
    stats.stats.(labelList{i}).mri = MRIread(stats.file.(labelList{i}));
end




function statAux = getStatAux(statsFile, statIdx)
global src
cmd = {src.afni};
cmd{end+1} = ['3dAttribute BRICK_STATAUX ' statsFile '+orig[' num2str(statIdx) ']'];
[statcodeStr,status] = runSysCmd(cmd);
statAux = str2double(strsplit(strtrim(statcodeStr),' '));







