function deconStruct = mri2mat(deconStruct)


    switch class(deconStruct)
        case 'var_afniDecon'
            fieldList = {'resp', 'stats','base'};
            for i = 1:length(fieldList)
                fieldList2 = fields(deconStruct.res.(fieldList{i}));
                for j = 1:length(fieldList2)
                    if strcmp(fieldList2{j}, 'mri')
                        continue % hack--extractino of baseline does not conform and will be changed later
                    end
                    if isfield(deconStruct.res.(fieldList{i}).(fieldList2{j}), 'mri')
                        deconStruct.res.(fieldList{i}).(fieldList2{j}) = mri2mat(deconStruct.res.(fieldList{i}).(fieldList2{j}));
                    end
                end
            end
        
            if isfield(deconStruct.res.base,'mri') % hack--extractino of baseline does not conform and will be changed later
                deconStruct.res.base.p0 = deconStruct.res.base;
                deconStruct.res.base = rmfield(deconStruct.res.base, 'mri');
                deconStruct.res.base.p0 = mri2mat(deconStruct.res.base.p0);
            end
            return

        case 'struct'
            fieldList = fields(deconStruct);
            if ~any(contains(fieldList,'mri'))
                for i = 1:length(fieldList)
                    for j = 1:numel(deconStruct)
                        deconStruct(j).(fieldList{i}) = mri2mat(deconStruct(j).(fieldList{i}));
                    end
                end
                return
            else
                % move on
            end
      
        
            % fieldList = fields(deconStruct);
            % for i = 1:length(fieldList)
            %     if isa(deconStruct(1).(fieldList{i}), 'var_afniDecon')
            %         for j = 1:numel(deconStruct)
            %             deconStruct(j).(fieldList{i}) = mri2mat(deconStruct(j).(fieldList{i}));
            %         end
            %     end
            % end
            % return
        otherwise
            return
    end





    % Extract data from MRI structure
    try
    sz = deconStruct.mri.volsize;
    catch
        keyboard
    end
    deconStruct = deconStruct.mri.vol;

    % Remove dummy variable/voxel
    % (when single variable/voxel is analyzed, a dummy variable/voxel is appended to allow creation of a nifti file and force 3dDeconvolve to behave)
    % this is detected here by assuming spatial data will always have spatial dimensions 2 and 3 larger than 1
    if all(sz([2 3]) == 1)
        deconStruct = permute(deconStruct(1:end-1,:,:,:),[4 1 2 3]);
    end