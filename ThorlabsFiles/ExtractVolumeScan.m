 %This script reads a volume scan and extracts the Intensity.  


disp('Which File do you want to process?');
filenum = input('Enter the number here (output will be Vol[number].mat): ');
filename = input('Enter the input file name: ','s');

ii =1;
if filenum(ii) < 10 
    filenum_str = ['0', num2str(filenum(ii))];
else
    filenum_str = num2str(filenum(ii));
end

handle = OCTFileOpen(filename);
Intensity = OCTFileGetIntensity(handle);

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
ranges = zeros(1,3);
sizes = zeros(1,3);

filepath = [];

for k = 1:L
    % Get the label element. In this file, each
    % listitem contains only one label.
    thisList = handle.head.DataFiles;
    node = thisList.DataFile{k};
    if ~isempty(node) && ~isempty(strfind(node.Text, 'Intensity'))
        ranges(1) = str2double(node.Attributes.RangeX);
        ranges(2) = str2double(node.Attributes.RangeX);
        ranges(3) = str2double(node.Attributes.RangeZ);
        
        sizes(1) = str2double(node.Attributes.SizeX);
        sizes(2) = str2double(node.Attributes.SizeY);
        sizes(3) = str2double(node.Attributes.SizeZ);
        filepath = node.Text;
    end
    
    %Read the size of the video image.
    if ~isempty(node) && ~isempty(strfind(node.Text, 'VideoImage'))
        pixel(1) = str2double(node.Attributes.RangeX);
        pixel(2) = str2double(node.Attributes.RangeY);
        pixel(3) = str2double(node.Attributes.RangeZ);
        
    end
    
    
end

save(['Vol',filenum_str,'.mat'],'-v7.3')