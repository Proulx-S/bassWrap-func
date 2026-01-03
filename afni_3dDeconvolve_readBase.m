function base = afni_3dDeconvolve_readBase(baseFile)

    base.mri = MRIread(baseFile);
