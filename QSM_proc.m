function QSM_proc(main_path)
% @DESCRIPTION: Script for QSM processing
% @AUTHOR: Emma Biondetti, PhD, University of Chieti-Pescara, Italy
% @DATE: 24/01/2025

%addpath(genpath('/home/emma/Documents/MATLAB/'))
addpath(genpath('/home/jbetancur/Desktop/Matlab/'))
addpath('/home/jbetancur/Desktop/Scripts_QSM/')

%%% Loading ROMEO field map and mask
romeo_B0_nii = dir([main_path '/QSM/romeo_unw/B0.nii.gz']);
nii = load_untouch_nii([romeo_B0_nii.folder '/' romeo_B0_nii.name]);
romeo_B0 = double(nii.img);
romeo_B0(isnan(romeo_B0)) = 0;
voxel_size = nii.hdr.dime.pixdim(2:4);    

% Calculating any rotations relative to the B0 direction
rotation_matrix = R_from_hdr_method2(nii.hdr);
B0_dir = [0 0 1]';
B0_dir_prime = rotation_matrix\B0_dir;
B0_dir_prime = B0_dir_prime/norm(B0_dir_prime);

%% Loading brain maskngest TE

brain_mask_dir = dir([main_path '/Magnitude/*robustfov*mask*backwardReg*']);
nii = load_untouch_nii([brain_mask_dir.folder '/' brain_mask_dir.name]);
brain_mask = double(nii.img);

%%
%%% Background field removal + brain mask erosion    
[TissuePhase, NewMask] = ...
    V_SHARP(romeo_B0,brain_mask,'voxelsize',voxel_size,'smvsize',12);

nii.hdr.dime.bitpix = 16;
nii.hdr.dime.datatype = 16;
nii.hdr.dime.scl_inter = 0;
nii.hdr.dime.scl_slope = 1;
nii.hdr.hist.descrip = 'local field map [Hz]';
nii.img = TissuePhase;
save_untouch_nii(nii, ...
    [main_path '/QSM/local_field_map_VSHARP_Hz.nii.gz'])

nii.hdr.dime.bitpix = 16;
nii.hdr.dime.datatype = 16;
nii.hdr.dime.scl_inter = 0;
nii.hdr.dime.scl_slope = 1;
nii.hdr.hist.descrip = 'final QSM mask';
nii.img = NewMask;
save_untouch_nii(nii, ...
    [main_path '/QSM/NewMask.nii.gz'])

%%% Local field to magnetic susceptibility inversion: 
% Option 1: direct Tikhonov
B0_strength = 3; % [T]
par.Resolution = voxel_size;
par.Orientation = B0_dir_prime;
par.PSFCorr = 'Yes';
psi = TissuePhase/(42.6*B0_strength);
[QSM_ppm, alpha_Tik] = directTikhonov_lcurve(psi, ...
    NewMask, par);

%%% Save QSM
nii.hdr.dime.bitpix = 16;
nii.hdr.dime.datatype = 16;
nii.hdr.dime.scl_inter = 0;
nii.hdr.dime.scl_slope = 1;
nii.hdr.hist.descrip = ['magnetic susceptibility (alpha_Tik = ' ...
    num2str(alpha_Tik) ') [ppm]'];
nii.img = QSM_ppm;
save_untouch_nii(nii, [main_path '/QSM/QSM_VSHARP_ppm.nii.gz'])


