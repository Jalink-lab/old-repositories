clear all; close all; clc
set(0,'defaulttextinterpreter','latex')
fig=gcf;
fig.Position=[100 200 800 450];

pth = 'E:\2020\01\07\result';
file = 'D3_ROIData_lifetime.tsv';
fit = 'D3_fitresults.tsv';
data = dlmread(fullfile(pth,file),'\t',1,0);
fitdat = dlmread(fullfile(pth,fit),'\t',1,0);
xax = data(:,1);
data(:,1)=[];
for ct=1:51
    plot(xax,data(:,ct),'.','MarkerSize',10)
    idx = find(fitdat(:,1)==(ct-1));
    if ~isempty(idx)
        f = @(x,p) p(1) + p(2)./(1+exp(-(x-p(4))./p(3)));
        p=fitdat(idx,2:5);
        hold on; plot(xax,f(xax,p),'-'); hold off
        title(sprintf("ROI: %.0f ; Breakdown: %.2f",ct,p(3)))
    end
    pause
end
xlabel('time(s)')
ylabel('lifetime(ns)')
legend('data','fit')

%fig.Children(1).TickLabelInterpreter='latex';