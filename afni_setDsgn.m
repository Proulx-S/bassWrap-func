function [cmd,files,dsgn] = afni_setDsgn(dsgn,file)
    if ~exist('file', 'var'); file = []; end
    % if isempty(param) || ~isfield(param,'model') || isempty(param.model); param.model = 'TENTzero'; end
    % if isempty(param) || ~isfield(param,'PCflag') || isempty(param.PCflag); param.PCflag = 0; end
    % if ~exist('dryRun', 'var') || isempty(dryRun); dryRun = 0; end
    % if ~exist('scratchDir', 'var'); scratchDir = []; end
    % if ~isempty(scratchDir) && ~endsWith(scratchDir, [filesep 'tmp']); scratchDir = fullfile(scratchDir, 'tmp'); end
        

    % Set output files
    if isempty(file)
        file = tempname;
    elseif isfolder(file)
        dbstack; error('not sure what to do with file');
        % if isfolder(scratchDir); mkdir(scratchDir); end
        % dataFile = tempname(scratchDir);
    elseif endsWith(file, {'.1D', '.nii','.nii.gz'})
        file = strsplit(file,'.'); file = file{1};
    else
        % do nothing
    end
    files.stimTimes    = [file '_stimTimes.1D'];
    files.resp    = [file '_resp.nii.gz'     ];
    files.respStd = [file '_respStd.nii.gz'  ];

    
    % Set dsgn
    switch class(dsgn)
        case 'runDsgn'
            writematrix(dsgn.onsetList, files.stimTimes,'Delimiter','space','FileType','text');
        otherwise
            dbstack; error(['dsgn is of type ' class(dsgn) '(not implemented)']);
    end



    switch dsgn.model
        case {'TENTzero', 'TENT'}
            if isempty(dsgn.(dsgn.model).windowMethod)
                dsgn.(dsgn.model).windowMethod = 'minISIrunInterrupted';
            end
    end



    cmd = {};
    % if param.PCflag
    %     cmd{end+1} = ['-num_stimts ' num2str(dsgn.condK*2) ' \'];
    % else
        cmd{end+1} = ['-num_stimts ' num2str(dsgn.condK) ' \'];
    % end

    % if param.PCflag
    %     cmd{end+1} = ['-stim_label ' num2str(k)            ' ' [char(dsgn.task) '_' dsgn.condLabel{k} 'Real'] ' \'];
    %     cmd{end+1} = ['-stim_label ' num2str(dsgn.condK+k) ' ' [char(dsgn.task) '_' dsgn.condLabel{k} 'Imag'] ' \'];
    % else
    %     cmd{end+1} = ['-stim_label ' num2str(k) ' ' [char(dsgn.task) '_' dsgn.condLabel{k}] ' \'];
    % end



    kList = sort(unique(dsgn.cond));
    for k = 1:dsgn.condK
        % if param.PCflag
        %     dbstack; error('double-check that');
        %     cmd{end+1} = ['-stim_label ' num2str(k)            ' ' [char(dsgn.task) '_' dsgn.condLabel{k} 'Real'] ' \'];
        %     cmd{end+1} = ['-stim_label ' num2str(dsgn.condK+k) ' ' [char(dsgn.task) '_' dsgn.condLabel{k} 'Imag'] ' \'];
        % else
            cmd{end+1} = ['-stim_label ' num2str(k) ' ' [char(dsgn.task) '_' dsgn.condLabel{k}] ' \'];
        % end

    
        % Set model
        switch dsgn.model
            case 'SPMG2'
                dbstack; error('double-check that')
                dur = dsgn.ondurList(kList(k)==dsgn.cond); if ~isempty(dur) && any(diff(dur)); dbstack; error('stim duration cannot be different across trials'); end
                dur = dur(1);
                nReg = 2;
                cmd{end+1} = ['-stim_times ' num2str(k) ' ' files.stimTimes{k} ' ''' param.model '(' num2str(dur,'%0.3f') ')'' \'];
                nRegAll(k) = nReg;
            case 'SPMG3'
                dbstack; error('double-check that')
                nReg = 3;
                if max(abs(diff(durSeq)))/max(durSeq) > 0.0001; dbstack; error('stim duration cannot be different across trials'); end
                cmd{end+1} = ['-stim_times ' num2str(k) ' ' files.stimTimes ' ''' HRmodel '(' num2str(mean(durSeq),'%0.3f') ')'' \'];
            % case 'TENT'
            %     dbstack; error('code that')
            case {'TENTzero', 'TENT'}
                switch dsgn.(dsgn.model).windowMethod
                    case 'minISI'
                        % set the deconvolution window to the minimum ISI
                        % ISI is the time between any stimulus (of any condition)
                        eTime     = dsgn.onsetList(dsgn.cond==kList(k));
                        eTimeNext_idx = find(dsgn.cond==kList(k))+1;
                        if eTimeNext_idx(end) > length(dsgn.onsetList)
                            % this is the last stimulus of the run, create a dummy stimulus at the end of the run
                            eTimeNext_idx(end) = [];
                            eTimeNext = dsgn.onsetList(eTimeNext_idx);
                            eTime(end) = [];
                        else
                            eTimeNext = dsgn.onsetList(eTimeNext_idx);
                        end
                        deconWin_sec = min(eTimeNext - eTime);
                        deconSR = dsgn.(dsgn.model).sr;
                        if (deconWin_sec*deconSR)/ceil(deconWin_sec*deconSR)>0.9
                            deconWin_sec = ceil(deconWin_sec*deconSR)/deconSR;
                        else
                            deconWin_sec = floor(deconWin_sec*deconSR)/deconSR;
                        end
                        b = 0;
                        c = round((deconWin_sec-1/deconSR)*deconSR)/deconSR;
                        nReg = round( (c-b)*deconSR + 1 );        
                    case 'minISIrunInterrupted'
                        % set the deconvolution window to the smallest of
                        %  the minimum ISI or
                        %  the time between the last stimulus of the current condition and the end of the run
                        % ISI is the time between any stimulus (of any condition)
                        eTime     = dsgn.onsetList(dsgn.cond==kList(k));
                        eTimeNext_idx = find(dsgn.cond==kList(k))+1;
                        if eTimeNext_idx(end) > length(dsgn.onsetList)
                            % this is the last stimulus of the run, create a dummy stimulus at the end of the run
                            eTimeNext_idx(end) = [];
                            eTimeNext = dsgn.onsetList(eTimeNext_idx);
                            eTimeNext(end+1) = double(dsgn.n) / dsgn.sr;
                        else
                            eTimeNext = dsgn.onsetList(eTimeNext_idx);
                        end
                        deconWin_sec = min(eTimeNext - eTime);
                        deconSR = dsgn.(dsgn.model).sr;
                        if (deconWin_sec*deconSR)/ceil(deconWin_sec*deconSR)>0.9
                            deconWin_sec = ceil(deconWin_sec*deconSR)/deconSR;
                        else
                            deconWin_sec = floor(deconWin_sec*deconSR)/deconSR;
                        end
                        b = 0;
                        c = round((deconWin_sec-1/deconSR)*deconSR)/deconSR;
                        nReg = round( (c-b)*deconSR + 1 );        
                end

                % (c-b)/(nReg-1)
                % if param.PCflag
                %     dbstack; error('double-check that');
                %     cmd{end+1} = ['-stim_times ' num2str(k)            ' ' fStim{:,:,1} ' ''(dsgn.model)(' num2str(b) ',' num2str(c) ',' num2str(nReg) ')'' \'];
                %     cmd{end+1} = ['-stim_times ' num2str(dsgn.condK+k) ' ' fStim{:,:,2} ' ''(dsgn.model)(' num2str(b) ',' num2str(c) ',' num2str(nReg) ')'' \'];
                % else
                    cmd{end+1} = ['-stim_times ' num2str(k) ' ' char(files.stimTimes) ' ''' dsgn.model '(' num2str(b) ',' num2str(c) ',' num2str(nReg) ')'' \'];
                % end

                % deconvolve time vector
                % for TENTzero the first and last regressors are removed and a fitted value of zero is assumed, effectively fixing these time points to the baseline
                dsgn.(dsgn.model).tReg = linspace(b,c,nReg);
                % if ~dryRun
                    % if param.PCflag
                    %     dbstack; error('double-check that');
                    %     cmd{end+1} = ['-iresp ' num2str(k)            ' ' fResp{:,:,1}    ' \'];
                    %     cmd{end+1} = ['-sresp ' num2str(k)            ' ' fRespStd{:,:,1} ' \'];
                    %     cmd{end+1} = ['-iresp ' num2str(dsgn.condK+k) ' ' fResp{:,:,2}    ' \'];
                    %     cmd{end+1} = ['-sresp ' num2str(dsgn.condK+k) ' ' fRespStd{:,:,2} ' \'];
                    % else
                        cmd{end+1} = ['-iresp ' num2str(k) ' ' char(files.resp)    ' \'];
                        cmd{end+1} = ['-sresp ' num2str(k) ' ' char(files.respStd) ' \'];
                        cmd{end+1} = ['-TR_times ' num2str(1/deconSR) ' \'];
                    % end
                % end
            otherwise
                dbstak; error('unknown model');
        end
    end
