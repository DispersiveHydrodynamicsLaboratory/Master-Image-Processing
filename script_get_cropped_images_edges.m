% This script loads a set of images, extracts their time and then
% generates a quicktime movie
clear; close all; clc; % need to delete any potential movie objects
process_files = 1; % Saves Timestamps
find_rect     = 0; % Finds and saves cropping rectangle
find_rot      = 0; % Finds and DISPLAYS first rotation angle (needs find_rect)
save_cropped  = 0; % Saves cropped images
load_cropped  = 0; % Uses cropped images instead of reprocessing originals
check_scale   = 0; % Check formatting of the video image
movie_on      = 0; % Actually save as movie (becoming less important)

% Find directory dynamically
dirparts = strsplit(pwd, '/');
data_dir = [];
for pi = 1:length(dirparts)-1
    data_dir = [data_dir, dirparts{pi}, filesep];
end
disp(['Processing from directory: ',data_dir]);

% Find number of trials dynamically
trialnums = 0;
if ~trialnums
    subfolders = glob([data_dir,'*/']); % gets all subfolders
    trialmax = 0;
    for ii = 1:length(subfolders)
        query = regexp(subfolders{ii},[data_dir,'Trial*']);
        if query
            trialmax = trialmax + 1;
        end
    end
    if trialmax
        disp([num2str(trialmax) ,' trials found, processing...']);
        trialnums = 1:trialmax;
    else
        disp(['No trials found, exiting...']);
    end
else
    disp('Processing chosen trials...');
%     trialnums = 1:4;
end

for trialnum = trialnums
    extra_dir = '/full_cam/';
    source_dir = [data_dir,'Trial',num2str(trialnum,'%02d'),extra_dir];
    quants = load([data_dir,'quantities.mat']);
    disp(['Processing ',source_dir,'...']);
    % Parameters
    hfac = 5; % Factor to increase the size in the horizontal direction
    pix = [1024]; % Number of pixels in horizontal direction
    tfac = 12;  % Speedup in time
    rotation = -147;  % Rotation angle to apply to all images (-33)
    num_files = Inf; % set to number of pictures desired; if Inf, will use all pictures
    fontsize = 10; % Fontsize for length and time scales
    show_time = 1; % Set nonzero if you want display of current time
    length_scale = 1; % Set nonzero if you want length scale to display

%     if save_cropped | load_cropped
        crop_dir = [source_dir,'/cropped/'];
%     end
    if movie_on
        output_dir = [data_dir,'/movie_files/Trial',num2str(trialnum),'/'];
        if ~exist(output_dir,'dir');
            mkdir(output_dir);
        end
    end

    if ~exist(crop_dir,'dir');
        mkdir(crop_dir);
    end

        % Finds and saves cropping rectangle
        if find_rect && trialnum == trialnums(1)
            if find_rot
                rotation = get_rot(trialnum,data_dir,extra_dir,1,1,5,hfac,rotation,1);
            end
            get_rect_horiz(trialnums,data_dir,extra_dir,1,1,5,hfac,rotation,1);
            load([source_dir,'full_preprocessing_data.mat'],'crop_rect','rotation_angle');
            myrect = crop_rect;
            myrect_on = 1;
            if ~length(trialnums)==1
                continue;
            end
        else
            load([source_dir,'full_preprocessing_data.mat'],'crop_rect','rotation_angle');
            myrect = crop_rect;
            myrect_on = 1;
        end

    if length_scale
        vlengthscale = quants.fullPixToCm; % Vertical (axial) length scale in cm/pixel, ; % Vertical (axial) length scale in cm/pixel, 
                                % if zero, then no scale is displayed
        vlength = 1; % Vertical length to display, in cm
    else
        vlengthscale = 0;
        vlength      = 0;
    end

    if process_files

        % Get all dng files in source directory
        img_files = glob([source_dir,'*.dng']);
        num_files = min(length(img_files),num_files);

        % Get starting time (include subsecond data)
        pic = fullfile(img_files(1));
        pic = pic{1};
        status = getexif(pic);
        [tokens,matches] = regexp(status,...
                                  'SubSecCreateDate +: ([0-9]+):([0-9]+):([0-9]+) ([0-9]+):([0-9]+):([0-9]+).([0-9]+)','tokens','match');
        % Array in format [yyyy,mm,dd,HH,MM,SS,ss]
        t = str2double(tokens{1}(1:7));
        t0 = t(4)*60*60+t(5)*60+t(6)+1e-2*t(7);

        % Preallocate time array
        T = zeros(1,num_files);

        disp(['Extracting timestamp from ',num2str(num_files),...
              ' images']);
        % Loop through files
        for ii=1:num_files
            pic = fullfile(img_files(ii));
            pic = pic{1};
            disp(['Processing file ',pic]);

            % Get time (include subsecond data)
            status = getexif(pic);
            [tokens,matches] = regexp(status,...
                                      'SubSecCreateDate +: ([0-9]+):([0-9]+):([0-9]+) ([0-9]+):([0-9]+):([0-9]+).([0-9]+)','tokens','match');
            % Array in format [yyyy,mm,dd,HH,MM,SS,ss]
            t = str2double(tokens{1}(1:7));
            % Convert to seconds 
            T(ii) = t(4)*60*60+t(5)*60+t(6)+1e-2*t(7);
        end
            % Sort images by timestamps
            [T,Tinds] = sort(T);
            img_files = img_files(Tinds);

        save([source_dir,'img_timestamps.mat'],'img_files','T');
    end

    if ~process_files
        load([source_dir,'img_timestamps.mat'],'img_files','T');
    end

