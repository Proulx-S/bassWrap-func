function res = afni_3dDeconvolve_writeStats(statsFile)
% afni_3dDeconvolve_writeStats - Extract and write statistics from AFNI 3dDeconvolve bucket file
%
% Syntax:
%   res = afni_3dDeconvolve_writeStats(statsFile)
%
% Inputs:
%   statsFile - String prefix for the AFNI bucket file (e.g., 'prefix_stats')
%                The function will look for statsFile+orig.HEAD and statsFile+orig.BRIK
%
% Outputs:
%   res      - Structure containing file paths and indices:
%                .file.bucket        - Original bucket file prefix
%                .brik.labels        - Cell array of sub-brick labels
%                .file.FullR2        - Path to FullR2 output file (.nii.gz)
%                .file.FullFstat     - Path to FullFstat output file (.nii.gz)
%                .file.TaskR2        - Path to TaskR2 output file (.nii.gz)
%                .file.TaskFstat     - Path to TaskFstat output file (.nii.gz)
%                .file.baselineCoef  - Path to baselineCoef output file (.nii.gz)
%                .fileBucketIdx      - Structure with bucket indices for each statistic
%
% Description:
%   Extracts specific statistics from an AFNI 3dDeconvolve bucket file (+orig.BRIK/+orig.HEAD format)
%   and writes them to separate NII files. Uses 3dinfo to extract sub-brick labels and 3dbucket
%   to extract and save individual statistics. The function extracts:
%   - FullR2: Full model R-squared statistic
%   - FullFstat: Full model F-statistic
%   - TaskR2: Task model R-squared statistic
%   - TaskFstat: Task model F-statistic
%   - baselineCoef: Baseline coefficient (Run#*Pol#0_Coef)
%
% Example:
%   stats = afni_3dDeconvolve_writeStats('my_analysis_stats');
%
% See also: 3dinfo, 3dbucket

global src

% Check if statsFile is provided
if ~exist('statsFile','var') || isempty(statsFile)
    error('statsFile must be provided');
end

% Construct full path to the bucket file
% AFNI bucket files use +orig.HEAD and +orig.BRIK extensions
if length(statsFile) >= 5 && strcmp(statsFile(end-4:end), '+orig')
    filePath = statsFile;
    statsFile = statsFile(1:end-5); % Remove '+orig' suffix
else
    filePath = [statsFile '+orig'];
end

% Check if the file exists
if ~exist([filePath '.HEAD'], 'file')
    error('AFNI bucket file not found: %s.HEAD', filePath);
end

% Store file information
res = struct();
res.bucket.file = statsFile;

% Get sub-brick information using 3dinfo
if ~exist('src','var') || ~isfield(src,'afni') || isempty(src.afni)
    error('Global variable src.afni must be set to AFNI installation path');
end


% Get sub-brick labels
cmd = {src.afni};
cmd{end+1} = ['3dinfo -label ' res.bucket.file '+orig'];
[brickLabelsStr,status] = runSysCmd(cmd);
if status ~= 0
    error('Failed to get sub-brick labels from %s: %s', filePath, brickLabelsStr);
end
res.bucket.brikLabels = strsplit(strtrim(brickLabelsStr),'|')';




% Write FullR2
statSuffix = 'FullR2';
statIdx = startsWith(res.bucket.brikLabels, 'Full_');
statIdx = endsWith(res.bucket.brikLabels, '_R^2') & statIdx;
res.files.(statSuffix)          = [res.bucket.file '-' statSuffix '.nii.gz'];
res.bucket.brikIdx.(statSuffix) = find(statIdx)-1;
brick2nii(res.bucket.file, res.bucket.brikIdx.(statSuffix), res.files.(statSuffix));

% Write FullFstat
statSuffix = 'FullFstat';
statIdx = startsWith(res.bucket.brikLabels, 'Full_');
statIdx = endsWith(res.bucket.brikLabels, '_Fstat') & statIdx;
res.files.(statSuffix) = [res.bucket.file '-' statSuffix '.nii.gz'];
res.bucket.brikIdx.(statSuffix) = find(statIdx)-1;
brick2nii(res.bucket.file, res.bucket.brikIdx.(statSuffix), res.files.(statSuffix));


% Write TaskR2
statSuffix = 'TaskR2';
statIdx = startsWith(res.bucket.brikLabels, 'task_');
statIdx = endsWith(res.bucket.brikLabels, '_R^2') & statIdx;
if nnz(statIdx)>1
    dbstack;
    error('Multiple task conditions. Code that');
end
res.files.(statSuffix) = [res.bucket.file '-' statSuffix '.nii.gz'];
res.bucket.brikIdx.(statSuffix) = find(statIdx)-1;
brick2nii(res.bucket.file, res.bucket.brikIdx.(statSuffix), res.files.(statSuffix));

% Write TaskFstat
statSuffix = 'TaskFstat';
statIdx = startsWith(res.bucket.brikLabels, 'task_');
statIdx = endsWith(res.bucket.brikLabels, '_Fstat') & statIdx;
res.files.(statSuffix) = [res.bucket.file '-' statSuffix '.nii.gz'];
res.bucket.brikIdx.(statSuffix) = find(statIdx)-1;
brick2nii(res.bucket.file, res.bucket.brikIdx.(statSuffix), res.files.(statSuffix));

% Write BaselineCoef
statSuffix = 'baselineCoef';
statIdx = startsWith(res.bucket.brikLabels, 'Run#');
statIdx = endsWith(res.bucket.brikLabels, 'Pol#0_Coef') & statIdx;
res.files.(statSuffix) = [res.bucket.file '-' statSuffix '.nii.gz'];
res.bucket.brikIdx.(statSuffix) = find(statIdx)-1;
brick2nii(res.bucket.file, res.bucket.brikIdx.(statSuffix), res.files.(statSuffix));








function outputFile = brick2nii(bucketFile, statIdx, outputFile)
% brick2nii - Extract sub-bricks from AFNI bucket file using 3dbucket
%
% Syntax:
%   outputFile = brick2nii(bucketFile, statIdx, outputFile)
%
% Inputs:
%   bucketFile  - Prefix of the bucket file (without +orig)
%   statIdx     - Logical index of which sub-bricks to extract
%   outputFile  - Full path to the output file
%
% Outputs:
%   outputFile  - Full path to the extracted file (same as input)
%
% Description:
%   Extracts specified sub-bricks from an AFNI bucket file using 3dbucket
%   and saves them to a new file.

global src

% Build 3dbucket command
cmd = {src.afni};
% Convert logical index to sub-brick indices (0-based for AFNI)
subBrickIndices = statIdx;
if length(subBrickIndices) == 1
    % Single sub-brick
    brickSelector = num2str(subBrickIndices);
else
    % Multiple sub-bricks - join with commas
    brickSelector = strjoin(arrayfun(@num2str, subBrickIndices, 'UniformOutput', false), ',');
end
cmd{end+1} = ['3dbucket -overwrite -prefix ' outputFile ' ' bucketFile '+orig[' brickSelector ']'];

% Execute command
[~,status] = runSysCmd(cmd);
if status ~= 0
    error('Failed to write output file: %s', outputFile);
end



