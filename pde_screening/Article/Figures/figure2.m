%% Figure 2: Trace of a single cell with caged cAMP
% data from screen of 05-12-2019 
% well D7, only cells
addpath('..\..\..\generalMatlabFunctions')
clear all; close all; clc
set(0,'defaulttextinterpreter','tex')
fig=gcf;
FontName = 'Times New Roman';
fig.Position=[100 200 500 300];
LineWidth = 1.5;
MarkerSize = 9;
FontSize = 10;
pth = 'E:\2019\12\05\result';
file = 'D11_ROIData_lifetime.tsv';
fit = 'D11_fitresults.tsv';
data = dlmread(fullfile(pth,file),'\t',1,0);
fitdat = dlmread(fullfile(pth,fit),'\t',1,0);
xax = data(:,1);
data(:,1)=[];
for ct=14:14
    plot(xax,data(:,ct),'.','MarkerSize',MarkerSize)
    idx = find(fitdat(:,1)==(ct-1));
    if ~isempty(idx)
        f = @(x,p) p(1) + p(2)./(1+exp(-(x-p(4))./p(3)));
        p=fitdat(idx,2:5);
        %p(1)=3.2;
        hold on; plot(xax,f(xax,p),'-','LineWidth',LineWidth); hold off
    end
    title(num2str(ct))
end
xlabel('time(s)')
ylabel('lifetime(ns)')
title('')
legend('data','fit','Location','best')
xlim([0 120])
ylim([2.5,3.2])
for ct = 1:length(fig.Children)
    if isprop(fig.Children(ct),'FontName')
        fig.Children(ct).FontName=FontName;
    end
    if isprop(fig.Children(ct),'FontSize')
        fig.Children(ct).FontSize=FontSize;
    end
    if isprop(fig.Children(ct),'Interpreter')
        fig.Children(ct).Interpreter='tex';
    end
    if isprop(fig.Children(ct),'TickLabelInterpreter')
        fig.Children(ct).TickLabelInterpreter='tex';
    end
end
saveas(fig,'figure2.emf')