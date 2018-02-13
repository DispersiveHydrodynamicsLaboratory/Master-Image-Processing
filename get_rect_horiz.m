function [] = get_rect_horiz(Trials,data_dir,extra_dir,verbose,save_on,smoothing,gridsp,theta_pre,full_on)


% This function generates a reasonable cropping window for the trials
%verbose: Set nonzero if plotting and information is desired
%save_on: Set to 1 to save rectangle
turn_off_warnings % Warnings related to image display and opening the 
                  % DNG files are irrelevant


% Relevant quantities
if exist([data_dir,'quantities.mat'],'file')
    load([data_dir,'quantities.mat'])
    quant_on = 1;
else
    warning('No set_quantities used');
    quant_on = 0;
end
n = length(Trials);
rect = 0;


% Process images
for ii = 1:n
    disp(['Processing Trial ', sprintf('%02d',Trials(ii)),filesep,extra_dir]);
    img_dir = [data_dir,'Trial',sprintf('%02d',Trials(ii)),extra_dir,filesep];
    % Get all dng files
    img_files = glob([img_dir,'*.dng']);
    if length(img_files) == 0
        error(['No dng files in directory ',...
               img_dir]);
           return;
    end
    if length(img_files) == 1
        disp(['WARNING! Only one image file for trial ,',int2str(Trials(ii))]);
    end
    if quant_on
        disp([' ']);
        if exist('st')
            disp(['Trial ',int2str(Trials(ii)),', Q0 = ',...
                num2str(st(Trials(ii)).Q0),' mL/min, Q1 = ',...
                num2str(st(Trials(ii)).Q1),' mL/min']);
        end
    end
    % Set the crop window from a middle picture,
    % to be used for all remaining images
    specialpic = length(img_files);
    % Open dng file
    img = openDNG(img_files{specialpic});
    % Rotate theta_pre degrees ccw
    img = imrotate(img,theta_pre,'bicubic');
    % Clip values outside of [0,1]
