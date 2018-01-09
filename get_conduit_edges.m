function [el,er] = get_conduit_edges(img,s,method)
%get_conduit_edges Extracts horizontal pixel locations for conduit edges
%   el and er are vectors of horizontal pixel locations of the left and
%   right conduit edges, respectively, as functions of the vertical pixel 
%   number.  img is a grayscale image and s is the number of points
%   over which to apply the smooth function (default s=5)
%   method is a string, either 'mp' or 'deriv,' that determines the method
%   used. 'mp' is midpoint, 'deriv' uses the max/min of the first
%   derivative.

if nargin == 1
    s = 5;
end

% Get data in the right format
zdata = im2double(img);
[m,n] = size(zdata);

% Smooth image using 2-D adaptive noise-removal filtering method
zdata = wiener2(zdata,[s,s]);

if strcmp(method(1:2),'mp');
    [zl,zr] = deriv(zdata,m); %use deriv method to find center line
    ctr     = 1/2*(zl+zr);
    [el,er] = mp(zdata,ctr,m,n,method);
elseif strcmp(method,'deriv') 
    [el,er] = deriv(zdata,m);
end

if 0
	imshow_edges_horiz(zdata',el,er,2,'');
    for ii = 1:m
        figure(1); clf;
            subplot(2,1,1);
                plot(1:n,zdata(ii,:),...
                    er(ii),zdata(ii,er(ii)),'rx',...
                    el(ii),zdata(ii,el(ii)),'bx');
            subplot(2,1,2);
                if strcmp(method,'deriv') 
                    plot(1:n,fp(ii,:),...
                        er(ii),fp(ii,er(ii)),'rx',...
                        el(ii),fp(ii,el(ii)),'bx');
                else
                    plot(1:n,zedge(ii,:),...
                        er(ii),zedge(ii,er(ii)),'rx',...
                        el(ii),zedge(ii,el(ii)),'bx');
                end
                drawnow; pause(0.2);
    end
end
end

function[el,er] = mp(zdata,ctr,m,n,method)
	zsort = sort(zdata,2);
	zmax  = mean(zsort(:,round(0.8*end):end),2);
	zmin  = mean(zsort(:,1:3),2);
	zhalf = 1/2*(zmax+zmin);
	zedge = zdata - repmat(zhalf,1,n);
        el    = zeros(m,1);
        er    = zeros(m,1);
    if strcmp(method,'mpinterp')
        for ii = 1:m
            A = @(z) interp1(1:n,zedge(ii,:),z,'spline',zmax(ii));
            el(ii) = fzero(@(z) A(z), [ 1, ctr(ii)]);
            er(ii) = fzero(@(z) A(z), [ ctr(ii), n]);
        end
    else
        for ii = 1:m
            [~,l] = min(abs(zedge(ii,1:round(ctr(ii)))));
            [~,r] = min(abs(zedge(ii,round(ctr(ii)):end)));
            el(ii) = l;
            er(ii) = r;
        end
        er = er + round(ctr) - 1;
    end
end


function[el,er] = deriv(zdata,m)
    % Compute centered differences of smoothed image
    fp = zdata(:,3:end)-zdata(:,1:end-2);
    fp = [zeros(m,1),fp,zeros(m,1)];

    % Get the max and min of derivative
    [~,er] = max(fp,[],2);
    [~,el] = min(fp,[],2);
end
            



