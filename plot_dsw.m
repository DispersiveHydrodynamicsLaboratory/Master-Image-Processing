function [] = plot_dsw(el,er,fignum,str)
%plot_dsw Plot the diameter of the conduit dsw along with 
% stats in fig fignum with title str

z = [1:length(el)];
diam = er - el;
ctr = 0.5*(er+el);

% Drop first and last few pixels from calculations
cutoff = 10;
diam(1:cutoff) = NaN;
diam(end-cutoff+1:end) = NaN;

% Stats
mu = mean(ctr);
sigma = std(ctr);
p = polyfit(z(:),ctr(:),1);
ctr(1:cutoff) = NaN;
ctr(end-cutoff+1:end) = NaN;

figure(fignum);
clf()
subplot(2,1,1);
[diammax,indmax] = max(diam);
plot(z,diam,'b-',z(indmax*[1,1]),diammax*[1,1],'r--',...
     z(indmax),diammax,'r.','markersize',10);
ylabel('diameter');
xlabel('z (vertical pixel number)');
title([str,', max at z = ',num2str(z(indmax)),...
       ', max diameter = ',num2str(diammax)]);

subplot(2,1,2);
plot(z,ctr,'b-',z,polyval(p,z),'g-.');
hold on;
errorbar([1,length(z)],mu*[1,1],2*sigma*[1,1],'r--');
hold off;
legend({'center','linear fit'});
ylabel('center');
xlabel('vertical pixel number');
title(['Angle deviation from vertical = ',num2str(-atand(p(1))),' degs']);
drawnow();

end

