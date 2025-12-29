classdef runDsgn
    % Encapsulate definition of stimulus design.

   properties
      % Header info
      task      (1,:) char = 'task' % label
      onsetList (1,:) double        % [1 x nEvent] onset time of each event/trial, in seconds (trigger time = 0)
      ondurList (1,:) double        % [1 x nEvent] duration of each event/trial, in seconds
      cond      (1,:) uint8         % [1 x nEvent] index of event/trial condition (0 is special for null event/trial, other conditions should be increments of 1), always stored as a row vector
      condLabel (1,:) cell          % [1 x nConditions] event/trial condition labels (indices corresponds to values of cond)
      condK     (1,1) uint8         % [1 x 1] number of event/trial conditions, empty by default
      sr        (1,1) double;       % [1 x 1] sampling rate in Hz
      n         (1,1) uint32;       % [1 x 1] number of data points
      model     (1,:) char
      TENTzero  (1,1) struct        % [1 x 1] struct containing parameters relevant to the TENTzero model
      TENT      (1,1) struct        % [1 x 1] struct containing parameters relevant to the TENT model
      SPMG2     (1,1) struct        % [1 x 1] struct containing parameters relevant to the SPMG2 model
   end
   
   properties (Constant, Hidden)
      % Units for each property
      units = struct(...
          'task', '', ...
          'onsetList', 's', ...
          'ondurList', 's', ...
          'cond', '', ...
          'condLabel', '', ...
          'condK', '', ...
          'sr', 'Hz', ...
          'n', '', ...
          'model', '', ...
          'TENTzero', struct('sr', 'Hz', 'tReg', 's'), ...
          'TENT', struct('sr', 'Hz', 'tReg', 's'), ...
          'SPMG2', struct('params', '') ...
      );
   end
   
   methods
      function obj = runDsgn()
          % Constructor: Initialize substructures with default values
          
          % Initialize TENTzero substructure
          obj.TENTzero = struct(...
              'sr'  , [], ...                 % sampling rate (Hz)
              'tReg', zeros(0,1) ...          % time vector for regressors (seconds), always column vector
          );
          
          % Initialize TENT substructure
          obj.TENT = struct(...
            'sr'  , [], ...                 % sampling rate (Hz)
            'tReg', zeros(0,1) ...          % time vector for regressors (seconds), always column vector
        );
          
          % Initialize SPMG2 substructure
          obj.SPMG2 = struct(...
              'params', [] ...               % SPMG2 model parameters
          );
      end
      
      function obj = set.TENTzero(obj, val)
          % Property setter: Ensure tReg is always a column vector
          if isfield(val, 'tReg') && ~isempty(val.tReg)
              val.tReg = val.tReg(:);
          end
          obj.TENTzero = val;
      end
      
      function obj = set.TENT(obj, val)
          % Property setter: Ensure tReg is always a column vector
          if isfield(val, 'tReg') && ~isempty(val.tReg)
              val.tReg = val.tReg(:);
          end
          obj.TENT = val;
      end
      
      function disp(obj)
          % Custom display method that shows units with values
          fprintf('  runDsgn with properties:\n\n');
          
          propNames = properties(obj);
          for i = 1:length(propNames)
              propName = propNames{i};
              value = obj.(propName);
              unit = runDsgn.units.(propName);
              
              % Format the value display
              if isempty(value)
                  if iscell(value)
                      valueStr = '{1×0 cell}';
                  elseif ischar(value) || isstring(value)
                      valueStr = '[1×0 char]';
                  else
                      valueStr = sprintf('[1×0 %s]', class(value));
                  end
              elseif ischar(value) || isstring(value)
                  if length(value) <= 50
                      valueStr = sprintf('''%s''', value);
                  else
                      valueStr = sprintf('''%s...''', value(1:47));
                  end
              elseif iscell(value)
                  if isempty(value)
                      valueStr = '{1×0 cell}';
                  else
                      dims = size(value);
                      dimStr = sprintf('%d×', dims);
                      dimStr = dimStr(1:end-1); % remove trailing ×
                      valueStr = sprintf('{%s cell}', dimStr);
                  end
              elseif isnumeric(value) || islogical(value)
                  if isscalar(value)
                      valueStr = num2str(value);
                  else
                      dims = size(value);
                      dimStr = sprintf('%d×', dims);
                      dimStr = dimStr(1:end-1); % remove trailing ×
                      valueStr = sprintf('[%s %s]', dimStr, class(value));
                  end
              elseif isstruct(value)
                  % Display struct with field names and units
                  fnames = fieldnames(value);
                  if isempty(fnames)
                      valueStr = '[1×1 struct]';
                  else
                      % Check if this substructure has units defined
                      if isstruct(unit) && isfield(unit, fnames{1})
                          % Build string with field names and units
                          fnameUnitPairs = cell(1, length(fnames));
                          for j = 1:length(fnames)
                              fname = fnames{j};
                              if isfield(unit, fname) && ~isempty(unit.(fname))
                                  fnameUnitPairs{j} = sprintf('%s (%s)', fname, unit.(fname));
                              else
                                  fnameUnitPairs{j} = fname;
                              end
                          end
                          fnamesStr = strjoin(fnameUnitPairs, ', ');
                      else
                          fnamesStr = strjoin(fnames, ', ');
                      end
                      if length(fnamesStr) > 50
                          fnamesStr = [fnamesStr(1:47) '...'];
                      end
                      valueStr = sprintf('[1×1 struct: %s]', fnamesStr);
                  end
              else
                  valueStr = sprintf('[%s]', class(value));
              end
              
              % Add unit if it exists (but not for structs, as units are shown in field names)
              if isstruct(unit)
                  % Units are already shown in the struct field names
                  fprintf('    %12s: %s\n', propName, valueStr);
              elseif ~isempty(unit)
                  fprintf('    %12s: %s %s\n', propName, valueStr, unit);
              else
                  fprintf('    %12s: %s\n', propName, valueStr);
              end
          end
      end
   end
end