%     % Sort images by timestamps
%     [T,Tinds] = sort(T);
%     img_files = img_files(Tinds);

    % Make first time zero
    T = T - T(1);


    image_inds = 1:min(num_files,length(img_files));


    if ~load_cropped
        % Get image size for preallocation purposes
        pic = fullfile(img_files(1));
        pic = pic{1};
        img = openDNG_mov(pic);
        img = imrotate(img,rotation);
        sz = size(img);
        img = imresize(img,[sz(1)*hfac,sz(2)]);

        if myrect_on == 1
            myrect = [myrect(1),myrect(2)*hfac,myrect(3),myrect(4)*hfac];
            [img] = imcrop(img,myrect);
        else
            clear rect; close all;
            disp('Crop');
            [img,rect] = imcrop(img);
        %     rect = [rect(1),rect(2)/hfac,rect(3),rect(4)/hfac];
        end
            % Extract conduit edges
                [el,er] = get_conduit_edges(img',8,'mp');
                [els,ers] = smooth_conduit_edges_large_dsw(el,er);
                ctr = 0.5*(el+er);
                ctrs = 0.5*(els+ers);
                diam = els - ers;
                p = polyfit([1:length(ctrs)]',ctrs,1);
            % Now rotate original image so that center line is horizontal and
            % reprocess everything
                theta = atand(p(1));
                disp(['Rotating image ',num2str(theta),' degrees and reprocessing']);
                imgrot = imrotate(img,theta,'bicubic');

            % Update cropping rectangle
            sz = size(imgrot);
            dy = abs(sind(theta))*sz(2)+5;
            dx = abs(sind(theta))*sz(1)+5;
            rect_rotated = [dx,dy,sz(2)-2*dx,sz(1)-2*dy];
            img = imcrop(imgrot,rect_rotated);
            close all; figure(1);
            imshow(img)
            if check_scale
                input('Image rotation good?');
            else
                drawnow;
            end
    end

    % Loop through different pixel resolutions
    for jj=1:length(pix)
        

        if movie_on
            disp(['Generating quicktime movie for horizontal pixel resolution ',...
              int2str(pix(jj))]);
            % Create movie object
            movObj = QTWriter([output_dir,'dt_',num2str(tfac),'x_dz_',num2str(hfac),...
                              'x_',int2str(pix(jj)),'.mov'],...
                              'MovieFormat','Photo TIFF');%,'Quality',85);
        else
            disp('Generating cropped images ');
        end
        
        % Add frames to movie object
        for ii= 1:image_inds(end)
            disp(['ii = ',int2str(ii),'/',int2str(length(T))]);
            if ~load_cropped
                pic = fullfile(img_files(ii));
                pic = pic{1};
                % Load, convert to grayscale, rotate, and resize
                img = imrotate(openDNG_mov(pic),rotation);
                sz = size(img);
                img = imresize(img,[sz(1)*hfac,sz(2)]);%[hfac*pix(jj)*sz(1)/sz(2),pix(jj)]);
                if myrect_on == 1
                    img = imcrop(img,myrect);
                else
                    img = imcrop(img,rect);
                end

                imgrot = imrotate(img,theta,'bicubic');
                img = imcrop(imgrot,rect_rotated);

                % If chosen, save image and edges
                if save_cropped
                    % Extract conduit edges
                    [el,er] = get_conduit_edges(img',8,'mp');
                    [els,ers] = smooth_conduit_edges_large_dsw(el,er);
                    ctr = 0.5*(el+er);
                    ctrs = 0.5*(els+ers);
                    diam = els - ers;
                    p = polyfit([1:length(ctrs)]',ctrs,1);
                    croppix = pix(jj);

                    save([crop_dir,sprintf('%05d.mat',ii)],'img','diam','croppix');
                end
            else
                load([crop_dir,sprintf('%05d.mat',ii)],'img');
            end
            % Resize to chosen resolution
            sz = size(img);
            img = imresize(img,[pix(jj)*sz(1)/sz(2),pix(jj)]);

            if ii==image_inds(1)
                imshow(img); drawnow;
    %             input('Return');
            end
            if movie_on
            % Add length scale to image in lower left corner if nonzero
            if vlengthscale | show_time
                newsz = size(img);
                if vlengthscale
                    % Draw vertical scale first
                    xplace_fac = 0.02;
                    yplace_fac = 0.01;
                    dx = vlength*pix(jj)/(vlengthscale*sz(2));
                    x1 = xplace_fac*newsz(2)+dx;
                    dy = vlength*pix(jj)*hfac/(10*vlengthscale*sz(2)); % in mm
                    y1 = (1-yplace_fac)*newsz(1)-2*dy;
                    x2 = x1;
                    y2 = y1+dy;
                    pos = [x1,y1,x2,y2];
                    x2 = x1;
                    y2 = mean([y1,y2]);
                    x1 = x2-dx;
                    y1 = y2;
                    pos = [pos;x1,y1,x2,y2];
                    img = insertShape(img,'Line',pos,'linewidth',2,...
                        'color','black');
                    x0 = pos(2,3)-0.002*newsz(2)+2*dx;
                    y0 = pos(2,2)-0.02*newsz(1);
                    str = [num2str(vlength),' cm'];
                    img = rgb2gray(insertText(img,[x0,y0],str,'fontsize',fontsize,...
                        'textcolor','black','boxopacity',0,...
                        'anchorpoint','rightbottom'));
                    x0 = pos(1,1)+0.02*newsz(1);
                    y0 = pos(2,2);
                    str = [num2str(vlength),' mm'];
                    img = rgb2gray(insertText(img,[x0,y0],str,'fontsize',fontsize,...
                        'textcolor','black','boxopacity',0,...
                        'anchorpoint','leftcenter'));
                end
                if show_time
                   x0 = 0.01*newsz(2); %.005*newsz(2);
                   y0 = 0; %.005*newsz(2);
                   str = ['t = ',sprintf('%d',round(T(ii))),' s'];
                   img = rgb2gray(insertText(img,[x0,y0],str,'fontsize',fontsize,...
                        'textcolor','black','boxopacity',0,...
                        'anchorpoint','lefttop'));
                end
                if ii == 1 & jj == 1
                     imshow(img);
                     if check_scale
                        reply = input('Scale layout OK? (Y/n): ','s');
                     else
                         reply = 'Y';
                         drawnow;
                     end
                     if strcmp(reply,'n');
                         disp(['Exiting movie script']);
                         close(movObj);
                         return;
                     end
                end
            end
            try
                if ii<min(num_files,length(img_files))
                    movObj.FrameRate = tfac/(T(ii+1)-T(ii));
                else
                    movObj.FrameRate = tfac/(T(ii)-T(ii-1));
                end;
            catch 
                continue;
            end
            writeMovie(movObj,img);
            end
            if 0
                imshow(img)
                width  = 3.5;
                height = 1.5; 
                set(gcf,'papersize',[width,height],...
                'paperunits','inches',...
                'paperposition',[0,0,width,height]);
    %         if length_scale==1
    %             print('-dpdf',[output_dir,'lengthscale_time',num2str(round(T(ii)-T(init))),'.pdf'])
    %         else
    %             print('-dpdf',[output_dir,'time',num2str(round(T(ii)-T(init))),'.pdf'])
    %         end
            end
        end
        if myrect_on==0
            myrect = rect;
        end
        
        if movie_on
            % Default for movies to loop
            movObj.Loop = 'loop';

            disp(['Mean framerate = ',num2str(movObj.MeanFrameRate),' fps']);

            % Finish writing
            close(movObj);

            disp(['Movie can be found at ',output_dir,'dt_',num2str(tfac),'x_dz_',num2str(hfac),...
                              'x_',int2str(pix(jj)),'.mov']);
        end
    end
end