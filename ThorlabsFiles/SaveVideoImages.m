%This script reads all the 2D oct files in a directory and saves the video
%snapshots taken with the CCD camera.  Files are saved as .png files. 

disp('Which File(s) do you want to process?');
filenum = input('Enter the number(s) here: ');

len = length(filenum);

for ii = 1: len

if filenum(ii) < 10
    
    filenum_str = ['000', num2str(filenum(ii))];
else
    filenum_str = ['00', num2str(filenum(ii))];
end



    filename = ['TOOTH_',filenum_str, '_Mode3D.oct'];

    %filename = filelist(ii).name;
    ind = filename(11:12);
   
    handle = OCTFileOpen(filename);
    
    angle = str2double(handle.head.Image.Angle.Text);
    center = [str2double(handle.head.Image.CenterX.Text); ...
              str2double(handle.head.Image.CenterY.Text)];
    pxsize = [str2double(handle.head.Image.PixelSpacing.SizeX.Text); ...
              str2double(handle.head.Image.PixelSpacing.SizeY.Text); ...
              str2double(handle.head.Image.PixelSpacing.SizeZ.Text)];

    %%%%% read dataset properties %%%%%%
    
    %disp( OCTFileGetProperty(handle, 'AcquisitionMode') );
    %disp( OCTFileGetProperty(handle, 'RefractiveIndex') );
    %disp( OCTFileGetProperty(handle, 'Comment') );
    %disp( OCTFileGetProperty(handle, 'Study') );
    %disp( OCTFileGetProperty(handle, 'ExperimentNumber') );
    
    VideoImage = OCTFileGetColoredData(handle,'VideoImage');
    %figure(2);clf;

    
    set(0,'Units','pixels');
    width=size(VideoImage,1); %17cm
    height=size(VideoImage,2); %10cm
    figure;
    %set(gcf,'Units','pixels','Position',[1 1 width height]); % 100 100 width height
    imagesc(VideoImage);
    axis off;
    box off;
    pbaspect([size(VideoImage,2) size(VideoImage,1) 1]);
    outfilename = ['VideoImage_',filenum_str,'.jpg'];
    imwrite(VideoImage, outfilename);
    save(['VolHeader_',filenum_str],'angle','center','pxsize')
    OCTFileClose(handle);

end

%clear filename filenum filenum_str handle ii ind len VideoImage;
