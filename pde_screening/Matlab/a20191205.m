clear all; close all; clc
pth = 'E:\2019\12\05\result';

parameter_names = {'Time to Halfpoint (s)','Startpoint (ns)','Endpoint (ns)','Breakdown Rate (s)','Fit error'};
% The fit function "y=a + b/(1+exp(-c*(x-d)))"
% c is the rate constant with units 1/s so the exponent is dimensionless
% In the datafiles we store 1/c in seconds. 
%Roi	start(ns)	range(ns)	rate(s)	midpoint(s)	RSq	RMSE	Intensity
%(8 parameters)
parameter = 4; %4=rate(s)

method = '90pc';
names = 'screenLayout.txt';
%% load all data
d = dir(fullfile(pth,'*.tsv'));
for ct = length(d):-1:1
    if isempty(regexp(d(ct).name,'fitresults','once'))
        d(ct)=[];
    end
end
alldata=cell(length(d),2);
for ct = 1:length(d)
    alldata{ct,1}=d(ct).name(1:end-15);
    alldata{ct,2}=dlmread(fullfile(d(ct).folder,d(ct).name),'\t',1,0);
end
%% load screen layout and sort data accordingly
fid = fopen(fullfile(pth,names),'rt');
l = fgetl(fid);
data = {}; ct=1;
wellnrs = [];
while ~isnumeric(l)
    l = split(l,',');
    data{ct,1} = l{1};
    for wells = 2:length(l)
        wellname = regexp(l{wells},'\S*','match');
        wellname = wellname{:};
        wellnr=find(ismember(alldata(:,1),wellname));
        if ~isempty(wellnr)
            data{ct,wells} = alldata{wellnr,2};
            wellnrs(end+1)=wellnr;
        else
            warning('could not find %s',wellname)
        end
    end
    ct=ct+1;
    l = fgetl(fid);
end
fclose(fid);
if length(unique(wellnrs))~=length(wellnrs),warning('used a well nr more than once\n');end
if length(unique(wellnrs))~=size(alldata,1),warning('did not use well %s\n',alldata{setdiff(1:size(alldata,1),wellnrs),1});end
clear alldata;
%% show a cloud
% I = [];
% for ct = 1:size(data,1)
% d = cell2mat(data(ct,2:end)');d=d(:,8);d(isnan(d))=[];
% I=[I;d];
% end
% R = [];
% for ct = 1:size(data,1)
% d = cell2mat(data(ct,2:end)');d=d(:,4);d(isnan(d))=[];
% R=[R;d];
% end
% plot(I,R,'.')
% xlabel('intensity')
% ylabel('rate')
% [im,x,y]=RH_hist2([I,R],[20,2]);
% figure(2)
% imagesc(x,y,log10(im))
% ax=gca;
% ax.YDir='normal';
% xlabel('intensity')
% ylabel('rate')
%% get intensity
I = [];
for ct = 1:size(data,1)
d = cell2mat(data(ct,2:end)');d=d(:,8);d(isnan(d))=[];
I=[I;d];
end
cutoffI = RH_percentile(I,.5);
%% make boxplot of the data
f=figure(1);clf;
xticklabels = strrep(data(:,1),'_',' ');
if~exist('RH_boxplot.m','file'),addpath('\..\..\..\generalMatlabFunctions');end 
ct=1;
d = cell2mat(data(ct,2:end)');d=d(:,parameter);
I = cell2mat(data(ct,2:end)');I=I(:,8);
d(isnan(d)|d<RH_percentile(d,0.05)|d>RH_percentile(d,0.95))=[];

ax = RH_boxplot(1,d,[],method,[0.5,1]);
N(ct)=length(d);
xticklabels{ct} = [xticklabels{ct},sprintf('_{N=%.0f}',N(ct))];
for ct = 2:size(data,1)
    d = cell2mat(data(ct,2:end)');d=d(:,parameter);
    I = cell2mat(data(ct,2:end)');I=I(:,8);
    d(isnan(d)|d<RH_percentile(d,0.05)|d>RH_percentile(d,0.95))=[];
    N(ct)=length(d);
    xticklabels{ct} = [xticklabels{ct},sprintf('_{N=%.0f}',N(ct))];
    RH_boxplot(ct,d,ax,method,[0.5,1]);
end
ax.XTickLabel = xticklabels;
ax.XTickLabelRotation = -45;
ylabel(parameter_names(parameter))
title(sprintf('PDE screen, N = %.0f cells',sum(N)))
%% save boxplot
set(0,'defaulttextinterpreter','latex')
f=gcf;
f.Position=[100 200 700 300];

f.Children(1).TickLabelInterpreter='latex';
f.Children(1).FontSize=10;
xticklabels = strrep(xticklabels,'u','$\mu$');
ax.XTickLabel = strrep(xticklabels,'_','\textsuperscript');
ax.XTickLabelRotation = -45;
saveas(f,fullfile(pth,'boxplot20191205.emf'))