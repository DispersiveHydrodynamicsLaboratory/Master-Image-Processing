function [] = imshow_rect(img,rect,fignum,str)
%imshow_rect Display an image img and the rectangle rect in figure fignum
%with title str

figure(fignum);
clf();
imshow(img);
drawnow();
hold on;
plot(rect([1,1]),rect([2,2])+[0,rect(4)],'g-',...
     rect([1,1])+rect([3,3]),rect([2,2])+[0,rect(4)],'g-',...
     rect([1,1])+[0,rect(3)],rect([2,2]),'g-',...
     rect([1,1])+[0,rect(3)],rect([2,2])+rect([4,4]),'g-');
drawnow();
hold off;
title(str);
drawnow();
end

