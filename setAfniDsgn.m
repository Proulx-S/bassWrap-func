function [cmd,out] = setAfniDsgn(dsgn,file)
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
        dbstack; error('not sure what to do with file');
    end
    out.stimFile    = [file '_stimTimes.1D'];
    out.respFile    = [file '_resp.1D'     ];
    out.respStdFile = [file '_respStd.1D'  ];

    
    % Set dsgn
    switch class(dsgn)
        case 'runDsgn'
            writematrix(dsgn.onsetList, out.stimFile,'Delimiter','space','FileType','text');
        otherwise
            dbstack; error(['dsgn is of type ' class(dsgn) '(not implemented)']);
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
                out.nReg = 2;
                cmd{end+1} = ['-stim_times ' num2str(k) ' ' out.stimFile{k} ' ''' param.model '(' num2str(dur,'%0.3f') ')'' \'];
                out.nRegAll(k) = out.nReg;
            case 'SPMG3'
                dbstack; error('double-check that')
                out.nReg = 3;
                if max(abs(diff(durSeq)))/max(durSeq) > 0.0001; dbstack; error('stim duration cannot be different across trials'); end
                cmd{end+1} = ['-stim_times ' num2str(k) ' ' out.stimFile ' ''' HRmodel '(' num2str(mean(durSeq),'%0.3f') ')'' \'];
            case 'TENT'
                dbstack; error('code that')
            case 'TENTzero'
                % set the deconvolution window to the maximum (all the way up to the next stimulus or the end of the run)
                eTime     = dsgn.onsetList(dsgn.cond==kList(k));
                eTimeNext_idx = find(dsgn.cond==kList(k))+1;
                if eTimeNext_idx(end) > length(dsgn.onsetList)
                    eTimeNext_idx(end) = [];
                    eTimeNext = dsgn.onsetList(eTimeNext_idx);
                    eTimeNext(end+1) = dsgn.n / dsgn.sr;
                else
                    eTimeNext = dsgn.onsetList(eTimeNext_idx);
                end
                deconWin_sec = min(eTimeNext - eTime);
                if (deconWin_sec*dsgn.dr)/ceil(deconWin_sec*dsgn.dr)>0.9
                    deconWin_sec = ceil(deconWin_sec*dsgn.dr)/dsgn.dr;
                else
                    deconWin_sec = floor(deconWin_sec*dsgn.dr)/dsgn.dr;
                end
                b = 0;
                c = round((deconWin_sec-1/dsgn.dr)*dsgn.dr)/dsgn.dr;
                out.nReg = round( (c-b)*dsgn.dr + 1 );
                % (c-b)/(nReg-1)
                % if param.PCflag
                %     dbstack; error('double-check that');
                %     cmd{end+1} = ['-stim_times ' num2str(k)            ' ' fStim{:,:,1} ' ''TENTzero(' num2str(b) ',' num2str(c) ',' num2str(nReg) ')'' \'];
                %     cmd{end+1} = ['-stim_times ' num2str(dsgn.condK+k) ' ' fStim{:,:,2} ' ''TENTzero(' num2str(b) ',' num2str(c) ',' num2str(nReg) ')'' \'];
                % else
                    cmd{end+1} = ['-stim_times ' num2str(k) ' ' char(out.stimFile) ' ''TENTzero(' num2str(b) ',' num2str(c) ',' num2str(out.nReg) ')'' \'];
                % end
                out.nReg = out.nReg - 2;
                % if ~dryRun
                    % if param.PCflag
                    %     dbstack; error('double-check that');
                    %     cmd{end+1} = ['-iresp ' num2str(k)            ' ' fResp{:,:,1}    ' \'];
                    %     cmd{end+1} = ['-sresp ' num2str(k)            ' ' fRespStd{:,:,1} ' \'];
                    %     cmd{end+1} = ['-iresp ' num2str(dsgn.condK+k) ' ' fResp{:,:,2}    ' \'];
                    %     cmd{end+1} = ['-sresp ' num2str(dsgn.condK+k) ' ' fRespStd{:,:,2} ' \'];
                    % else
                        cmd{end+1} = ['-iresp ' num2str(k) ' ' char(out.respFile)    ' \'];
                        cmd{end+1} = ['-sresp ' num2str(k) ' ' char(out.respStdFile) ' \'];
                    % end
                % end
            otherwise
                dbstak; error('unknown model');
        end
    end
