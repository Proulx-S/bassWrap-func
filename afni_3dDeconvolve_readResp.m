function resp = afni_3dDeconvolve_readResp(respFile,respStdFile)

resp.resp.mri    = MRIread(respFile);
resp.respStd.mri = MRIread(respStdFile);

