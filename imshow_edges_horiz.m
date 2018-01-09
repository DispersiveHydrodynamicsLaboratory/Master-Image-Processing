function [f1, f2, ax] = imshow_edges_horiz(img,el,er,fignum,str)
%imshow_edges Display an image img and the left and right edges el, er in
% figure fignum with title str

z = [1:length(el)];
ctr = 0.5*(el+er); % Center line
diam = er-el; % Diameter

f1 = figure(fignum);
%     subplot(3,1,fignum)
        clf();
        set(gcf,'Color','white');
        imshow(img);
        hold on;
        plot(z,el,'r-',z,er,'r-',z,ctr,'g-');
        title(str);
        hold off;
        
f2 = figure(fignum+1);
    clf; 
    set(gcf,'Color','white');
    ax(1) = subplot(2,1,1);
        plot(z,diam,'b-');
        title(str);
	ax(2) = subplot(2,1,2);
        plot(z,ctr,'r-');
        drawnow();
end

