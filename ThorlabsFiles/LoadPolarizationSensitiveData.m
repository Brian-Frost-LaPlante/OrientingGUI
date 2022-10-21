%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% This file shows some example usage of the Matlab OCT scripts
% for Polarization Sensitive OCT data. To acquire such data a Polarization
% Sensitive system of the TEL200PS series is required. 
%
% Please add the path 'C:\Program Files\Thorlabs\SpectralRadar' to Matlab
% with "Set Path" -> "Add with Subfolders..." before running the scripts. 
%
% To use exectute this test file, an OCT dataset named 'testdata.oct' 
% containing processed data from either 2D or 3D Polarization Sensitive 
% mode has to put into this directory
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

handle = OCTFileOpen('testdata.oct');

%%%%% read dataset properties %%%%%%

disp( OCTFileGetProperty(handle, 'AcquisitionMode') );
disp( OCTFileGetProperty(handle, 'RefractiveIndex') );
disp( OCTFileGetProperty(handle, 'Comment') );
disp( OCTFileGetProperty(handle, 'Study') );
disp( OCTFileGetProperty(handle, 'ExperimentNumber') );

%% Processed data only
% Please note that the dataset needs to contain processed data to use 
% the function 'OCTFileGetPolarizationSensitiveData' properly

%%%%% reading retardation data %%%%%%

Retardation = OCTFileGetPolarizationSensitiveData(handle, 'Retardation');

figure(1);clf;
imagesc(Retardation(:,:,1));
title('Retardation')

%%%%% reading optic axis data %%%%%%

OpticAxis = OCTFileGetPolarizationSensitiveData(handle, 'OpticAxis');

figure(2);clf;
imagesc(OpticAxis(:,:,1));
title('Optic Axis')

%%%%% reading DOPU data %%%%%%

DOPU = OCTFileGetPolarizationSensitiveData(handle, 'DOPU');

figure(3);clf;
imagesc(DOPU(:,:,1));
title('DOPU')


%% Spectral raw data only
% Please note that the dataset needs to contain spectral raw data to use 
% the function 'OCTFileProcessPolarizationSensitiveData' properly

%%%%% reprocess retardation data from an oct-file containing spectral raw data %%%%%%

Retardation = OCTFileProcessPolarizationSensitiveData(handle, 'Retardation');

figure(4);clf;
imagesc(Retardation(:,:,1));
title('Retardation')

%%%%% close OCT file (deletes temporary files) %%%%%%

OCTFileClose(handle);
