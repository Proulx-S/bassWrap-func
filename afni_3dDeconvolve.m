function [files,dsgn,cmd,cmdOut,res] = afni_3dDeconvolve(data,dsgn,scratch,verbose)
    global src
    if ~exist('verbose','var') || isempty(verbose); verbose = false; end
        


    if isempty(scratch)
        files.prefix = tempname;
    else
        if ~isfolder(scratch); mkdir(scratch); end
        files.prefix = tempname(scratch);
    end
    files.cmd   = [files.prefix '_cmd-3dDeconvolve.txt'];
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



    dsgn = assertDsgn(dsgn);

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
    [cmdTmp,tmpFiles,dsgn] = afni_setDsgn(dsgn,files.data);
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



    cmdOut = runSysCmd(cmd, files.cmd, verbose);





    %% Read back results
    res.xMat = afni_readDsgnMat(files.xmat,dsgn);
    res.resp = readmatrix(files.resp,'FileType','text');
    res.respStd = readmatrix(files.respStd,'FileType','text');

    voxelData = parseVoxelResultsFromCmdOut(cmdOut);
    sectionStruct = parseAfniDeconvolveSections(voxelData.text);
    for i = 1:length(sectionStruct.stimulus)
        [~,res.respStats(i)] = parseSectionStats(sectionStruct.stimulus{i});
    end
    [res.baseline,~] = parseSectionStats(sectionStruct.baseline{1});
    [~,res.fullStats] = parseSectionStats(sectionStruct.fullModel{1});

    res.resp = res.resp + res.baseline;

    res.dsgn = dsgn;

    % clean tmp files
    delete([files.prefix '*']);
end



