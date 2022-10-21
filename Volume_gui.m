function Volume_gui

    % This program uses the output of plane_approx (which in turn uses the
    % output of ExtractVolumeScan) to allow the user to explore a cochlear
    % volume scan in terms of both optical and anatomical coordinates. The
    % program can be used in experiments to determine the locations of
    % possible measurement locations, or after experiments to determine the
    % relative locations of points measured.

    file_correct = 0; % Checks that the file exists and that it contains the correct variables
    while ~file_correct
        filename = input('\nPlease enter the name of the file (without quotes) containing the output of plane_approx: ','s');
        file_exists = isfile(filename);
        if ~file_exists
            disp("File does not exist!")
        else
            list_of_vars = who('-file',filename);
            if ismember('n_unit',list_of_vars) && ...
                    ismember('If',list_of_vars) && ...
                    ismember('dx',list_of_vars) && ...
                    ismember('dy',list_of_vars) && ...
                    ismember('dz',list_of_vars) && ...
                    ismember('Braw',list_of_vars) && ...
                    ismember('U',list_of_vars)
                
                I = load(filename); 
                n_unit = I.n_unit; If = I.If;
                dx = I.dx; dy = I.dy; dz = I.dz; Braw = I.Braw;
                Araw = I.Araw; Craw = I.Craw; U = I.U;
                file_correct = 1;
            else
                disp('There are not correct variables in this file')
            end
        end
    end

    
    % The program assumes the orienting B-Scan is at the longitudinal
    % center of the volume (centerind). The variables x, y and z span the
    % optical coordinate axes with origin at the center of the orienting
    % B-ScanThey are scaled by dx, dy and dz to have units of microns. For
    % y and z, we crop by 19 pixels on either side so that the scaled
    % images of the B-Scans look nicer.
    centerind = floor(size(If,2)/2);
    x = dx*((1:size(If,2))-centerind); 
    y = dy*((1:size(If,1))-centerind); z = dz*((1:size(If,3))-centerind);
    y = y(20:end-20); z = z(20:end-20);
    
    % the plane is determined by a normal vector and an offset as
    % dot(n_unit,v) = d for any vector v in the plane. As we know vector
    % B is in the plane, we find the offset by taking the dot product of B
    % and the normal.
    % Braw is determined in units of pixels in a scaled image that has been
    % cropped by 19 pixels on all for y,z edges. The vector B starting at
    % the origin [centerind,centerind,centerind] is thereby Braw+[0,19,19]
    % - [centerind,centerind,centerind], finally scaled by the voxel
    % dimensions dx, dy and dz.
    % The offset d is then the dot product of this vector with the unit
    % normal.
    d = dot(n_unit,[dx,dy,dz].*(Braw+[0,19,19] - centerind*[1,1,1]));
    
    % We have dot(n_unit,v) = n_unit(1)*x + n_unit(2)*y + n_unit(3)*z = d
    % for any vector v = [x,y,z] in the plane. Solving for z, we have:
    % z = -1/n_unit(3)*(n_unit(1)*x + n_unit(2)*y - d)
    % By letting x and y span over the range of the entire volume, we get
    % the z-value of the plane using this formula at all x-y values, using
    % meshgrid -- the cartesian product -- to generate all possible 
    % coordinate pairs)
    [X,Y] = meshgrid(x,y);
    Z = -1/n_unit(3)*(n_unit(1)*X + n_unit(2)*Y - d);
    
    
    % We create a figure, which is the window of the GUI. It begins
    % invisible while we set up the elements in the window. It listens for
    % keypresses and calls the function press_enter every time a key is
    % pressed. This function moves the user to the point in the optical
    % coordinates edit boxes.
    f = figure('Visible','off','units','normalized', ...
    'position',[.25,.1,.5,.9],'WindowKeyPressFcn',@press_enter);
    

    % First is a title text box above the B-Scan that doesn't change
    title_text = uicontrol('style','text',...
    'units','normalized', ...
    'position',[.25,.85,.5,.1],'String','OPTICAL COORDINATES', ...
    'FontSize',14);

    % Next, a set of axes in which the B-Scans are shown along with the
    % planar approximation projections. These also do not change.
    axes('units','normalized', ...
    'position',[.25,.25,.5,.7], 'NextPlot', 'add','Ydir','reverse');
    
    % Image1 is the B-Scan data that we display on our axes using imagesc.
    % This variable's second index does change as the user varies the
    % x-coordinate. It is initially the orienting B-Scan.
    Image1 = reshape(If(20:end-20,centerind,20:end-20),length(y),length(z));
    ylim([z(1) z(end)])
    xlim([y(1),y(end)])
     
    img = imagesc(y,z,Image1);
    colormap('gray')
    
    % pltplane is the plot element for the planar approximations projection onto
    % the B-Scan. Z's second index is the x-index of the B-Scan in
    % question. It is plotted in red. It starts at the orienting B-Scan and
    % moves as the user traverses x-space.
    pltplane = plot(y,Z(:,centerind),'r');
    
    % pltvert is the plot element of the A-Scan line in white. It is
    % initially at the center, but is moved as the user traverses y-space.
    pltvert = plot([0,0],[z(1),z(end)],'w');
    
    % pltpoint is the plot element of the point that has the coordinates shown
    % in all of the fields. It moves as y- and z-space are traversed. It is
    % a blue circle. It always lies on the A-Scan line, and begins at the
    % center of the B-Scan.
    pltpoint = plot(0,0,'bo');
    
    % lrt_origin is a point in the volume from which the anatomical
    % coordinates are referenced, as the name suggests. It starts at the
    % optical origin, but can be set anywhere using the set zero button.
    lrt_origin = [0,0,0];
    
    % there are three sliders on the bottom of the figure -- one to move
    % about in x, one for y and one for z. The sliders each have a textboxt
    % next to them labelling as x, y, or z. These are those text and slider
    % elements
    slicex_text = uicontrol('style','text',...
    'units','normalized', ...
    'position',[.75,.15,.02,.04],'String','x');
    
    slicex_slider = uicontrol('style','slider','units','normalized', ...
    'position',[.25,.15,.5,.05],...
    'min',x(1),'max',x(end)-1,'Value',0);

    slicey_text = uicontrol('style','text',...
    'units','normalized', ...
    'position',[.75,.1,.02,.04],'String','y');

    slicey_slider = uicontrol('style','slider','units','normalized', ...
    'position',[.25,.1,.5,.05],...
    'min',y(1),'max',y(end)-1,'Value',0);

    slicez_text = uicontrol('style','text',...
    'units','normalized', ...
    'position',[.75,0.05,.02,.04],'String','z');

    slicez_slider = uicontrol('style','slider','units','normalized', ...
    'position',[.25,0.05,.5,.05],...
    'min',z(1),'max',z(end)-1,'Value',0);

    % x, y and z coordinates can also be traversed using edit boxes, each
    % of which is labeled x, y, z.
    x_offset = uicontrol('style','Edit',...
        'string','0',...
        'Units','normalized',...
        'Position',[0.775 0.725 0.15 0.05],...
        'backgroundcolor','w',...
        'Tag','EditField');

    x_text = uicontrol('style','text',...
        'units','normalized', ...
        'position',[.775,.775,.15,.025],'String','x (um)');
    
    y_offset = uicontrol('style','Edit',...
        'string','0',...
        'Units','normalized',...
        'Position',[0.775 0.625 0.15 0.05],...
        'backgroundcolor','w',...
        'Tag','EditField');

    y_text = uicontrol('style','text',...
        'units','normalized', ...
        'position',[.775,.675,.15,.025],'String','y (um)');
                   
    z_offset = uicontrol('style','Edit',...
        'string','0',...
        'Units','normalized',...
        'Position',[0.775 0.525 0.15 0.05],...
        'backgroundcolor','w',...
        'Tag','EditField');
    
    z_text = uicontrol('style','text',...
        'units','normalized', ...
        'position',[.775,.575,.15,.025],'String','z (um)');
    
    % The offset button labeled APPLY on the right-hand side brings the
    % blue point to the coordinates in the optical edit boxes (x,y and z).
    % It does so by calling the function offset_fn.
    offset_button = uicontrol('Style','PushButton',...
        'String','APPLY',...
        'Units','normalized',...
        'Position',[0.775 0.425 0.15 0.075],...
        'backgroundcolor',...
        [.8,.8,.8],'FontSize',8, ...
        'callback',@xyz_fn);

    % The scan angle is controlled by an edit box theta, which is labeled
    % by a textbox.
    theta = uicontrol('style','Edit',...
        'string','0',...
        'Units','normalized',...
        'Position',[0.775 0.325 0.15 0.05],...
        'backgroundcolor','w',...
        'Tag','EditField');
    theta_text = uicontrol('style','text',...
        'units','normalized', ...
        'position',[.775,.375,.15,.025],'String','Scan Angle (deg)');
    
    % The coordinates to be used in the capture program "Cartesian Offset"
    % mode are displayed in a textbox. These vary as x,y,z,l,r,t vary, and
    % depend on the scan angle
    cart_text = uicontrol('style','text',...
        'units','normalized', ...
        'position',[.775,.175,.15,.075],'String',['OCT (X,Y)' newline '(0,0)'],...
        'FontSize',8);

    % Much like the optical APPLY button, the anatomical apply button is on
    % the lefthand side and moves the blue circle to the position in the
    % l,r,t edit boxes using callback function lrt_fn
    lrt_button = uicontrol('Style','PushButton',...
        'String','APPLY',...
        'Units','normalized',...
        'Position',[0.025 0.425 0.15 0.075],...
        'backgroundcolor',...
        [.8,.8,.8],'FontSize',8, ...
        'callback',@lrt_fn);
   
    % The button to set the reference point (lrt_origin) for anatomical
    % coordinates is labeled SET ZERO, and operates by calling zero_fn
    zero_button = uicontrol('Style','PushButton',...
        'String','SET ZERO',...
        'Units','normalized',...
        'Position',[0.025 0.3 0.15 0.075],...
        'backgroundcolor',...
        [.8,.8,.8],'FontSize',8, ...
        'callback',@zero_fn);              
    
    % The edit boxes and labels for l,r,t are analagous for those the x,y,z
    l_offset = uicontrol('style','Edit',...
        'string','0',...
        'Units','normalized',...
        'Position',[0.025 0.725 0.15 0.05],...
        'backgroundcolor','w',...
        'Tag','EditField');
    
    l_text = uicontrol('style','text',...
        'units','normalized', ...
        'position',[.025,.775,.15,.025],'String','l (um)');
    
    r_offset = uicontrol('style','Edit',...
        'string','0',...
        'Units','normalized',...
        'Position',[0.025 0.625 0.15 0.05],...
        'backgroundcolor','w',...
        'Tag','EditField');

    r_text = uicontrol('style','text',...
        'units','normalized', ...
        'position',[.025,.675,.15,.025],'String','r (um)');
                   
    t_offset = uicontrol('style','Edit',...
        'string','0',...
        'Units','normalized',...
        'Position',[0.025 0.525 0.15 0.05],...
        'backgroundcolor','w',...
        'Tag','EditField');
    
    t_text = uicontrol('style','text',...
        'units','normalized', ...
        'position',[.025,.575,.15,.025],'String','t (um)');
    
    % The sliders operate by having listeners observe the value of the
    % slider each time it is slid, and call a corresponding callback
    % function. Each of the sliders, x,y,z, have these.
    addlistener(slicex_slider, 'Value', 'PostSet', @slidex_fn);
    addlistener(slicey_slider, 'Value', 'PostSet', @slidey_fn);
    addlistener(slicez_slider, 'Value', 'PostSet', @slidez_fn);
    
    % We want the GUI to open in the center of the screen.
    movegui(f, 'center')
    
    % Finally, we make the GUI window f visible
    f.Visible = 'on';
    
    
    
    % Callback functions, written using module functions (below) mostly.
    
    function slidex_fn(source, eventdata)
        % Sets the x value based on the x slider whenever it is moved,
        % then updates l, r, t, the plot and X, Y based on the new (x,y,z)
        x_offset.String = get(eventdata.AffectedObject, 'Value');
        [xx,yy,zz] = getxyz();
        setlrt(xx,yy,zz);
        setcart(xx,yy);
        updateplot(xx,yy,zz);
    end

    function slidey_fn(source, eventdata)
        % Sets the y value based on the y slider whenever it is moved,
        % then updates l, r, t, the plot and X, Y based on the new (x,y,z)
        y_offset.String = get(eventdata.AffectedObject, 'Value');
        [xx,yy,zz] = getxyz();
        setlrt(xx,yy,zz);
        setcart(xx,yy);
        updateplot(xx,yy,zz);
    end

    function slidez_fn(source, eventdata)
        % Sets the z value based on the z slider whenever it is moved,
        % then updates l, r, t, the plot and X, Y based on the new (x,y,z)
        z_offset.String = get(eventdata.AffectedObject, 'Value');
        [xx,yy,zz] = getxyz();
        setlrt(xx,yy,zz);
        updateplot(xx,yy,zz);   
        setcart(xx,yy);
    end

    function xyz_fn(source,eventdata)
        % called when the righthand APPLY button is pressed or when ENTER
        % is pressed twice. Gets x,y,z frome dit boxes and updates l,r,t
        % the plot and X,Y based on these x,y,z.
        [xx,yy,zz] = getxyz();
        setlrt(xx,yy,zz);
        setcart(xx,yy);
        updateplot(xx,yy,zz);
    end

    function lrt_fn(source,eventdata)
        % Called when the left-hand APPLY button is pressed, reads l,r,t
        % from the edit boxes to update x,y,z, the plot and X,Y based on
        % the new l,r,t.
        [xx,yy,zz] = lrt2xyz();
        setxyz(xx,yy,zz);
        updateplot(xx,yy,zz);       
        setcart(xx,yy);        
    end

    function zero_fn(source,eventdata)
        % Called when SET ZERO is pressed. First, sets the edit boxes for
        % l,r,t to 0,0,0. Then sets the reference lrt_origin to be the
        % current values of x,y,z.
        l_offset.String = 0;r_offset.String = 0;t_offset.String = 0;
        [xx,yy,zz] = getxyz();
        lrt_origin = [xx,yy,zz];
    end

    function press_enter(varargin)
       currChar = varargin{2}.Key;
       if isequal(currChar,'return') 
           xyz_fn(offset_button,[]);
       end
    end



    % Module functions, which allow us to write the callback functions
    % succinctly
    
    function [xx,yy,zz] = getxyz()
        % Simply reads x,y,z from the right-hand edit boxes into doubles
        xx = str2double(get(x_offset, 'String'));
        yy = str2double(get(y_offset, 'String'));
        zz = str2double(get(z_offset, 'String'));
    end

    function [xx,yy,zz] = lrt2xyz()
        % First, reads l,r,t from the left-hand edit boxes. Then, uses the
        % change of basis matrix U to map the l,r,t coordinates to optical
        % coordinates (adding in the reference lrt_origin). Outputs the
        % corresponding optical coordinates, x,y,z.
        ll = str2double(get(l_offset, 'String'));
        rr = str2double(get(r_offset, 'String'));
        tt = str2double(get(t_offset, 'String'));
        lrt_vector = [ll,rr,tt];
        o_vector = (U*lrt_vector')+lrt_origin';
        xx = o_vector(1); yy = o_vector(2); zz = o_vector(3);
    end

    function setcart(xx,yy)
        % Sets the cartesian coordinates (capture coordinates for the C++
        % program) based on x and y. These can be found using basic
        % trigonometry. The value of xx is negated here because the Volume
        % axes run in counterintuitive directions compared to the capture
        % axes.
        ang = str2double(get(theta,'String'));
        cart_x = (yy*cosd(ang))+(-xx*cosd(90+ang));
        cart_y = (yy*sind(ang))+(-xx*sind(90+ang));
        cart_text.String = ['OCT (X,Y)', newline, '(',num2str(cart_x,3),',',num2str(cart_y,3),')'];
    end

    function setxyz(xx,yy,zz)
        x_offset.String = num2str(xx);
        y_offset.String = num2str(yy);
        z_offset.String = num2str(zz);
    end

    function setlrt(xx,yy,zz)
        % First subtracts out the reference (lrt_origin) from the optical
        % coordinate vector. Then, uses the change of basis matrix from
        % optical to anatomical, U', to get the l,r,t. Lastly sets the edit
        % boxes for l,r,t to these values.
        optical_vector = [xx,yy,zz]-lrt_origin;
        lrt_vector = U'*optical_vector';
        l_offset.String = lrt_vector(1);
        r_offset.String = lrt_vector(2);
        t_offset.String = lrt_vector(3);
    end

    function updateplot(xx,yy,zz)
        % Updates the plot with the correct x-plane B-Scan, the correct
        % projected plane, the correct A-Scan and correct Z-point.
        slice_ind = round((xx/dx)+centerind); 
        % xx in um, xx/dx is #px from center, add center to get x-index of 
        % B-Scan
        Islice = reshape(If(20:end-20,slice_ind,20:end-20),length(y),length(z));
        img.CData = Islice;
        pltvert.XData = [yy,yy];
        pltpoint.YData = zz;
        pltpoint.XData = yy;
        pltplane.YData = Z(:,slice_ind);
        % CData is the displayed image of an the img object from imagesc.
        % It is the reshaped and cropped B-Scan.
        % XData and YData are the x- and y-values of data in plot objects.
        % The A-Scan line pltvert has x-value in plot coords) determined by
        % y (in optical coords). The point has the same x-value as the line
        % and y-value (in plot coords) determined by z (in optical coords).
        % The plane's y (in plot coords) is Z at the x-index of the B-Scan.
    end
    
end

