function setAfniDsgn(dsgn,data,param,dryRun,scratchDir)
    if ~exist('scratchDir', 'var'); scratchDir = []; end
    if ~isempty(scratchDir) && ~endsWith(scratchDir, [filesep 'tmp']); scratchDir = fullfile(scratchDir, 'tmp'); end
    if isempty(param) || ~isfield(param,'model') || isempty(param.model); param.model = 'TENTzero'; end

    % Assert data
    switch class(data)
        case {'double', 'single', 'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'}
            % write data to temporary 1D file
            if isempty(scratchDir)
                dataFile = tempname;
            else
                if ~isfolder(scratchDir); mkdir(scratchDir); end
                dataFile = tempname(scratchDir);
            end
            dataFile = [dataFile '.1D'];
            if iscolumn(data); data = permute(data,[2 1]); end
            writematrix(data, dataFile,'Delimiter','space','FileType','text');
            
            
        otherwise
            dbstack; error(['data is of type ' class(data) '(not implemented)']);
    end

    % Assert dsgn
    switch class(dsgn)
        case 'runDsgn'
            if ~isfolder(scratchDir); mkdir(scratchDir); end
            stimFile = replace(dataFile,'.1D','_startTimes.1D');
            writematrix(dsgn.onsetList, stimFile,'Delimiter','space','FileType','text');
        otherwise
            dbstack; error(['dsgn is of type ' class(dsgn) '(not implemented)']);
    end


    




    cmd = {};
    % if param.PCflag
    %     cmd{end+1} = ['-stim_label ' num2str(k)            ' ' [char(dsgn.task) '_' dsgn.condLabel{k} 'Real'] ' \'];
    %     cmd{end+1} = ['-stim_label ' num2str(dsgn.condK+k) ' ' [char(dsgn.task) '_' dsgn.condLabel{k} 'Imag'] ' \'];
    % else
    %     cmd{end+1} = ['-stim_label ' num2str(k) ' ' [char(dsgn.task) '_' dsgn.condLabel{k}] ' \'];
    % end

    % % write design to file
    % if dryRun
    %     fStim = [tempname '_startTime.1D' ];
    % end

    % if param.PCflag
    %     %real
    %     fido = fopen(fStim{:,:,1}, 'w');
    %     for i = 1:size(fIn,1)
    %         fprintf(fido,'%.3f ',dsgn.onsetList(kList(k)==dsgn.cond));
    %         fprintf(fido,'\n');
    %     end
    %     for i = 1:size(fIn,1)
    %         fprintf(fido,'*');
    %         fprintf(fido,'\n');
    %     end
    %     fclose(fido);
    %     %imag
    %     fido = fopen(fStim{:,:,2}, 'w');
    %     for i = 1:size(fIn,1)
    %         fprintf(fido,'*');
    %         fprintf(fido,'\n');
    %     end
    %     for i = 1:size(fIn,1)
    %         fprintf(fido,'%.3f ',dsgn.onsetList(kList(k)==dsgn.cond));
    %         fprintf(fido,'\n');
    %     end
    %     fclose(fido);
    % else
    %     fido = fopen(char(fStim), 'w');
    %     if ~iscell(fIn); dbstack; error('fIn must be type cell'); end
    %     for i = 1:size(fIn,1)
    %         fprintf(fido,'%.3f ',dsgn.onsetList(kList(k)==dsgn.cond));
    %         fprintf(fido,'\n');
    %     end
    %     fclose(fido);
    % end

    kList = sort(unique(dsgn.cond));
    for k = 1:dsgn.condK
        cmd{end+1} = ['-stim_label ' num2str(k) ' ' [char(dsgn.task) '_' dsgn.condLabel{k}] ' \'];
    
        % Set model
        switch param.model
            case 'SPMG2'
                dbstack; error('double-check that')
                dur = dsgn.ondurList(kList(k)==dsgn.cond); if ~isempty(dur) && any(diff(dur)); dbstack; error('stim duration cannot be different across trials'); end
                dur = dur(1);
                nReg = 2;
                cmd{end+1} = ['-stim_times ' num2str(k) ' ' fStim{k} ' ''' param.model '(' num2str(dur,'%0.3f') ')'' \'];
                nRegAll(k) = nReg;
            case 'SPMG3'
                dbstack; error('double-check that')
                nReg = 3;
                if max(abs(diff(durSeq)))/max(durSeq) > 0.0001; dbstack; error('stim duration cannot be different across trials'); end
                cmd{end+1} = ['-stim_times ' num2str(k) ' ' fStim ' ''' HRmodel '(' num2str(mean(durSeq),'%0.3f') ')'' \'];
            case 'TENT'
                dbstack; error('code that')
            case 'TENTzero'
                % set the deconvolution window to the maximum (all the way up to the next stimulus or the end of the run)
                eTime     = dsgn.onsetList(dsgn.cond==kList(k));
                eTimeNext = find(dsgn.cond==kList(k))+1;
                if eTimeNext(end) > length(dsgn.onsetList)
                    eTimeNext(end) = [];
                    eTimeNext = dsgn.onsetList(eTimeNext);
                    eTimeNext(end+1) = max(param.nFrame) * mean(param.tr); % use max nFrame in case of a run interruption
                    % eTimeNext(end+1) = (param.nFrame + mode(param.nFrameOrig - param.nFrame)) * mean(param.tr);
                else
                    eTimeNext = dsgn.onsetList(eTimeNext);
                end
                deconWin = min(eTimeNext - eTime);
                if isfield(param,'durDecon') && ~isempty(param.durDecon)
                    deconWin = deconWin.*param.durDecon;
                end
                % deconWin = deconWin - 3*tr; % ensure at least one acquisition tr (not trDecon) of baseline between each stimulus
                if (deconWin/param.trDecon)/ceil(deconWin/param.trDecon)>0.9
                    deconWin = ceil(deconWin/param.trDecon)*param.trDecon;
                else
                    deconWin = floor(deconWin/param.trDecon)*param.trDecon;
                end
                b = 0;
                c = round((deconWin-param.trDecon)/param.trDecon)*param.trDecon;
                nReg = round( (c-b)/param.trDecon + 1 );
                % (c-b)/(nReg-1)
                if param.PCflag
                    cmd{end+1} = ['-stim_times ' num2str(k)            ' ' fStim{:,:,1} ' ''TENTzero(' num2str(b) ',' num2str(c) ',' num2str(nReg) ')'' \'];
                    cmd{end+1} = ['-stim_times ' num2str(dsgn.condK+k) ' ' fStim{:,:,2} ' ''TENTzero(' num2str(b) ',' num2str(c) ',' num2str(nReg) ')'' \'];
                else
                    cmd{end+1} = ['-stim_times ' num2str(k) ' ' char(fStim) ' ''TENTzero(' num2str(b) ',' num2str(c) ',' num2str(nReg) ')'' \'];
                end
                nReg = nReg - 2;
                if ~dryRun
                    if param.PCflag
                        cmd{end+1} = ['-iresp ' num2str(k)            ' ' fResp{:,:,1}    ' \'];
                        cmd{end+1} = ['-sresp ' num2str(k)            ' ' fRespStd{:,:,1} ' \'];
                        cmd{end+1} = ['-iresp ' num2str(dsgn.condK+k) ' ' fResp{:,:,2}    ' \'];
                        cmd{end+1} = ['-sresp ' num2str(dsgn.condK+k) ' ' fRespStd{:,:,2} ' \'];
                    else
                        cmd{end+1} = ['-iresp ' num2str(k) ' ' char(fResp)    ' \'];
                        cmd{end+1} = ['-sresp ' num2str(k) ' ' char(fRespStd) ' \'];
                    end
                end
            otherwise
                dbstak; error('X');
        end
    end