function sectionStruct = parseAfniDeconvolveSections(text)
    % Parse sections in AFNI Deconvolve output by headings
    % Returns struct with .baseline (cell), .stimulus (cell array), .fullModel (cell)
    % Header lines are removed from each section
    lines = regexp(text, '\r?\n', 'split');
    currentSection = {};
    currentTitle = '';
    
    sectionStruct = struct();
    sectionStruct.baseline = {};
    sectionStruct.stimulus = {};
    sectionStruct.fullModel = {};
    
    for i = 1:length(lines)
        line = strtrim(lines{i});
        
        % Check for empty lines - close current section if it has content
        if isempty(line)
            if ~isempty(currentTitle) && ~isempty(currentSection)
                sectionText = strjoin(currentSection, newline);
                if strcmp(currentTitle, 'Baseline')
                    sectionStruct.baseline{end+1} = sectionText;
                elseif startsWith(currentTitle, 'Stimulus')
                    sectionStruct.stimulus{end+1} = sectionText;
                elseif strcmp(currentTitle, 'Full Model')
                    sectionStruct.fullModel{end+1} = sectionText;
                end
                currentSection = {};
                currentTitle = '';
            end
            continue
        end
        
        % Check for section headers
        if startsWith(line, 'Baseline:')
            % Save previous section if it exists
            if ~isempty(currentTitle) && ~isempty(currentSection)
                sectionText = strjoin(currentSection, newline);
                if strcmp(currentTitle, 'Baseline')
                    sectionStruct.baseline{end+1} = sectionText;
                elseif startsWith(currentTitle, 'Stimulus')
                    sectionStruct.stimulus{end+1} = sectionText;
                elseif strcmp(currentTitle, 'Full Model')
                    sectionStruct.fullModel{end+1} = sectionText;
                end
            end
            % Start new baseline section (don't include header line)
            currentSection = {};
            currentTitle = 'Baseline';
        elseif startsWith(line, 'Stimulus:')
            % Save previous section if it exists
            if ~isempty(currentTitle) && ~isempty(currentSection)
                sectionText = strjoin(currentSection, newline);
                if strcmp(currentTitle, 'Baseline')
                    sectionStruct.baseline{end+1} = sectionText;
                elseif startsWith(currentTitle, 'Stimulus')
                    sectionStruct.stimulus{end+1} = sectionText;
                elseif strcmp(currentTitle, 'Full Model')
                    sectionStruct.fullModel{end+1} = sectionText;
                end
            end
            % Start new stimulus section (don't include header line)
            currentSection = {};
            currentTitle = sprintf('Stimulus%d', length(sectionStruct.stimulus) + 1);
        elseif startsWith(line, 'Full Model:')
            % Save previous section if it exists
            if ~isempty(currentTitle) && ~isempty(currentSection)
                sectionText = strjoin(currentSection, newline);
                if strcmp(currentTitle, 'Baseline')
                    sectionStruct.baseline{end+1} = sectionText;
                elseif startsWith(currentTitle, 'Stimulus')
                    sectionStruct.stimulus{end+1} = sectionText;
                elseif strcmp(currentTitle, 'Full Model')
                    sectionStruct.fullModel{end+1} = sectionText;
                end
            end
            % Start new full model section (don't include header line)
            currentSection = {};
            currentTitle = 'Full Model';
        else
            % Add line to current section if we're in one
            if ~isempty(currentTitle)
                currentSection{end+1} = line;
            end
        end
    end
    
    % Save the last section if it exists
    if ~isempty(currentTitle) && ~isempty(currentSection)
        sectionText = strjoin(currentSection, newline);
        if strcmp(currentTitle, 'Baseline')
            sectionStruct.baseline{end+1} = sectionText;
        elseif startsWith(currentTitle, 'Stimulus')
            sectionStruct.stimulus{end+1} = sectionText;
        elseif strcmp(currentTitle, 'Full Model')
            sectionStruct.fullModel{end+1} = sectionText;
        end
    end
    % sectionStruct now has .baseline (cell), .stimulus (cell array), .fullModel (cell)
end



function [coef,stats] = parseSectionStats(sectionText)
    % Parse statistics from a stimulus or fullModel section
    % Extracts coefficients, MSE, R^2, F-statistic (with degrees of freedom), and p-value
    %
    % Input:
    %   sectionText - String containing the section text
    % Output:
    %   coef - Column vector of coefficient values
    %   stats - Struct with fields: MSE, R2, F, F_df1, F_df2, pvalue
    
    coef = [];
    stats = struct('MSE', [], 'R2', [], 'F', [], 'F_df1', [], 'F_df2', [], 'pvalue', []);
    
    % Split into lines
    lines = regexp(sectionText, '\r?\n', 'split');
    nonEmptyLines = lines(~cellfun(@isempty, strtrim(lines)));
    
    if isempty(nonEmptyLines)
        return
    end
    
    % Parse coefficients from all lines
    coefValues = [];
    for i = 1:length(nonEmptyLines)
        line = strtrim(nonEmptyLines{i});
        
        % Check for h[#] coef pattern (stimulus)
        hCoefMatch = regexp(line, 'h\[\s*(\d+)\]\s+coef\s*=\s*([\d.eE+-]+)', 'tokens', 'once');
        if ~isempty(hCoefMatch)
            coefValues(end+1) = str2double(hCoefMatch{2});
            continue
        end
        
        % Check for P_0 coef pattern (baseline)
        p0CoefMatch = regexp(line, 'P_0\s+coef\s*=\s*([\d.eE+-]+)', 'tokens', 'once');
        if ~isempty(p0CoefMatch)
            coefValues(end+1) = str2double(p0CoefMatch{1});
            continue
        end
    end
    
    if ~isempty(coefValues)
        coef = coefValues(:);  % Return as column vector
    end
    
    % Get the last line (or last two lines if MSE is on a separate line)
    lastLine = strtrim(nonEmptyLines{end});
    if length(nonEmptyLines) >= 2
        secondLastLine = strtrim(nonEmptyLines{end-1});
        % Check if second last line has MSE
        if startsWith(secondLastLine, 'MSE')
            lastLine = [secondLastLine ' ' lastLine];
        end
    end
    
    % Parse MSE
    mseMatch = regexp(lastLine, 'MSE\s*=\s*([\d.eE+-]+)', 'tokens', 'once');
    if ~isempty(mseMatch)
        stats.MSE = str2double(mseMatch{1});
    end
    
    % Parse R^2
    r2Match = regexp(lastLine, 'R\^2\s*=\s*([\d.eE+-]+)', 'tokens', 'once');
    if ~isempty(r2Match)
        stats.R2 = str2double(r2Match{1});
    end
    
    % Parse F-statistic: F[df1,df2] = value
    fMatch = regexp(lastLine, 'F\[(\d+),(\d+)\]\s*=\s*([\d.eE+-]+)', 'tokens', 'once');
    if ~isempty(fMatch)
        stats.F_df1 = str2double(fMatch{1});
        stats.F_df2 = str2double(fMatch{2});
        stats.F = str2double(fMatch{3});
    end
    
    % Parse p-value
    pMatch = regexp(lastLine, 'p-value\s*=\s*([\d.eE+-]+)', 'tokens', 'once');
    if ~isempty(pMatch)
        stats.pvalue = str2double(pMatch{1});
    end
end



function voxelData = parseVoxelResultsFromCmdOut(cmdOut)
    % Parse cmdOut for each voxel
    voxelSections = regexp(cmdOut, 'Results for Voxel #\d+:', 'split');
    voxelHeaders = regexp(cmdOut, 'Results for Voxel #\d+:', 'match');

    % The first split section is prior stuff; skip it if headers found
    if ~isempty(voxelHeaders)
        voxelData = struct('header', {}, 'text', {});
        for ii = 1:length(voxelHeaders)
            header = voxelHeaders{ii};
            if ii <= length(voxelSections)-1
                textBlock = strtrim(voxelSections{ii+1}); % Data after this header
            else
                textBlock = '';
            end
            voxelData(ii).header = header;
            voxelData(ii).text = textBlock;
        end
    else
        voxelData = [];
    end
    % Optionally, debugging outputs (disable or enable as needed)
    % disp({voxelData.header});
    % disp({voxelData.text});
    % Now voxelData is an array of structs containing 'header' and 'text' for each voxel
end

