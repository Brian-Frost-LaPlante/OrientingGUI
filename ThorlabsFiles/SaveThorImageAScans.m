disp('Do you want to save the output as .eps figures?');
save_figs = input('1 = yes, 0 = no: ');
filelist = dir('*Mode1D.oct');
disp('Do you want to rotate the plot (intensity horizontal)?')
rotatePlot = input('1 = yes, 0 = no: ');
%numfiles = length(filelist);

disp('Which File(s) do you want to process?');
filenum = input('Enter the number(s) here: ');

len = length(filenum);

for ii = 1: len
    
    if filenum(ii) < 10
        
        filenum_str = ['0', num2str(filenum(ii))];
    else
        filenum_str = num2str(filenum(ii));
    end


    filename = ['Default_00',filenum_str, '_Mode1D.oct'];
   % filename = filelist(ii).name;
    ind = filename(8:9);
    
    handle = OCTFileOpen(filename);
    Intensity = OCTFileGetIntensity(handle);
    
    avg_AScan = mean(abs(Intensity),2);
    
    %Either ThorImage saves the data for an A-scan in a dB scale or one of
    %the Matlab scripts converts it to dB.  In either case, the saved data
    %have already been converted to a log scale.  So use a linear plot
    %here.  
    %For scans taken with SDK during an experiment, data are saved as
    %linear values, so we need to plot on a log-y scale.
    
    if rotatePlot == 0
        figure;
        plot(1:1024, avg_AScan);
        xlabel('Pixel');
        ylabel('Intensity (dB)');
        title(filename,'Interpreter', 'None');
        box off;
    else
        figure;
        n = 1:1024;
        plot(avg_AScan, n, 'LineWidth', 1.25);
        set(gca,'ydir', 'reverse');
        box off;
        set(gca, 'FontSize', 12);
        xlabel('Intensity(dB)', 'FontSize',16,'FontName', 'Arial');
        ylabel('Position (Pixel)', 'FontSize',16,'FontName', 'Arial');
        title(['AScan_', filenum_str],'Interpreter','None');
        axis([ min(avg_AScan) max(avg_AScan) 0 1024]);
        pbaspect([1 2 1])

    end
        
    
    if save_figs == 1
        outputfilename = (['AScan_', filenum_str, '.eps']);
        print(outputfilename, '-dpng');
        print2eps(outputfilename, gcf);
    else
        if ii == 1
            disp('You chose not to save the figures.');
        end
    end

    OCTFileClose(handle);
    %close all;
    
end

clear avg_Ascan filelist filenum filenum_Str handle ii ind intensity;
clear len n outputfilename rotatePlot save_figs;