%% after running the fit and make boxplot
clearvars  -except data
OC = cell2mat(data(23,2:end));OC=OC(4,:);OC(isnan(OC))=[];
PD = cell2mat(data(22,2:end));PD=PD(4,:);PD(isnan(PD))=[];

OC = log(OC);
PD = log(PD);
mm=[1,5];
msOC = [mean(OC),std(OC),std(OC)/sqrt(length(OC))];
msPD = [mean(PD),std(PD),std(PD)/sqrt(length(PD))];

normD = @(x,p) exp(-(x-p(1)).^2/(2*p(2)^2))/sqrt(2*pi*p(2)^2);
Edge = linspace(mm(1),mm(2),21);
xax = linspace(mm(1),mm(2),1E3);
figure(1);clf
subplot(1,2,1);histogram(OC,Edge,'Normalization','pdf'); title('Scrambled')
hold on;plot(xax,normD(xax,msOC),'LineWidth',2)
xlabel('log(decay time (s))')
subplot(1,2,2);histogram(PD,Edge,'Normalization','pdf'); title('PDE3A')
hold on;plot(xax,normD(xax,msPD),'LineWidth',2)
xlabel('log(decay time (s))')

