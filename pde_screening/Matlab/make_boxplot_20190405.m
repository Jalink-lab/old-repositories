%we have a fitparameter_data variable with in the first colum the data
%filename. eg B5.csv. Next column is the data.
switch 4
    case 1
        parameter = 1;
        parameter_name = 'Time to Halfpoint (s)';
    case 2
        parameter = 2;
        parameter_name = 'Startpoint (ns)';
    case 3
        parameter = 3;
        parameter_name = 'Endpoint (ns)';
    case 4
        parameter = 4;
        parameter_name = 'Decay rate (s)';
    case 5
        parameter = 5;
        parameter_name = 'Fit error';
end
method = '90pc';
names = '..\Data\20190405\PDE_INDEX.txt';
fid = fopen(names,'rt');
l = fgetl(fid);
data = {};ct=1;
while ~isnumeric(l)
    l = split(l,',');
    data{ct,1} = l{1};
    for wells = 2:length(l)
        wellname = regexp(l{wells},'\S*','match');
        wellname = [wellname{:},'.csv'];
        wellnr = find(ismember(fitparameter_data(:,1),wellname));
        if ~isempty(wellnr)
            data{ct,wells} = fitparameter_data{wellnr,2};
        end
    end
    ct=ct+1;
    l = fgetl(fid);
end
fclose(fid)

f=figure(1);clf;
xticklabels = strrep(data(:,1),'_',' ');
if~exist('mboxplot.m','file'),addpath('HelperFunctions');end %must also search in the helperfunctions path if it cannot find mboxplot.m
ct=1;
d = cell2mat(data(ct,2:end));d=d(parameter,:);d(isnan(d))=[];
ax = mboxplot(1,d,[],method);
N(ct)=length(d);
xticklabels{ct} = [xticklabels{ct},sprintf('_{N=%.0f}',N(ct))];
for ct = 2:size(data,1)
    d = cell2mat(data(ct,2:end));d=d(parameter,:);d(isnan(d))=[];
    N(ct)=length(d);
    xticklabels{ct} = [xticklabels{ct},sprintf('_{N=%.0f}',N(ct))];
    mboxplot(ct,d,ax,method);
end
ax.XTickLabel = xticklabels;
ax.XTickLabelRotation = -45;
ylabel(parameter_name)
title(sprintf('PDE screen, N = %.0f cells',sum(N)))
%% Statistics. We will compare each set against the ONLY CELLS.
%Welch's t-test
clc
allt=[];
alpha = 0.05/size(data,1); %Bonferroni corrected. 0.05/26
tLim = sqrt(2)*erfinv(1-2*alpha);
fprintf('t-limit = %.2f\n',tLim);
for ct = 1:size(data,1)
    y = cell2mat(data(end-3,2:end));y=y(parameter,:);y(isnan(y))=[];
    x = cell2mat(data(ct,2:end));x=x(parameter,:);x(isnan(x))=[];
    x=log(x);y=log(y); %log-normal distribution
    [t,nu] = welchttest(x,y);
    if nu<120,warning('low sample size for %s',xticklabels{ct});end
    if t>tLim
        fprintf(1,'%s is significant ; t=%.1f \n',xticklabels{ct},t)
    end
    allt(ct)=t;
end