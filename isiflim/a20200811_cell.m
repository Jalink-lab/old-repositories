%% Could have done it in python, but so many scripts are already in Matlab
clear all;close all; clc;
if ~exist('flifile.m','file'),addpath('..\general-matlab-functions\fdFLIM');end
pth = 'D:\temp\20200811';

%% load system parameters
load(fullfile(pth,'systemparameters.mat'))
%% load data for movies
files = {'2020-08-11_16.47.11_cells_his_io_io_ca'};
file = flifile(fullfile(pth,files{1}));
dat = (double(getdata(file,0))-sys.bg2dat)/2; % had wrong gain (4 instead of 2)
dat = apply_toggel_correction_frame(dat,sys.tog_corr_F);
dt = file.getdatetimes;
%% restructure isiFLIM and get phi mod dc
ph2 = [0,60,180,240]; % zie mail Tue 28-Jan-20 1:58 PM
ph2 = (ph2*2*pi) / 360;  % to radians
for ct = 1:size(dat,4)
    datI = isiFlimInterlace(dat(:,:,:,ct));
    [p,m,d] = PhiMod(int16(datI),[],ph2);
    phiS(:,:,ct) = p;
    modS(:,:,ct) = m;
    dcS(:,:,ct) = d;
end

%% calculate lifetimes
omega = 40E6*2*pi;
tau_p = nan(size(phiS));
tau_m = nan(size(phiS));
for ct = 1:size(phiS,3)
    p = phiS(:,:,ct)+sys.phic1;
    m = modS(:,:,ct)./sys.modc1;
    m(m>1)=1;
    m(m<0)=0;
    tau_p(:,:,ct) = (1/omega) .* tan(p);
    tau_m(:,:,ct) = (1/omega) .* sqrt((1./(m.^2))-1);
end

%% display
figure(1);clf;
display = 1;
for ct = 1:size(phiS,3)
    mask = dcS(:,:,ct)>RH_percentile(dcS(:,:,ct),0.7);
    tau_p(~mask)=NaN;
    tau_m(~mask)=NaN;
    if display == 0
        imagesc(tau_p(:,:,ct),[0,5]*1E-9)
        title(sprintf('frame %.0f ; mean tau_{phi} %.2fns',ct,1E9*mean(tau_p(:),'omitnan')))
    else
        imagesc(tau_m(:,:,ct),[0,5]*1E-9)
        title(sprintf('frame %.0f ; mean tau_M %.2fns',ct,1E9*mean(tau_m(:),'omitnan')))
    end
    colormap('jet')
    colorbar
    axis image
    pause(0.25)
end
%% show progression in ROIs
in={}; ROI={};
[X,Y] = meshgrid(1:size(tau,2),1:size(tau,1));
for ct=1:3
    r = getROI();
    ROI{ct} = r;
    in{ct} = inpolygon(X,Y,r(:,1),r(:,2));
end
%% create a video
traces = [];
colors = {'g','k','m'};
vidObj = VideoWriter([file.name,'.avi'],'Uncompressed AVI');
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
    scale = [0,4];
    res = tau2rgb(tau(:,:,t),dcS(:,:,t),scale,0.25,colormap(jet(2^16)));
    image(res);axis image;hold on;
    colormap jet
    cb = colorbar;
    cbL = length(cb.TickLabels);
    cbTl = linspace(scale(1),scale(2),cbL);
    cb.TickLabels = string(num2cell(cbTl));
    for ct = 1:3
        r=ROI{ct};
        plot(r(:,1),r(:,2),colors{ct},'LineWidth',2)
    end
    subplot(4,1,4);hold on
    for ct = 1:3
        plot(dt(4:t)-dt(4),traces(4:t,ct),colors{ct})
    end
    %legend('cel1','cel2','cel3','Location','NorthWest')
    if display == 0
        ylabel('\tau_{\phi} (ns)')
    else
        ylabel('\tau_M (ns)')
    end
    axis tight
    ylim([2.3,4.1]*1E-9)
    fig.Position = [1000 602 560 736];
    if (dt(t) - dt(1))>seconds(20)
        xlim([dt(t)-dt(4)-seconds(20),dt(t)-dt(4)])
    end
    if t > 5
        currFrame = getframe(gcf);
        writeVideo(vidObj,currFrame);
    end
end
close(vidObj);
%% show lifetime traces
figure(99);clf;hold on
for ct = 1:3
    plot(dt(4:end), traces(4:end,ct),[colors{ct} '.-'])
end
legend('cel1','cel2','cel3')
ylabel('\tau (ns)')
axis tight