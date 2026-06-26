# bassWrap-func

> ⚠️ **SUNSETTED.** This repo is no longer actively developed. AFNI wrappers are
> being consolidated into [`afniWrap`](https://github.com/Proulx-S/afniWrap).
> The next time a wrapper here is used or modified, copy it into `afniWrap` and
> work from there — do not add new work in this repo.

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













