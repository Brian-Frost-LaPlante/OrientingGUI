%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This script reads the .raw Bscans taken before and after a run.  The two
%images are processed and shown as an overlaid RGB image.  The first image
%is the RED channel and the second image is the GREEN channel.  When
%plotted together, areas that are overlapped appear YELLOW = RED + GREEN.
%If the Organ of Corti does not drift during a run, then the final image
%will be primarily a YELLOW image of the structures of interest.  If the
%Organ of Corti does drift substantially during a run, then the final image
%will show the RED and GREEN channels offset by the drift.  
%
%Goal is to have structural images taken automatically before and after
%each run and to be able to see if the sample has drifted relatively 
%quickly.
%
%Elliott, February 26th, 2019

warning off;
clear filelist;

%Initilaize the raw dimensions
%num_scans = 10000;
%The number of background shots is determined by the sampling rate and the
%image size.  The Bscans taken before each run are aquired at 76 kHz which
%is less than the SDPM measuremements.  If you decide to change the
%sampling rate in the SDK program, you will need to figure out the number
%of background shots that the Telesto aquires.  The program should state
%this after it takes the image.  Or one can figure it out from the
%filesize:

%Total Number of Shots = filesize (in BYTES!!!!) /(2 * 2048)

%                      = filesize (in kB) / 4

%There are 2048 photodetectors in the line camera and each pixel holds 2
%Bytes of image depth.  On a Windows machine, 1 kB == 1024 Bytes.  

%this number appears to have changed when we updated to SDK 5.  I don't
%know why.  
num_bkg = 175;
%num_bkg = 177;
%Depth pixels in z
col = 2048;             
numApos = num_bkg;  

%Import OCT parameters
Offset = double(importdata('D:\Scripts\Thorlabs Matlab Files\OCT Calibration Files\Offset.dat'));
Chirp=importdata('D:\Scripts\Thorlabs Matlab Files\OCT Calibration Files\Chirp.dat');
electronScaling = 540;

%Matrix for interpolation from lambda to k-domain.  In the future, the matrix 
%could be stored and just called.  
Mdc = zeros(2048,2048);
for m = 1:2048
    
    basevec = zeros(2048,1);
    basevec(m) = 1; 
    Mdc(:,m) = lamb2k_v3(basevec, Chirp);
    
end

tic;

runs = input('Enter the run numbers in vector form: ');

for r = 1:length(runs)
    run_num = runs(r)
filelist{1} = ['Bscan_e1r',num2str(run_num),'.raw'];
filelist{2} = ['Bscan_e1r',num2str(run_num),'Final.raw'];

%disp('Do you want to save the final figure?');
%save_fig = input(' 1 = Yes, 0 = No: ');
save_fig = 1;

for ii = 1:length(filelist)

    inputfile = filelist{ii};
    disp(inputfile);
    
    %Open the raw data set.
    %Raw data stored as 16 bit unsigned integers.  Little endian bit order.  
    fin = fopen(inputfile,'r'); 
    I=fread(fin,'uint16', 'l');          
    fclose(fin);                           
    row_raw = length(I)./2048;
    row = row_raw - num_bkg;
    outputraw = reshape(I(1:end), [2048 row_raw]);
    
    clear I;
    
    outputraw = outputraw*electronScaling;
