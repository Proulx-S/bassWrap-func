function [files,dsgn,cmd,res] = afni_3dDeconvolve(data,dsgn,scratch)
global src
    




if isempty(scratch)
    files.prefix = tempname;
else
    if ~isfolder(scratch); mkdir(scratch); end
    files.prefix = tempname(scratch);
end
files.cmd   = [files.prefix '_cmd.txt'];
files.data  = [files.prefix '_ts.1D'];
files.data3D = [files.prefix '_tsX'];
files.xmat  = [files.prefix '.xmat.1D'];
files.stats = [files.prefix '_stats'];

% Write data to 1D file (one value per line for proper 3dTcat conversion)
if iscolumn(data); data = permute(data,[2 1]); end
% Format as column vector (one value per line)
% dataCol = data(:);
writematrix(data, files.data,'Delimiter','space','FileType','text');

% % Convert 1D file to AFNI +orig format (single-voxel 3D+time dataset)
% % This forces 3dDeconvolve to output in bucket format
% cmdTcat = {src.afni};
% cmdTcat{end+1} = '3dTcat -overwrite \';
% cmdTcat{end+1} = ['-prefix ' files.data ' \'];
% cmdTcat{end+1} = ['-tr ' num2str(1/dsgn.sr) ' \'];
% cmdTcat{end+1} = files.data;
% system(strjoin(cmdTcat,newline),'-echo');



dsgn = setDsgn(dsgn);

% prefix = {};
% if ~strcmp(dsgn.task,'task'); prefix{end+1} = ['task-' dsgn.task]; end
% % prefix{end+1} = ['cond-FULL'];
% prefix{end+1} = ['model-' dsgn.model];
% prefix = strjoin(prefix,'_');
% % fullfile(scratch, prefix);
% fMat    = fullfile(fileparts(replace(fOut,'.nii.gz','')),['task-' param.dsgn.task '_cond-FULL_model-' HRmodel '_stats.xmat.1D']);

cmd = {src.afni};
cmd{end+1} = '3dDeconvolve -overwrite \';
cmd{end+1} = ['-input1D ' files.data ' \'];
cmd{end+1} = ['-TR_1D ' num2str(1/dsgn.sr) ' \'];
cmd{end+1} = '-polort 0 \';
cmd{end+1} = ['-local_times \'];
[cmdTmp,tmpFiles,dsgn] = setAfniDsgn(dsgn,files.data);
cmd = [cmd cmdTmp];
files.resp      = tmpFiles.resp;
files.respStd   = tmpFiles.respStd;
files.stimTimes = tmpFiles.stimTimes;



% if dryRun
%     dbstack; error('code that')
%     fMat = replace(fMat,'_stats.xmat.1D','_stats.xmatPerTrial.1D');
%     fMat  = [tempname '_stats.xmat.1D'];
% end



    % Set outputs
    % if ~dryRun
    %     if ~isempty(fFit)
    %         cmd{end+1} = ['-fitts ' char(fFit) ' \'];
    %     end
    %     if ~isempty(fResid)
    %         dbstack; error('code that')
    %         cmd{end+1} = ['-errts ' char(fResid) ' \'];
    %     end
        cmd{end+1} = '-bout -fout -rout \';
    % end

    %%%%%%%%%%%%%%
    %%% GET AROUND LINUX PATH LENGTH SOFT LIMITATION
    fMatTmp = [tempname '.xmat.1D'];
    % fMatTmp2 = replace(fMatTmp,'.xmat.1D','X.xmat.1D');
    cmd{end+1} = ['-x1D_uncensored ' char(fMatTmp) ' \'];
    % if ~isempty(cnsr)
    %     cmd{end+1} = ['-x1D_regcensored ' char(fMatTmp2) ' \'];
    % elseif exist(fMatTmp2,'file') % if this file exists, it is garbage from a previous run and can interfere in plotDsgnMat.m
    %     delete(fMatTmp2);
    % end
    %%%%%%%%%%%%%%



    % if ~dryRun
        % if verbose>0
            cmd{end+1} = ['-bucket ' char(files.stats)];
        % else
        %     cmd{end+1} = ['-bucket ' char(file.stats) ' 2>/dev/null'];
        % end
    % else
    %     cmd{end}(end-1:end) = [];
    % end
    %%%%%%%%%%%%%%
    %%% GET AROUND LINUX PATH LENGTH SOFT LIMITATION
    % fMatTmp3 = char(replace(fMat,'.xmat.1D','.xmatCnsrClmn.1D'));
    cmd{end+1} = ['cp ' char(fMatTmp) ' ' char(files.xmat)];
    % if ~isempty(cnsr)
    %     cmd{end+1} = ['cp ' char(fMatTmp2) ' ' fMatTmp3];
    % elseif exist(fMatTmp3,'file') % if this file exists, it is garbage from a previous run and can interfere in plotDsgnMat.m
    %     delete(fMatTmp3);
    % end
    %%%%%%%%%%%%%%

    cmd{end} = replace(cmd{end},' \','');



% getRespAndAct2


disp(strjoin(cmd,newline));
[cmdErr,cmdOut] = system(strjoin(cmd,newline),'-echo'); if cmdErr; dbstack; error(cmdOut); end

% if 1D file, we will have to get stats from cmdOut


fid = fopen(files.cmd, 'w');
fprintf(fid, '%s', strjoin(cmd, newline));
fclose(fid);


%% Read back results

res.resp = readmatrix(files.resp,'FileType','text');
res.respStd = readmatrix(files.respStd,'FileType','text');
res.xMat = afni_readDsgnMat(files.xmat,dsgn);


files.stats


figure('MenuBar','none','Toolbar','none');
errorbar(res.resp,res.respStd);