%     img = max(0,min(img,1));
    full_img = img;

    % Crop image: if first time, use cropping tool, otherwise prompt user
    % to use the old one or interactively
    %rect = [];
    
 if ii == 1
        figure(1);
        clf();
        % Allows user to use a previously loaded crop
        if rect
             imshow_rect(full_img,rect,1,['Trial ',int2str(Trials(ii)),...
            ' image with current crop window']);
            reply = input('Use previous crop? (Y/n) ','s');
            if isempty(reply)
                reply = 'y';
            end
            if strcmp(reply,'y') | strcmp(reply,'Y')
                img = imcrop(img,rect);
            else
                figure(1);
                clf();
                disp('To crop image, click & drag rectangle, then double click it');
                [img,rect] = imcrop(img);
            end
        else
            disp('To crop image, click & drag rectangle, then double click it');
            [img,rect] = imcrop(img);
        end
        % Ask user if wanting to use current crop
    elseif verbose
        imshow_rect(full_img,rect,1,['Trial ',int2str(Trials(ii)),...
            ' image with current crop window']);
        reply = input('Use previous crop? (Y/n) ','s');
        if isempty(reply)
            reply = 'y';
        end
        if strcmp(reply,'y') | strcmp(reply,'Y')
            img = imcrop(img,rect);
        else
            figure(1);
            clf();
            disp('To crop image, click & drag rectangle, then double click it');
            [img,rect] = imcrop(img);
        end
    else
        imshow_rect(full_img,rect,1,['Trial ',int2str(Trials(ii)),...
            ' image with current crop window']);
        img = imcrop(img,rect);
 end
    disp('Rectangle Accepted!');
 
     % Interpolate the image along vertical lines
        [mz, nz] = size(img); 
        img   = imresize(img,[mz*gridsp,nz]);

    % Extract conduit edges
        [el,er] = get_conduit_edges(flipud(img'),smoothing,'mp');
        if full_on
            [els,ers] = smooth_conduit_edges_large_dsw(el,er);
        else
            [els,ers] = smooth_conduit_edges_soliton(el,er);
        end
        ctr = 0.5*(el+er);
        ctrs = 0.5*(els+ers);
        diam = els - ers;
        p = polyfit([1:length(ctrs)]',ctrs,1);
    
    if 0 %verbose
        z = [1:length(diam)];
        
        imshow_rect(full_img,rect,1,...
            'Original image with current crop window');
        imshow_edges(img,els,ers,2,...
            ['Filtered edges, Trial ',int2str(trials(ii)),...
            ', Q0 = ',num2str(Q0(trials(ii))),' mL/min']);
        plot_diam_ctr(els,ers,3,['Trial ',int2str(trials(ii))]);
        
    end
    
    % Now rotate original image so that center line is vertical and
    % reprocess everything
    theta = -atand(p(1));
    disp(['Rotating image ',num2str(theta),' degrees and reprocessing']);
    imgrot = imrotate(img,theta,'bicubic');
    
    
    % Update cropping rectangle
    sz = size(imgrot);
    dy = abs(sind(theta))*sz(2)+5;
    dx = abs(sind(theta))*sz(1)+5;
    rect_rotated = [dx,dy,sz(2)-2*dx,sz(1)-2*dy];
    img = imcrop(imgrot,rect_rotated);
        
    % Extract conduit edges
    [el,er] = get_conduit_edges(flipud(img'),smoothing,'mp');
    if full_on
        disp('Smoothing...');
        [els,ers] = smooth_conduit_edges_large_dsw(el,er);
    else
        [els,ers] = smooth_conduit_edges_soliton(el,er);
    end
    ctr = 0.5*(el+er);
    ctrs = 0.5*(els+ers);
    diam = els - ers;
    p = polyfit([1:length(ctrs)]',ctrs,1);
    
    
    % Extracts Time Stamp from picture
    status = getexif(img_files{specialpic});
    [tokens,matches] = regexp(status,...
                              'SubSecCreateDate +: ([0-9]+):([0-9]+):([0-9]+) ([0-9]+):([0-9]+):([0-9]+).([0-9]+)','tokens','match');
    % Array in format [yyyy,mm,dd,HH,MM,SS,ss]
    t = str2double(tokens{1}(1:7));
    minutes = t(5);
    seconds = t(6)+1e-2*t(7);
    times(1) = minutes*60 + seconds;
    
        imshow_edges_horiz(img,flipud(els),flipud(ers),2,...
            ['Filtered edges, Trial ',int2str(Trials(ii)),...
                 ', image ',num2str(specialpic),' out of ',...
                 int2str(length(img_files))]);
        plot_dsw(els,ers,3,['Filtered edges, Trial ',int2str(Trials(ii)),...
                 ', image ',num2str(specialpic),' out of ',...
                 int2str(length(img_files))]);
                            % Recrop image if necessary
        reply = input('Recrop image? (y/N) ','s');
        while strcmp(reply,'y') | strcmp(reply,'Y')
            figure(1);
            clf();
            disp('To crop image, click & drag rectangle, then double click it');
            [img,rect] = imcrop(full_img);
            
            % Extract conduit edges
            [el,er] = get_conduit_edges(flipud(img'),smoothing,'mp');
                if ismember(Trials(ii),51:53)
                    [els,ers] = smooth_conduit_edges_large_dsw(el,er);
                else
                    [els,ers] = smooth_conduit_edges_soliton(el,er);
                end
            ctr = 0.5*(el+er);
            ctrs = 0.5*(els+ers);
            diam = els - ers;
            p = polyfit([1:length(ctrs)]',ctrs,1);
            figure(3);
        subplot(2,1,1);
        axis([0 rect(3) 0 rect(4)]);
            reply = input('Recrop image? (y/N) ','s');
        end
    
    if save_on
    % Save the data in each trial's folder
    rotation_angle = theta;
    crop_rect = rect;
    crop_rect_rotated = rect_rotated;
    disp('Saving cropping rectangle...');
    save([img_dir,...
          '/full_preprocessing_data.mat'],'crop_rect',...
          'rotation_angle','crop_rect_rotated','specialpic',...
          'theta','theta_pre','gridsp');
    end
    
    
end
end