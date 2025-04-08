function [ R ] = R_from_hdr_method2( header )
%R_FROM_HDR Calculates the rotation matrix from the voxel to the scanner
%coordinates based on the image header
% See ~/Documents/Resources/Nifti_1.docx, Method 2. This function uses
% quaternions instead of sform, because sform can be modified when
% coregistering an image to a standard atlas, e.g. MNI
%
% @AUTHOR: Emma Biondetti, University College London, UK
% @E-MAIL: emma.biondetti.14@ucl.ac.uk
% @DATE: 04/02/2021

b = header.hist.quatern_b;
c = header.hist.quatern_c;
d = header.hist.quatern_d;
a = sqrt(1 - (b*b + c*c + d*d));
qfac = header.dime.pixdim(1);

% The orthogonal matrix corresponding to a rotation by the unit quaternion
% z = a + b*i + c*j + d*k (with |z| = 1) when post-multiplying with a column 
% vector is given by:
R = [a*a+b*b-c*c-d*d 2*b*c-2*a*d 2*b*d+2*a*c;
    2*b*c+2*a*d a*a+c*c-b*b-d*d 2*c*d-2*a*b;
    2*b*d-2*a*c 2*c*d+2*a*b a*a+d*d-c*c-b*b];
R(:, 3) = qfac * R(:, 3);

end %function

