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
      % nReg      (1,1) uint8  % [1 x 1] number of regressors, empty by default
      winSec    (1,2) double        % [window length , window step] in seconds
      win       (1,2) uint16        % [window length, window step] in number of frames
      sr        (1,1) double = 1;   % [1 x 1] sampling rate in Hz
      dr        (1,1) double = 1;   % [1 x 1] sampling rate in Hz for deconvolution (default to sr)
   end
end