%     for i = 1:row_raw
%         outputraw(:,i) = outputraw(:,i) - Offset;
%     end
    
    %Spectrum = mean(outputraw(:,1:num_bkg), 2);
    Spectrum = mean(outputraw(:,76:76+25-1),2);
    RawData_total = outputraw(:,num_bkg+1:end);      
 
    clear outputraw;
    
    %Replicate the background A-scan into a full background the size of the raw data
    Background = repmat(Spectrum, [1 row]);   
    minbackground = min(Background);                 
    maxbackground = max(Background);                
    
    norm_background = zeros(1,col);
    for i=1:col
        norm_background(i)=(Background(i)-minbackground) / (maxbackground-minbackground);
    end
    
    clear minbackground maxbackground;
    
    %Set up the length of the apodization window
    %Fit the source spectrum (contained in the background scan) with a
    %polynomial.
    %Normalize the polynomial fit of the source spectrum
    z_axis=1:col;   
    p = polyfit(z_axis', norm_background',9);
    norm_background_smooth = polyval(p, z_axis');
    
    hann_win=hann(col);
    %hann_win=flattopwin(col);
    w = hann_win./norm_background_smooth;
    DC_subtracted=RawData_total-Background;
    
    %Used for testing different windows.  Commented out.  
    %{
    figure;
    plot(w,'r');
    hold on;
    plot(hann_win,'b');
    
    hold off;
    ylabel('Amplitude');
    xlabel('Lambda Domain'); 
    %}
    
    clear Background;
    clear norm_background norm_background_smooth;
    clear RawData_total;
    
    Apod = zeros(col,row);
    for i=1:row
        Apod(:,i) = w.*DC_subtracted(:,i);
    end
    
    clear w;
    clear DC_subtracted;
    clear offset Spectrum z_axis;
    
    
    %Transform from lambda to k-domain.
    %This is Marcel's method for interpolation using matrix multiplcation.
    data= Mdc * Apod;
    %disp('OK to generating data');
       
    Bscantest=20*log10(abs(fft(data)));
    %Try without using deChrip.  (No lambda- to k-domain interpolation.)
    %Bscantest=20*log10(abs(fft(Apod)));
    
    %[bscanx, bscany] = size(Bscantest);      
    Bscantest(1025:2048,:) = [];
    clear data; 
    
    %Bscantest = imrotate(Bscantest,20);
    
    %Use a Gaussian filter to eliminate the salt and pepper noise in the
    %lower half of the image.  This improves the image quailty, but please
    %note that we do not use a filter when we take the time-locked A-scans.
    %Makes the images prettier but doesn't really change much in the
    %regions we are typically interested in.  
    
    Bscantest = imgaussfilt(Bscantest,2);
    
    %Experiment with a bandpass filter.  Use some very old code from grad
    %school days.  Didn't really work so well since the RWM is close to the
    %top of the image and the bandpass filter will remove any structures
    %within the window (last argument of the function) of the edges of the
    %image.
    %Bscantest = bpass(Bscantest, 1, 50);
    
    %Tried a median filter.  It looked worse.  
    %Bscantest = medfilt2(Bscantest);
    
    if ii == 1
        img1 = Bscantest;
    elseif ii == 2
        img2 = Bscantest;
    end
    figure;
    imagesc(Bscantest);   
  
    colormap gray;
    box off;

    %Set aspect ratio so the image looks right.
    %Note that 2.7 microns per pixel in the axial direction is based on the
    %refractive index (n = 1.33 in water).  If the Telsto is imaging in air
    %the scale (microns per pixel) will be different.  
    %Range in the x-direction is set to 1 mm.  If you change in the C++
    %code, change the aspect ratio here.  
    pbaspect([1 2.7 1])
    title(inputfile(1:end-4), 'Interpreter','None');
    grid on;
    set(gca, 'GridColor',[1,1,1]);
    set(gca, 'GridLineStyle', '-');
    set(gca, 'GridAlpha', .5);
    %xlim([3500 6500])
    %ylim([250 400])
    %outputfilename = [inputfile(1:end-4), '.png'];
    %print(outputfilename,'-dpng')

    clear data;
end

%Normalize the data.
%If this step is omitted, the composite image is mostly filled with
%"yellow" pixels where the two images are the same.  This is primarily the
%parts of the cochlea that are water-filled.  These parts of the images are
%obviously the same in the two Bscans.  There are a couple of ways one can
%try to normalize the image.  It doesn't make a huge difference since we 
%are only trying to compare the two to look for changes.  
% 
%Subtract the min and then normalize.  
%More concise to do in one step
img1 = (img1-min(img1(:)))./(max(img1(:))-min(img1(:)));
img2 = (img2-min(img2(:)))./(max(img2(:))-min(img2(:)));

%Blue Channel is empty.
filler = zeros(size(img1));

rgbImage = cat(3,img1,img2,filler);
figure;
imagesc(rgbImage);
box off;
%axis off;
pbaspect([1 2.7 1]);
%xticks([1 5000]); <--We have an older version of Matlab on the OCT
%computer and I can't get this command to work there.  It is fine on the
%analysis computer.  

%Zoom in to the top half of the image.  
%rgbImageCrop = rgbImage(1:512,:,:);
rgbImageCrop = rgbImage(1:512,:,:);

figure
imagesc(rgbImageCrop);
pbaspect([1 2.7*.5 1]);
% grid on;
% set(gca, 'GridColor',[1,1,1]);
% set(gca, 'GridLineStyle', '-');
% set(gca, 'GridAlpha', .5);
hold on;
x = [5000 5000 ];
y = [ 0 512];
line(x,y,'Color', [1,1,1],'LineStyle', '--');

% x = [5100 5100 ];
% y = [ 0 512];
% line(x,y,'Color', [1,1,1],'LineStyle', '--');
% x = [5200 5200 ];
% y = [ 0 512];
% line(x,y,'Color', [1,1,1],'LineStyle', '--');
% x = [4900 4900 ];
% y = [ 0 512];
% line(x,y,'Color', [1,1,1],'LineStyle', '--');
% x = [4800 4800 ];
% y = [ 0 512];
% line(x,y,'Color', [1,1,1],'LineStyle', '--');

hold off;

if save_fig == 1
    print(['Run', num2str(run_num), 'Bscan_Drift.png'], '-dpng');
end

elapsed = toc;
disp(['It took ', num2str(elapsed), ' seconds.']);

%Calculate the cross correlation and find the peak.
%This is very slow.  

% img1 = img1(1:512,:);
% img2 = img2(1:512,:);
% 
% img1_2 = img1 - mean(img1);
% img2_2 = img2 - mean(img2);
% 
% C = xcorr2(img1_2,img2_2);
% [max_cc,imax] = max(abs(C(:)));
% [ypeak,xpeak] = ind2sub(size(C),imax);
% corr_offset = [(ypeak-size(img1,1)) (xpeak-size(img2,2))];
% 
% 
% x1 = corr_offset(1);
% y1 = corr_offset(2);
% 
% disp(x1);
% disp(y1);

end
clear Apod basevec col filler img1 img2 m Mdc profit rgbImage* run_num;
clear ans run_str;
clear inputfile filelist Offset num* p row row_* Chirp bscanx bscany hann_win;
clear i ii j electronScaling fin elapsed pts sampfreq w;
clear Bscantest outputfilename dims save_fig;
clear n x y out*;


