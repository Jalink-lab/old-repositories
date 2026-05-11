%% Could have done it in python, but so many scripts are already in Matlab
clear all;close all; clc;
if ~exist('flifile.m','file'),addpath('..\general-matlab-functions\fdFLIM');end
pth = 'D:\temp\20200811';

%% data for callibration (6 flifiles)
%reference
ref12 = '2020-08-11_13.25.47_12ph_r6g.fli';
ref2 = '2020-08-11_13.29.50_2ph_r6g';
reftau = 3.88;
%background
bg12 = '2020-08-11_13.31.48_12ph_bg';
bg2 = '2020-08-11_13.30.53_2ph_bg';
%lamp
lp12 = '2020-08-11_17.01.56_12ph_lamp.fli';
lp2 = '2020-08-11_17.03.47_2ph_lamp';

ref12 = flifile(fullfile(pth,ref12));
ref2 = flifile(fullfile(pth,ref2));
bg12 = flifile(fullfile(pth,bg12));
bg2 = flifile(fullfile(pth,bg2));
lp12 = flifile(fullfile(pth,lp12));
lp2 = flifile(fullfile(pth,lp2));
%% load data for callibration (and take mean over time where appropriate)
bg2dat = mean(getdata(bg2,0),4);
bg12dat = mean(getdata(bg12,0),4);
ref2dat = mean(double(getdata(ref2,0))-bg2dat,4);
ref12dat = mean(double(getdata(ref12,0))-bg12dat,4);
lp2dat = mean(double(getdata(lp2,0))-bg2dat,4);
lp12dat = mean(double(getdata(lp12,0))-bg12dat,4);

%% correct with correction factor
tog_corr_F = get_toggel_correction_frame(lp12dat);
tog_corr_F = mean(tog_corr_F(:,:,1:11),3);
ref12datc = apply_toggel_correction_frame(ref12dat,tog_corr_F);
ref2datc = apply_toggel_correction_frame(ref2dat,tog_corr_F);

%% get system parameters
F = fdFLIM(40,12);
F = F.loadref(int16(ref12datc),reftau);
phic1 = F.phic(:,1:504);
phic2 = F.phic(:,505:end) + pi;
phic2 = map2pi(phic2);%map back to [-pi pi]

%% restructure isiFLIM
ph2 = [0,60,180,240]; % zie mail Tue 28-Jan-20 1:58 PM
ph2 = (ph2*2*pi) / 360;  % to radians
samdatIsiRef(:,:,:) = isiFlimInterlace(ref2datc(:,:,:));
[phiR,modR,dcR] = PhiMod(int16(samdatIsiRef),[],ph2);

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
title(sprintf('phi12 = %.2f ; phi2 = %.2f',out1.phi,param.phi))
legend()

%% save all system parameters
sys.phic1 = phic1;
sys.phic2 = phic2;
sys.modc1 = F.modc(:,1:504);
sys.modc2 = F.phic(:,505:end);
sys.tog_corr_F = tog_corr_F;
sys.bg2dat = bg2dat;
save(fullfile(pth,'systemparameters.mat'),'sys','-v7.3','-nocompression')