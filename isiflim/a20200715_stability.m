%% Could have done it in python, but so many scripts are already in Matlab
clear all;close all; clc;
if ~exist('flifile.m','file'),addpath('..\general-matlab-functions\fdFLIM');end
pth = 'E:\2020\07\15';
ref = '2020-07-15_14.00.17_reference_AD9520_test.fli';
sam = '2020-07-15_14.00.22_sample_AD9520_test.fli';
bg12 = '2020-07-15_14.14.13_bg_12ph.fli';
ref = flifile(fullfile(pth,ref));
sam = flifile(fullfile(pth,sam));
bg12 = flifile(fullfile(pth,bg12));
%%
bg12dat = mean(getdata(bg12,0),4);
refdat = double(getdata(ref,0))-bg12dat;
samdat = double(getdata(sam,0))-bg12dat;

%%
F = fdFLIM(40,12);
F = F.loadref(uint16(refdat),3.93);
[tp,tm] = F.getlifetime(uint16(samdat));
fprintf(1,'tp = %.2fns +- %.2fns\n',mean(1E9*tp(:)),std(1E9*tp(:)))
fprintf(1,'tm = %.2fns +- %.2fns\n',mean(1E9*tm(:)),std(1E9*tm(:)))