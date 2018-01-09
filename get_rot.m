function [theta] = get_rot(Trials,data_dir,extra_dir,verbose,save_on,smoothing,gridsp,theta_pre,full_on)


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

% Process images
for ii = 1:n
    img_dir = [data_dir,'Trial',sprintf('%02d',Trials(ii)),extra_dir,'/'];
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
        else
            disp(['Trial ',int2str(Trials(ii))]);
        end
    end
    % Set the crop window from a middle picture,
    % to be used for all remaining images
    specialpic = length(img_files);
    % Open dng file
    img = openDNG(img_files{specialpic});
    theta = theta_pre;
	figure(1); imshow(img);
        disp(['Original rotation angle: ',num2str(theta_pre)]);
        disp(['Last rotation angle: ',num2str(theta)]);
        img2 = imrotate(img,theta_pre,'bicubic');
        figure(2); imshow(img2);
	reply = input('Rotation good? Y/n: ','s');
        if isempty(reply)
            reply = 'Y';
        end
    while strcmpi(reply,'n')
        % Rotate theta_pre degrees ccw
%         figure(1); imshow(img);
        disp(['Original rotation angle: ',num2str(theta_pre)]);
        disp(['Last rotation angle: ',num2str(theta)]);
            theta = input('Please enter a new rotation angle (degrees): ');
        img2 = imrotate(img,theta,'bicubic');
        figure(2); imshow(img2);
            reply = input('Rotation good? Y/n: ','s');
        if isempty(reply)
            reply = 'Y';
        end
    
    end
    disp(['The final rotation angle for Trial ',sprintf('%02d',Trials(ii)),...
          ' is ',num2str(theta)]);
end
end