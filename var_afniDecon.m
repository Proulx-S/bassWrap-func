classdef var_afniDecon
    % Encapsulate AFNI 3dDeconvolve results structure.

   properties
      files struct        % afni's 3dDeconvolve input and output files and paths
      dsgn  runDsgn       % afni's 3dDeconvolve design specification
      cmd   cell          % afni's 3dDeconvolve command
      res   struct        % afni's 3dDeconvolve results
   end
   
   methods
      function obj = var_afniDecon()
          % Constructor: Initialize dsgn to a runDsgn object
          obj.dsgn = runDsgn();
      end
   end
end