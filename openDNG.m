function img = openDNG(filename)
% Opens and processes a .dng camera raw file for processing.
% The result is a grayscale image.  Most commands are courtesy of Rob Sumner's
% "Processing RAW Images in MATLAB", 2014.

%
% Set the phase of the Bayer pattern, i.e., the layout of color channels in
% the upper left most square of four pixels.
%
bayer_phase = 'rggb';
% filename = 'IMG01531.dng';
%
% Open file:  dng is essentially a tiff file with a bunch of useful meta
% data
%
warning off MATLAB:tifflib:TIFFReadDirectory:libraryWarning
t = Tiff(filename,'r');
offsets = getTag(t,'SubIFD');
setSubDirectory(t,offsets(1));
img = read(t); % the Bayer CFA data
close(t);
meta_info = imfinfo(filename);
% Crop to only valid pixels
x_origin = meta_info.SubIFDs{1}.ActiveArea(2)+1; % +1 due to MATLAB indexing
width = meta_info.SubIFDs{1}.DefaultCropSize(1);
y_origin = meta_info.SubIFDs{1}.ActiveArea(1)+1;
height = meta_info.SubIFDs{1}.DefaultCropSize(2);
img = double(img(y_origin:y_origin+height-1,x_origin:x_origin+width-1));

%
% Linearizing (if necessary):  map the magnitude scale back to the right
% scaling.  Canon cameras do not require linearization.  Also, set the
% magnitude scale to lie in [0,1].
%
if isfield(meta_info.SubIFDs{1},'LinearizationTable')
    ltab=meta_info.SubIFDs{1}.LinearizationTable;
    img = ltab(img+1);
end
black = meta_info.SubIFDs{1}.BlackLevel(1);
saturation = meta_info.SubIFDs{1}.WhiteLevel;
img = (img-black)/(saturation-black);
img = max(0,min(img,1));

%
% White balancing:  scale each color channel in the CFA by an appropriate
% amount to white balance the image.  It is a relative scaling so green
% pixels are given the (arbitrary) value 1.  The white balancing
% multipliers are taken from the time of shooting via meta data.  Need to
% choose the phase of the Bayer pattern.
%
wb_multipliers = (meta_info.AsShotNeutral).^-1;
wb_multipliers = wb_multipliers/wb_multipliers(2);
mask = wbmask(size(img,1),size(img,2),wb_multipliers,bayer_phase);
img = img .* mask;

%
% Demosaicing:  do interpolation on the Bayer pattern to get each color
% channel and to generate the rgb image.
%
temp = uint16(img/max(img(:))*2^16);
img = double(demosaic(temp,bayer_phase))/2^16;

%
% Color space conversion:  the basis for the RGB image that has been
% created does not coincide with the basis for the monitor and matlab.  Do
% a change of basis at each pixel on the RGB color space.
%
xyz2cam = meta_info.ColorMatrix2; % Get transformation matrix from meta data
xyz2cam = reshape(xyz2cam,[3,3])'; % Convert to a matrix with correct orientation 
rgb2xyz = [0.4124564 0.3575761 0.1804375
           0.2126729 0.7151522 0.0721750
           0.0193339 0.1191920 0.9503041];
rgb2cam = xyz2cam * rgb2xyz; % Assuming previously defined matrices
rgb2cam = rgb2cam ./ repmat(sum(rgb2cam,2),1,3); % Normalize rows to 1
cam2rgb = rgb2cam^-1;
img = apply_cmatrix(img, cam2rgb);
img = max(0,min(img,1)); % Always keep image clipped b/w 0-1

%
% Brightness (could be improved):  scale image so that
% the mean luminance is 0.6 the maximum.
%
img = rgb2gray(img);
grayscale = 0.6/mean(img(:));
img = min(1,img*grayscale);

%
% Gamma correction:  dark areas appear too dark so apply nonlinear
% transformation 
%
img = img.^(1/2.2);