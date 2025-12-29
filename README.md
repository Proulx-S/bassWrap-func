# bassWrap-func

MATLAB functions for AFNI design setup and stimulus design management.

## Files

- `runDsgn.m` - Class definition for stimulus design (`runDsgn` class)
- `setDsgn.m` - Function to set and validate design parameters
- `setAfniDsgn.m` - Function to set up AFNI design files

## Usage

```matlab
% Create a design object
dsgn = runDsgn();
dsgn.task = 'task';
dsgn.onsetList = [0, 10, 20, 30];
dsgn.cond = [1, 1, 2, 2];
dsgn = setDsgn(dsgn);

% Set up AFNI design
setAfniDsgn(dsgn, data, param, dryRun, scratchDir);
```

## Requirements

- MATLAB
- AFNI tools


