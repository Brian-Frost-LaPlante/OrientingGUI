%This script reads all the B-scans in a directory (the .oct files saved by
%ThorImage) and saves the processed B-scans as .png files.  Processed files
%will have the same number as the 2D .oct file.  

% filelist = dir('*Mode2D.oct');
% numfiles = length(filelist);

disp('Which File(s) do you want to process?');
filenum = input('Enter the number(s) here: ');

len = length(filenum);

for ii = 1: len

if filenum(ii) < 10
    
    filenum_str = ['0', num2str(filenum(ii))];
else
    filenum_str = num2str(filenum(ii));
end



filename = ['+_00',filenum_str, '_Mode2D.oct'];

%filename = 'Default_0017_Mode2D.oct';

%ind = filename(8:9);

handle = OCTFileOpen(filename);
Intensity = OCTFileGetIntensity(handle);

img = Intensity(:,:,1);

%Read the Real Data file and get the lengths of the axes.
%I got this to work by trial and error. 
%It is really a cut and paste job.  
%I am terrible at using XML files.  If you want to change this
%just play around with the parameters until it works.  
%Don't ask me for help because I really cannot give any.
%Elliott

%I cut and pasted this from the ThorLabs scripts until it worked.
%Unzip one of the .oct files and look at the 'Header.xml' file. 
%I am not sure how ThorImage decides to write these but you can 
%look through the file and see the parameters.
%Elliott
OCTFileGetRealData( handle, 'Intensity' );

L = length(handle.head.DataFiles.DataFile);
sizes = zeros(1,3);
sizes(1) = 4;
filepath = [];

for k = 1:L
   % Get the label element. In this file, each
   % listitem contains only one label.
   thisList = handle.head.DataFiles;
   node = thisList.DataFile{k};
    if ~isempty(node) && ~isempty(strfind(node.Text, 'Intensity'))
        sizes(2) = str2double(node.Attributes.RangeZ);
        sizes(3) = str2double(node.Attributes.RangeX);
        filepath = node.Text;
    end
end

%Use a filter to get rid of salt and pepper noise in the empty parts of
%the image.  This is just to make the images prettier.  Don't overinterpret
%this step.  It isn't worth worrying about. 
%Ellitot

temp = imgaussfilt(img,2);
figure;
set(gcf, 'Color', 'w');
imagesc(temp);
%axis off;
box off;
colormap gray;
%Scale bar
hold on;
rectangle('Position', [1050, 974,3000,25], 'FaceColor','w','EdgeColor','w');
hold off;
title(['BScan_', filenum_str],'Interpreter','None');
pbaspect([sizes(3) sizes(2) 1]);
grid on;
set(gca, 'GridColor',[1,1,1]);
set(gca, 'GridLineStyle', '-');
set(gca, 'GridAlpha', .5);

print(['BScan_00',filenum_str,'.png'],'-dpng')
%print2eps('BScanRunA.eps', gcf);
OCTFileClose(handle);

end



% clear ans Apod basevec Bscantest bscanx bscany Chirp col elapsed;
% clear electronScaling filelist filename filler fin hangle hann_win;
% clear i ii img1 img2 ind inputfile m Mdc num_bkg numApos numfiles;
% clear Offset p rgbImage rgbImageCrop row row_raw run_num save_fig x z;
% 
% clear Intensity temp img run_num handle;
% clear filepath k L node sizes thisList;
% clear filenum filenum_str len;