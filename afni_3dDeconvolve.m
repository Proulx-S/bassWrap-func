function file = runAfni_3dDeconvolve(data,dsgn,scratch)

    



% write data to temporary 1D file

if isempty(scratch)
    file.prefix = tempname;
else
    if ~isfolder(scratch); mkdir(scratch); end
    file.prefix = tempname(scratch);
end
file.data  = [file.prefix '_ts.1D'];
file.xmat  = [file.prefix '.xmat.1D'];
file.stats = [file.prefix '_stats'];


if iscolumn(ts); ts = permute(ts,[2 1]); end
writematrix(ts, file.data,'Delimiter','space','FileType','text');


dsgn = runDsgn;
dsgn.onsetList = 0:10:(length(ts)/sr);
dsgn.n         = length(ts);
dsgn.sr        = sr;
dsgn.model     = 'TENTzero';
dsgn.dr        = 1/0.1;
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
cmd{end+1} = ['-input1D ' file.data ' \'];
cmd{end+1} = ['-TR_1D ' num2str(1/sr) ' \'];
cmd{end+1} = '-polort 0 \';
cmd{end+1} = ['-local_times \'];
[cmdTmp,out] = setAfniDsgn(dsgn,file.data);
cmd = [cmd cmdTmp];
file.resp      = out.respFile;
file.respStd   = out.respStdFile;
file.stimTimes = out.stimFile;



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
        cmd{end+1} = '-bout -fout \';
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
            cmd{end+1} = ['-bucket ' char(file.stats)];
        % else
        %     cmd{end+1} = ['-bucket ' char(file.stats) ' 2>/dev/null'];
        % end
    % else
    %     cmd{end}(end-1:end) = [];
    % end
    %%%%%%%%%%%%%%
    %%% GET AROUND LINUX PATH LENGTH SOFT LIMITATION
    % fMatTmp3 = char(replace(fMat,'.xmat.1D','.xmatCnsrClmn.1D'));
    cmd{end+1} = ['cp ' char(fMatTmp) ' ' char(file.xmat)];
    % if ~isempty(cnsr)
    %     cmd{end+1} = ['cp ' char(fMatTmp2) ' ' fMatTmp3];
    % elseif exist(fMatTmp3,'file') % if this file exists, it is garbage from a previous run and can interfere in plotDsgnMat.m
    %     delete(fMatTmp3);
    % end
    %%%%%%%%%%%%%%

    cmd{end} = replace(cmd{end},' \','');



% getRespAndAct2


disp(strjoin(cmd,newline));
system(strjoin(cmd,newline),'-echo');


resp = readmatrix(file.resp,'FileType','text');
respStd = readmatrix(file.respStd,'FileType','text');
figure('MenuBar','none','Toolbar','none');
errorbar(resp,respStd);
