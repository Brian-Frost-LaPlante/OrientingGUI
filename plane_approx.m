function plane_approx

    % This function uses the output of the ThorLabs "ExtractVolumeScan"
    % program to allow the user to determine the approximate plane of the
    % BM in said volume scan. The program requires the voxel dimensions
    % found in ThorImage volume viewer, and allows the user to choose the
    % distance between the B-Scans used to approximate the plane. A smaller
    % distance (~10) corresponds to a more locally accurate but globally
    % (potentially) inaccurate approximation, while a larger distance (~50) 
    % corresponds to a more globally accurate but locally (potentially) 
    % inaccurate approximation. This program assumes that the orienting
    % B-Scan is at the longitudinal center of the volume (default in
    % Thorimage. The output of this program is used in the Volume_gui 
    % script.

    close all; clear; clc;
    
    disp('This program will provide the orientation of the BM in a given volume scan.');
    disp('This is done based on user-selected points from two B-Scans.');
    disp('The first such B-Scan is the center B-Scan in the volume scan.');
    disp('You may select the other.');
    dplane = input('Enter the spacing between the B-Scans in # of B-Scans (10-50 suggested): ');
    dx = input('Enter the longitudinal pixel size (dx, default 1.95) in microns: ');
    dy = input('Enter the radial pixel size (dy, default 1.95) in microns: ');
    dz = input('Enter the axial pixel size (dz, default 2.7) in microns: ');

    outname = input('Type the desired file name of the output: ','s');

    % Asks the user to input the filename where the Intensity lies (output
    % of ExtractVolumeScan). If the file does not exist or the variable
    % Intensity does not exist within the file, the program asks again.
    
    file_correct = 0;
    while ~file_correct
        filename = input('\nPlease enter the name of the file (without quotes) containing the intensity data: ','s');
        file_exists = isfile(filename); % isfile checks if the file exists.
        if ~file_exists
            disp("File does not exist!")
        else
            list_of_vars = who('-file',filename); 
            % who gives a cell array of variable names in a mat file
            if ismember('Intensity',list_of_vars)
                disp('Loading intensity data...')
                I = load(filename); Intensity = I.Intensity;
                % Checks to make sure the intensity is 3D, so the program
                % can function properly.
                if size(Intensity,3)~=1
                    file_correct = 1;
                    disp('Intensity data properly loaded!')
                else
                    disp('The intensity data is not 3D')
                end
            else
                disp('There is no variable called Intensity in this file')
            end
        end
    end
    
    disp('Succesfully loaded volume!')

    disp('Assuming B-Scan of index is at the center of the given volume.')
    
    % This program assumes the orienting B-Scan is at the volume's
    % longitudinal center. This is the default in ThorImage.
    
    index = floor(size(Intensity,3)/2); % Index of orienting B-Scan


    
    ct0 = 1; % ct0 is 1 while the user is still determining the plane.
    
    while ct0
        
        % The B-Scans used to find the plane are equidistant
        % (longitudinally) from the orienting B-Scan. This gives the best
        % approximation local to the orienting B-Scan. We use the floor of
        % half of dplane (the chosen distance between planes) for the first
        % B-Scan, and the ceiling of half of dplane for the second B-Scan.
        % This ensures that the program functions even if dplane is an odd
        % number.
        
        ind_B1 = index-floor(dplane/2); 
        
        % We crop the intensity because the image is very dark at the
        % edges. This means that when we view imagesc (the scaled image
        % for enhanced contrast), we would see nearly no enhancement as the
        % edges are at such a low grayscale value (near 0). We choose to
        % chop 19 pixels off of all 4 edges because it seems to work well
        % in all tested cases. We lose no information this way, as the
        % structures usually appear hundreds of pixels from each edge of
        % the B-Scan.
        Image1 = Intensity(20:end-20,20:end-20,ind_B1);
        
        % We median filter, which is the canonical best filter to reduce
        % salt and pepper noise. We choose a 5x5 window as it "seems good",
        % but this can be changed to be larger to smooth out the image
        % more, or smaller to give a less smooth image.
        MFilt = medfilt2(Image1,[5,5]);

        % The user now chooses two points in the first B-Scan defining a
        % line across the BM -- the first at the modiolus and the second on
        % the outer wall. ct1 is 1 while the user is still deciding these
        % points. The user can select points until they like what they see.
        ct1 = 1; 
        while ct1
            imagesc(MFilt)
            colormap('gray')
            disp('You will draw a line segment across the BM. First, pick a point on the left wall')
            p1 = input('Give the coordinates of a point of the BM nearest the ST [y,z]: ');
            
            % (y1,z1) is the pixel index at the modiolus in the first 
            % cropped B-Scan
            y1 = p1(1); z1 = p1(2);
            
            disp('Now pick a point on the right wall')
            p2 = input('Give the coordinates of a point of the BM nearest the ST [y,z]: ');
            
            % (y2,z2) is the pixel index at the outer wall in the first
            % cropped B-Scan.
            y2 = p2(1); z2 = p2(2);
            
            % We draw a line segment between the selected points so the
            % user can determine if they want to reselect the points.
            line([y1,y2],[z1,z2],'Color','white')
            resp = input('Are you ok with this line? (y/n): ','s');
            if (resp == 'y')||(resp=='Y')
                ct1 = 0;
            end
            close all
        end
        
        % Araw is the 3D pixel value in the cropped intensity volume at the
        % modiolus, Braw is that at the outer wall.
        Araw = [ind_B1,y1,z1]; Braw = [ind_B1,y2,z2];

        % B-Scan where the final point is selected. Once again crop and
        % filter the B-Scan.
        ind_B2 = index+ceil(dplane/2);
        Image2 = Intensity(20:end-20,20:end-20,ind_B2);
        MFilt2 = medfilt2(Image2,[5,5]);
        
        % ct2 is 1 while the user is deciding the third point, and thereby
        % the whole plane. The final point is at the outer wall on the BM
        % in this second B-Scan. All variables are more or less analogous
        % to those from above, and won't be explained again.
        ct2 = 1;
        while ct2
            imagesc(MFilt2)
            colormap('gray')
            disp('You will pick a point near the right wall')
            p3 = input('Give the coordinates of a point of the BM nearest the ST [y,z]: ');
            y3 = p3(1); z3 = p3(2);
            Craw = [ind_B2,y3,z3];
            
            % The plane is defined by these three points. We want to
            % display the projection of the plane onto this image so that
            % the user can decide if they like their choice of the third
            % point. To do so, we find the normal vector of the plane in
            % these pixel coordinates (as that is how we display the plane
            % here).
            % The normal vector is normal to all vectors in the plane, so 
            % the cross product between the vectors (Araw-Braw) and 
            % (Braw-Craw) will do. 
            n_op = cross(Araw-Braw,Braw-Craw);

            % To project the plane onto the B-Scan (a y-z plane at fixed
            % x), we find a vector normal to n_op (i.e. in the plane) which
            % is also normal to the x-axis (only in a y-z plane). Its
            % x-component (index 1) will be zero.
            w = cross(n_op, [1,0,0]); % line in the 2nd B-Scan plane

            % We draw a line in the direction of w over some parameterized
            % variable t controlling the length drawn. We need the line to
            % pass through Craw, so we must add Craw to the parametrized
            % line (as otherwise it would pass through the origin).
            t = -10:10;
            Y = Craw(2)+w(2)*t; 
            Z = Craw(3)+w(3)*t;

            line([Y(1),Y(end)],[Z(1),Z(end)],'Color','white')
            resp = input('Are you ok with this line? (y/n): ','s');
            if (resp == 'y')||(resp=='Y')
                ct2 = 0;
            end
        end
        ct0 = 0;
    end

    % A, B and C are the chosen points in the optical coordinate system,
    % where the voxels are correctly scaled by dx, dy and dz. We also
    % choose B to be the origin for simplicity's sake, as then the vectors
    % in the plane (A-B) and (C-B) are simply written as A and C.
    B = [0,0,0];
    A = (Araw-Braw).*[dx,dy,dz];
    C = (Craw-Braw).*[dx,dy,dz];
    
    % We want the normal vector n to face "into" the Organ of Corti, i.e.
    % have a z-component downward. A goes from outer wall to modioulus --
    % right-to-left. C goes from apex to base -- front-to-back. It can be
    % seen by the right-hand rule that AxC would point into the Organ of
    % Corti.
    n = cross(A,C);
    n_unit = n/sqrt(n(1)^2+n(2)^2+n(3)^2);
    
    % The anatomical coordinates are defined as follows -- l is from
    % apex-to-base longitudinally (C here), r is across the BM at a fixed
    % longitudinal cross-section, and t is Brom the BM into the Organ of
    % Corti (n here). As l,r,t form a right-handed system, r = lxt = Cxn
    % (normalized). These are the anatomical unit vectors written in the
    % optical basis.
    l = C'/norm(C); r = cross(n_unit,C)'/norm(cross(n_unit,C)); t = n_unit'; 
    
    % The change of basis matrix from anatomical to optical coordinates, U,
    % is the unitary matrix whose columns are the unit vectors of the
    % anatomical coordinates written in the optical basis. U*[1;0;0]=l,
    % U*[0;1;0]=r and U*[0;0;1]=t, so by linearity, any vector in the
    % anatomical basis can be transformed to the optical basis by
    % multiplying by U. 
    % The inverse of a unitary matrix is its transpose (U'). The inverse
    % maps optical coordinates to anatomical coordinates, so U'*l=[1;0;0],
    % etc.
    U = [l,r,t];
    
    % In the Volume_gui, we want to display the B-Scan cross-sections as
    % filtered images. It would be computationally wasteful to do this
    % every time the Volume_gui is opened. Instead, we do it at the end of
    % this program.
    disp('Creating filtered data...');
    
    % We first permute the data so that the B-Scan cross-sections can be
    % filtered and displayed. Ip(:,i,:) is the ith B-Scan. This permutation
    % is necessary by the logic of MATLAB's reshape function. Without
    % permutation, the user must transpose before reassigning. I find this
    % harder to follow, and the permutation feels more natural to me.
    Ip = permute(Intensity,[2,3,1]);
    
    % We initialize If so that it is the same size as Ip. We then filter
    % each B-Scan one at a time. To filter the image, we reshape each slice
    % of Ip into a 2D image so we can apply mfilt2.
    If = Ip;
    for i = 1:size(Ip,2)
        If(:,i,:) = medfilt2(reshape(Ip(:,i,:),size(Ip,1),size(Ip,3))',[5,5]);
    end
    
    % Finally, we save the necessary data for the Volume_gui program into
    % the output file.
    disp('Saving data ...')
    save(outname,'If','n_unit','dx','dy','dz','Araw','Braw','Craw','U');
    disp('Data saved!')
end