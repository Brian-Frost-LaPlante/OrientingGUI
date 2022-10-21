%Function for interpolating from lambda domain (raw photodetector data) to
%k-domain.  This step seems to be the big bottleneck in the processing but
%there seems to be little we can do to speed it up. Keep interpolation
%method set to 'spline'.  Other options, e.g., 'pchip' are faster but they
%give different values to the processed A-scans and lead to a reduction in
%resolution.  

function k = lamb2k_v3(A,Chirp)

cd1=Chirp';

%spline
k = interp1(cd1, A, 1:length(Chirp),'spline');
%k = interp1(cd1, A, 1:length(Chirp),'v5cubic','extrap');

end

% function k = lamb2k_v2(A,Chirp)
% 
% cd1=Chirp';
% 
% k = spline(cd1, A, 1:length(Chirp));

