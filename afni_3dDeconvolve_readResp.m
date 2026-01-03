function deconStruct = afni_3dDeconvolve_readResp(deconStruct)

    resp.mri    = MRIread(deconStruct.res.files.resp);
    deconStruct.res.resp.resp = resp;
    respStd.mri    = MRIread(deconStruct.res.files.respStd);
    deconStruct.res.resp.respStd = respStd;