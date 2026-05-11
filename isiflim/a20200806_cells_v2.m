%% Could have done it in python, but so many scripts are already in Matlab
clear all;close all; clc;
if ~exist('flifile.m','file'),addpath('..\general-matlab-functions\fdFLIM');end
pth = 'D:\temp\20200806_cal';
switch 1
    case 1
        ref12 = '2020-08-06_14.17.14_12ph_r6g';
        ref2 = '2020-08-06_14.18.42_2ph_r6g';
        reftau = 3.88;
    case 2
        ref12 = '2020-08-06_14.25.22_12ph_r6g_ki50';
        ref2 = '2020-08-06_14.27.13_2ph_r6g_ki50';
        reftau = 1.15;
end
bg12 = '2020-08-06_14.20.31_12ph_bg.fli';
bg2 = '2020-08-06_14.19.38_2ph_bg';
two_ph_cells = '2020-08-06_14.33.03_cells';
ref12 = flifile(fullfile(pth,ref12));
ref2 = flifile(fullfile(pth,ref2));
bg12 = flifile(fullfile(pth,bg12));
bg2 = flifile(fullfile(pth,bg2));
two_ph_cells = flifile(fullfile(pth,two_ph_cells));
dt1 = two_ph_cells.getdatetimes;
%% load data  (and take mean over time where appropriate)
bg2dat = mean(getdata(bg2,0),4);
bg12dat = mean(getdata(bg12,0),4);
ref2dat = mean(double(getdata(ref2,0))-bg2dat,4);
ref12dat = mean(double(getdata(ref12,0))-bg12dat,4);
two_ph_cells_dat = double(getdata(two_ph_cells,0))-bg2dat;
%% get system parameters
F = fdFLIM(40,12);
F = F.loadref(int16(ref12dat),reftau);
phic1 = F.phic(:,1:504);
phic2 = F.phic(:,505:end) + pi;
phic2(phic2>pi) = phic2(phic2>pi)-2*pi; %map back to [-pi pi]
%% show phic
subplot(1,3,1); 
imagesc(phic1,[min(phic1(:)) max(phic1(:))]); axis image
colorbar; 
title('system phase register 1')
subplot(1,3,2); 
imagesc(phic2,[min(phic1(:)) max(phic1(:))]); axis image
colorbar;
title('system phase register 2 + pi')
subplot(1,3,3);
phic_d = phic1-phic2;
imagesc(phic_d);axis image
colorbar;
ph_pr_seg = mean_per_segment(phic_d);
title(sprintf('register 1 - register 2 ; %.4f %.4f %.4f %.4f',ph_pr_seg))



%% restructure isiFLIM
ph2 = [0,60,180,240]; % zie mail Tue 28-Jan-20 1:58 PM
ph2 = (ph2*2*pi) / 360;  % to radians
% per segment phase fix
S = [1 123 253 383 505];
for ct = 1:size(two_ph_cells_dat,4)
    samdatIsi = isiFlimInterlace(two_ph_cells_dat(:,:,:,ct));
    for n_seg = 1:4
        ph2_seg = ph2;
        ph2_seg(3:4) = ph2_seg(3:4)+ph_pr_seg(n_seg);
        [p,m,d] = PhiMod(int16(samdatIsi(:,S(n_seg):S(n_seg+1)-1,:)),[],ph2);
        phiS(:,S(n_seg):S(n_seg+1)-1,ct) = p;
        modS(:,S(n_seg):S(n_seg+1)-1,ct) = m;
        dcS(:,S(n_seg):S(n_seg+1)-1,ct) = d;
    end
end
samdatIsiRef(:,:,:) = isiFlimInterlace(ref2dat(:,:,:));
for n_seg = 1:4
    ph2_seg = ph2;
    ph2_seg(3:4) = ph2_seg(3:4)+ph_pr_seg(n_seg);
    [phiR_,modR_,dcR_] = PhiMod(int16(samdatIsiRef(:,S(n_seg):S(n_seg+1)-1,:)),[],ph2);
    phiR(:,S(n_seg):S(n_seg+1)-1) = phiR_;
    modR(:,S(n_seg):S(n_seg+1)-1) = modR_;
    dcR(:,S(n_seg):S(n_seg+1)-1) = dcR_;
end
%% test resulting fit
f = @(ph,out) out.dc*(1+out.mod*sin(ph+out.phi));
pix = [96,176];
param.phi = phiR(pix(1),pix(2));
param.mod = modR(pix(1),pix(2));
param.dc = dcR(pix(1),pix(2));
phI = linspace(0,2*pi,1E3+1);phI(end)=[];
figure(1);clf
pl = plot(ph2,squeeze(samdatIsiRef(pix(1),pix(2),:)),'k.'); hold on
pl.Annotation.LegendInformation.IconDisplayStyle='off';
plot(phI,f(phI,param),'k-','DisplayName','2ph')
ph12=linspace(0,2*pi,13);ph12(end)=[];
refpix1 = squeeze(ref12dat(pix(1),pix(2),:));
refpix2 = squeeze(ref12dat(pix(1),pix(2)+504,:));
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
phic2 = F.phic(:,505:end) + pi;
phic2(phic2>pi) = phic2(phic2>pi)-2*pi; %map back to [-pi pi]
xphic1 = cos(phic1);
yphic1 = sin(phic1);
xphic2 = cos(phic2);
yphic2 = sin(phic2);
xphic = (xphic1+xphic2)/2;
yphic = (yphic1+yphic2)/2;
phic = atan2(yphic,xphic);
modc1 = F.modc(:,1:504);
modc2 = F.modc(:,505:end);
modc = (modc1+modc2)./2;
omega = 40E6*2*pi;
figure(1);clf;
display = 1;
tau = nan(size(phiS));
for ct = 1:size(phiS,3)
    mask = dcS(:,:,ct)>RH_percentile(dcS(:,:,ct),0.7);
    p = phiS(:,:,ct)+phic1;
    m = modS(:,:,ct)./modc;
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
%% create a video
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
%% show lifetime traces
plot(dt1(4:end), traces(4:end,:),'.-')
legend('cel1','cel2','cel3')
ylabel('\tau (ns)')
axis tight