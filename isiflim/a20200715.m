%% Could have done it in python, but so many scripts are already in Matlab
clear all;close all; clc;
if ~exist('flifile.m','file'),addpath('..\general-matlab-functions\fdFLIM');end
pth = 'E:\2020\07\15';
ref = '2020-07-15_14.00.17_reference_AD9520_test.fli';
sam = '2020-07-15_14.09.15_sample_AD9520_test_2';
bg12 = '2020-07-15_14.14.13_bg_12ph.fli';
ref = flifile(fullfile(pth,ref));
sam = flifile(fullfile(pth,sam));
exp_time = str2double(sam.getheaderinfo('exposureTime'));
bg2 = {'2020-07-15_14.14.13_bg100.fli','2020-07-15_14.14.13_bg200.fli','2020-07-15_14.14.13_bg300.fli'};
bg2 = flifile(fullfile(pth,bg2{2}));
bg12 = flifile(fullfile(pth,bg12));
%% load data
bg2dat = mean(getdata(bg2,0),4);
bg12dat = mean(getdata(bg12,0),4);
samdat = double(getdata(sam,0))-bg2dat;
refdat = double(getdata(ref,0))-bg12dat;

%% get system parameters
F = fdFLIM(40,12);
F = F.loadref(int16(refdat),3.83);

%% restructure isiFLIM
ph = [0,60,180,240]; % zie mail Tue 28-Jan-20 1:58 PM
for ct = 1:size(samdat,4)
    samdatIsi(:,:,:,ct) = isiFlimInterlace(samdat(:,:,:,ct));
    [p,m,d] = PhiMod(int16(samdatIsi(:,:,:,ct)),[],ph);
    phi(:,:,ct) = p;
    mod(:,:,ct) = m;
    dc(:,:,ct) = d;
end
%% calculate lifetimes
phic1 = F.phic(:,1:504);
phic2 = F.phic(:,505:end)+pi;
phic = (phic1+phic2)./2;
modc1 = F.modc(:,1:504);
modc2 = F.modc(:,505:end);
modc = (modc1+modc2)./2;
omega = 40E6*2*pi;
for ct = 1:size(samdat,4)
    mask = dc(:,:,ct)>RH_percentile(dc(:,:,ct),0.25);
    p = phic1-phi(:,:,ct);
    m = mod(:,:,ct)./modc1;
    m(m>1)=1;
    tau_p = (1/omega) .* tan(p);
    tau_m = (1/omega) .* sqrt((1./(m.^2))-1);
    tau_p(~mask)=NaN;
    tau_m(~mask)=NaN;
    imagesc(tau_p,[0,5]*1E-9)
    colormap('jet')
    colorbar
    pause(0.1)
end