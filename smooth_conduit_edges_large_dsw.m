function [els,ers] = smooth_conduit_edges_large_dsw(el,er)
%smooth_conduit_edges_soliton Throw away edge points that are too far from 
%                             the local mean
%   el and er are the left and right edges (obtained, e.g., by
%   get_conduit_edges)


% Smoothing parameters
avg_compare_smooth = 40; % Number of pixels to smooth in vertical
                         % direction when deciding on what points
                         % to throw out
max_pixel_deviation = 4; % Throw out all edge points that are greater
                          % than this value from the locally smoothed
                          % average
final_smooth = 20;  % Number of points to use in nonuniform (rloess)
                     % smoothing of filtered edges
max_pixels_from_mean = 10000;  % Maximum number of pixels away from global mean                     


n = length(el);
x = [1:n];
els = el;
ers = er;

% Remove obviously unphysical points
ind_disordered = find(els >= ers);
ind_ordered = setxor(x,ind_disordered);
% Interpolate to fill in missing points
if ind_disordered
    els(ind_disordered) = interp1(x(ind_ordered),els(ind_ordered),...
                                  x(ind_disordered),'linear',...
                                  0.5*(mean(els(ind_ordered))+mean(ers(ind_ordered))));
    ers(ind_disordered) = interp1(x(ind_ordered),ers(ind_ordered),...
                                  x(ind_disordered),'linear',...
                                  0.5*(mean(els(ind_ordered))+mean(ers(ind_ordered))));
end

% Smooth points in order to get local average distance
mu_el = smooth(els,avg_compare_smooth);
mu_er = smooth(ers,avg_compare_smooth);

% Find pixels that are close enough to smoothed profile
ind_el_close = find(abs(els-mu_el) <= max_pixel_deviation);
ind_er_close = find(abs(ers-mu_er) <= max_pixel_deviation);
ind_el_er_close = intersect(ind_el_close,ind_er_close);
ind_el_far = setxor(x,ind_el_close);
ind_er_far = setxor(x,ind_er_close);

% Replace pixels far from smoothed edges with interpolant through clean edge
% points of a smoothed version of the edges
els(ind_el_far) = interp1(x(ind_el_close),...
                          smooth(x(ind_el_close),els(ind_el_close),final_smooth,'rloess'),...
                          x(ind_el_far),'linear',...
                          0.5*(mean(els(ind_ordered))+mean(ers(ind_ordered))));
ers(ind_er_far) = interp1(x(ind_er_close),...
                          smooth(x(ind_er_close),ers(ind_er_close),final_smooth,'rloess'),...
                          x(ind_er_far),'linear',...
                          0.5*(mean(els(ind_ordered))+mean(ers(ind_ordered))));

% Replace points that are way too far away (likely edge points) with mean 
% center points
ind_el_too_far = find(abs(els - mean(els))>=max_pixels_from_mean);
ind_er_too_far = find(abs(ers - mean(ers))>=max_pixels_from_mean);
ind_el_ok = setxor(x,ind_el_too_far);
ind_er_ok = setxor(x,ind_er_too_far);
els(ind_el_too_far) = 0.5*(mean(els(ind_el_ok))+mean(ers(ind_er_ok)));
ers(ind_er_too_far) = 0.5*(mean(els(ind_el_ok))+mean(ers(ind_er_ok)));

% Now smooth the whole thing with clean points added
els = smooth(els, final_smooth);
ers = smooth(ers, final_smooth);
end

