function xMat = afni_readDsgnMat(fMat,dsgn)
global src

%% Extract design matrix
cmdX = {src.afni};
cmdX{end+1} = ['1dcat ' char(fMat)];
[~,cmdout] = system(strjoin(cmdX,newline));
mat = str2num(cmdout);
switch dsgn.model
    case 'TENTzero'
        nReg = length(dsgn.TENTzero.tReg)-2;
        nPoly = size(mat,2) - sum(nReg);
        tStim = dsgn.TENTzero.tReg(2:end-1)';
        tStim = cat(2,nan(1,nPoly),tStim);
    case 'TENT'
        dbstack; error('code that')
        nReg = length(dsgn.TENTzero.tReg);
        tStim = dsgn.TENTzero.tReg;
    case 'SPMG2'
        dbstack; error('code that')
end


% Calculate run timing
tRun = linspace(0,double(dsgn.n-1)/dsgn.sr,dsgn.n);
% for r = 1:length(param.nFrame)
%     iRun = [1 param.nFrame(r)-param.nDummyIgnore];
%     try
%         tRun(:,r) = (iRun + param.nDummyRemoved(r) + param.nDummyIgnore -1) .* param.tr(r);
%     catch
%         tRun(:,r) = (iRun + param.nDummyRemoved(r) + param.nDummyIgnore -1) .* param.tr;
%         warning(['only one tr found in param.tr' newline 'using the same for all runs'])
%     end
% end

% if param.PCflag
%     tRun = cat(2,tRun,tRun);
% end

% % Calculate stimulus timing
% switch param.model
%     case {'TENTzero' 'TENT'}
%         for k = 1:length(param.dsgn.condLabel)
%             iStim{k} = 1:param.dsgn.nReg(k);
%             if k == 1
%                 iStims{k} = iStim{k};
%             else
%                 iStims{k} = iStim{k} + iStims{k-1}(end);
%             end
%         end
%         switch param.model
%             case 'TENTzero'
%                 tStim = [iStim{:}].*param.trDecon;
%             case 'TENT'
%                 tStim = ([iStim{:}]-1).*param.trDecon;
%         end
%     case 'SPMG2'
%         tStim = tStim(tStim>=0);
%     otherwise
%         error('code that')
% end


% %%% Censoring
% if isfield(fMat,'fCnsr') && ~isempty(fMat.fCnsr)
%     fCnsr = fMat.fCnsr;
% else
%     fCnsr = replace(fMat.fIn,'.nii.gz',''); [fCnsr,b,~] = fileparts(fCnsr); fCnsr = fullfile(fCnsr,strcat('allCnsr_',b,'.csv'));
%     fMat.fCnsr = fCnsr;
% end
% sz = size(fCnsr,[1 2 3]);
% if sz(3)==1 && size(fMat.fIn,3)>1
%     fCnsr = repmat(fCnsr,1,1,size(fMat.fIn,3));
% elseif sz(3)~=size(fMat.fIn,3)
%     dbstack; error('fCnsr and fMat.fIn have different lengths in third dimension')
% end
% sz = size(fCnsr,[1 2 3]);
% sz(2) = 1;

% cnsr = cell(size(fCnsr));
% for ii = 1:sz(3)
%     for i = 1:sz(1)
%         cnsr{i,1,ii} = readmatrix(fCnsr{i,1,ii});
%         cnsr{i,1,ii} = ~logical(cnsr{i,1,ii}(:,2));
%     end
% end
% cnsr = cat(1,cnsr{:});

% % if any(cnsr)
% %     fMatCnsr = replace(char(fMat(1).fMat),'.xmat.1D','.xmatCnsrClmn.1D');
% %     if exist(fMatCnsr,'file')
% %         cmdX = {src.afni};
% %         cmdX{end+1} = ['1dcat ' fMatCnsr];
% %         [~,cmdout] = system(strjoin(cmdX,newline));
% %         matX = str2num(cmdout);
% %         nCnsr = size(matX,2) - size(mat,2);
% %         cnsr = any(matX(:,end-nCnsr+1:end),2);
% %     else
% %         dbstack; error('censor points detected but no censored design matrix found')
% %     end
% % else
% %     cnsr = [];
% % end

%% Output design matrix
xMat.mat   = mat;
xMat.tRun  = tRun';
xMat.tStim = tStim;
% xMat.nReg  = nReg;
% xMat.nPoly = nPoly;
% xMat.cnsr  = cnsr;



