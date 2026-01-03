function deconStruct = afni_3dDeconvolve_readBase(deconStruct)

    deconStruct.res.base.mri = MRIread(deconStruct.res.files.baselineCoef);
