%% Could have done it in python, but so many scripts are already in Matlab
clear all;close all; clc;
if ~exist('flifile.m','file'),addpath('..\general-matlab-functions\fdFLIM');end
pth = 'D:\temp\20200806_cal';
ref = '2020-08-06_14.17.14_12ph_r6g';
reftau = 3.88;
bg12 = '2020-08-06_14.20.31_12ph_bg';
bg2 = '2020-08-06_14.19.38_2ph_bg';
two_ph2 = '2020-08-06_14.37.02_cells2';
two_ph1 = '2020-08-06_14.33.03_cells';
ref = flifile(fullfile(pth,ref));
bg12 = flifile(fullfile(pth,bg12));
bg2 = flifile(fullfile(pth,bg2));
two_ph1 = flifile(fullfile(pth,two_ph1));
two_ph2 = flifile(fullfile(pth,two_ph2));
dt1 = two_ph1.getdatetimes;
dt2 = two_ph2.getdatetimes;
%% load data
bg2dat = mean(getdata(bg2,0),4);
bg12dat = mean(getdata(bg12,0),4);
refdat = mean(double(getdata(ref,0))-bg12dat,4);
two_ph1dat = double(getdata(two_ph1,0))-bg2dat;
two_ph2dat = double(getdata(two_ph2,0))-bg2dat;
%% get system parameters
F = fdFLIM(40,12);
F = F.loadref(int16(refdat),3.83);

%% restructure isiFLIM
ph2 = [0,60,180,240]; % zie mail Tue 28-Jan-20 1:58 PM
ph2 = (ph2*2*pi) / 360;  % to radians
for ct = 1:size(two_ph1dat,4)
    samdatIsi(:,:,:,ct) = isiFlimInterlace(two_ph1dat(:,:,:,ct));
    [p,m,d] = PhiMod(int16(samdatIsi(:,:,:,ct)),[],ph2);
    phi(:,:,ct) = p;
    mod(:,:,ct) = m;
    dc(:,:,ct) = d;
end

%% test resulting fit
pix = [96,176];
param.phi = squeeze(angularMean(phi(pix(1),pix(2),:)));
param.mod = squeeze(mean(mod(pix(1),pix(2),:)));
param.dc = squeeze(mean(dc(pix(1),pix(2),:)));
phI = linspace(0,2*pi,1E3+1);phI(end)=[];
f = @(ph,out) out.dc*(1+out.mod*sin(ph+out.phi));
figure(1);clf
pl = plot(ph2,squeeze(mean(samdatIsi(pix(1),pix(2),:,:),4)),'k.'); hold on
pl.Annotation.LegendInformation.IconDisplayStyle='off';
plot(phI,f(phI,param),'k-','DisplayName','2ph')
ph12=linspace(0,2*pi,13);ph12(end)=[];
refpix1 = squeeze(refdat(pix(1),pix(2),:));
refpix2 = squeeze(refdat(pix(1),pix(2)+504,:));
out1 = phimod_simple(refpix1);
out2 = phimod_simple(refpix2);
pl = plot(ph12,refpix1,'r.');
pl.Annotation.LegendInformation.IconDisplayStyle='off';
plot(phI,f(phI,out1),'r-','DisplayName','12ph top')
pl = plot(ph12,refpix2,'b.');
pl.Annotation.LegendInformation.IconDisplayStyle='off';
plot(phI,f(phI,out2),'b-','DisplayName','12ph bottom')
legend()
%% calculate lifetimes
phic1 = F.phic(:,1:504);
phic2 = F.phic(:,505:end)+pi;
xphic1 = cos(phic1);
yphic1 = sin(phic1);
xphic2 = cos(phic2);
yphic2 = sin(phic2);
xphic = (xphic1+xphic2)/2;
yphic = (yphic1+yphic2)/2;
phic = atan2(yphic,xphic);
phic(phic<0) = 2*pi + phic(phic<0);
modc1 = F.modc(:,1:504);
modc2 = F.modc(:,505:end);
modc = (modc1+modc2)./2;
omega = 40E6*2*pi;
figure(1);clf;
display = 0;
tau = nan(size(phi));
for ct = 1:size(phi,3)
    mask = dc(:,:,ct)>RH_percentile(dc(:,:,ct),0.7);
    p = phi(:,:,ct)+phic1;
    m = mod(:,:,ct)./modc;
    m(m>1)=1;
    tau_p = (1/omega) .* tan(p);
    tau_m = (1/omega) .* sqrt((1./(m.^2))-1);
    tau_p(~mask)=NaN;
    tau_m(~mask)=NaN;
    if display == 0
        imagesc(tau_p,[0,5]*1E-9)
        title(sprintf('frame %.0f ; mean tau_{phi} %.2fns',ct,1E9*mean(tau_p(:),'omitnan')))
        tau(:,:,ct)=tau_p;
    else
        imagesc(tau_m,[0,5]*1E-9)
        title(sprintf('frame %.0f ; mean tau_M %.2fns',ct,1E9*mean(tau_m(:),'omitnan')))
        tau(:,:,ct)=tau_m;
    end
    colormap('jet')
    colorbar
    pause(0.25)
end

%% show progression in ROIs
in={}; ROI{ct};
[X,Y] = meshgrid(1:size(tau,2),1:size(tau,1));
for ct=1:3
    r = getROI();
    ROI{ct} = r;
    in{ct} = inpolygon(X,Y,r(:,1),r(:,2));
end
%% 
traces = [];
colors = {'r','k','m'};
vidObj = VideoWriter('osc_cells.avi','Uncompressed AVI');
vidObj.FrameRate=5;
open(vidObj);
for t = 4:size(tau,3)
    for ct = 1:3
        fr = tau(:,:,t);
        fr(~in{ct}) = nan;
        fr(fr<0) = nan;
        fr(fr>5E-9) = nan;
        traces(t,ct) = mean(fr(:),'omitnan');
    end
    % display
    fig=figure(1);clf
    subplot(4,1,[1:3])
    imagesc(tau(:,:,t),[0,4]*1E-9);axis image;hold on;
    colormap jet
    colorbar
    for ct = 1:3
        r=ROI{ct};
        plot(r(:,1),r(:,2),colors{ct},'LineWidth',2)
    end
    subplot(4,1,4);hold on
    for ct = 1:3
        plot(dt(4:t)-dt(4),traces(4:t,ct),colors{ct})
    end
    legend('cel1','cel2','cel3','Location','NorthWest')
    ylabel('\tau (ns)')
    axis tight
    ylim([2.0,3]*1E-9)
    fig.Position = [1000 602 560 736];
    if t > 5
        currFrame = getframe(gcf);
        writeVideo(vidObj,currFrame);
    end
end
close(vidObj);
%%
plot(dt1(4:end), traces(4:end,:),'.-')
legend('cel1','cel2','cel3')
ylabel('\tau (ns)')
axis tight