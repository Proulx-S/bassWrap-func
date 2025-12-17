function dsgn = setDsgn(dsgn)
    switch class(dsgn)
        case 'runDsgn'
            % onsetList
            if isempty(dsgn.onsetList)
                dbstack; error('onsetList is required');
            end

            % cond
            if isempty(dsgn.cond)
                dsgn.cond = ones(size(dsgn.onsetList));
            end
            if ~all(size(dsgn.onsetList)==size(dsgn.cond))
                dbstack; error('size of onsetList and cond must be the same');
            end

            % condLabel
            if isempty(dsgn.condLabel)
                dsgn.condLabel = strcat('cond', arrayfun(@(x) num2str(x), 1:max(dsgn.cond), 'UniformOutput', false));
            end
            if length(dsgn.condLabel) < max(dsgn.cond)
                dbstack; error('missing condLabel');
            end

            % condK
            if ~dsgn.condK
                dsgn.condK = length(unique(dsgn.cond));
            end
            if dsgn.condK~=length(unique(dsgn.cond))
                dbstack; error('condK (number of conditions) should be the number of unique values in cond');
            end

        otherwise
            dbstack; error(['dsgn is of type ' class(dsgn) '(not implemented)']);
    end

