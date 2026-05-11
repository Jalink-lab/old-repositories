%% figure to show sensor saturation
clear all; close all; fclose all; clc;
set(0,'defaulttextinterpreter','latex')
xax = linspace(0,500,100)';
I = [1,2,5];
mu = [100 130 175];
sig = [20 30 45];

f = @(x,p) p(3)*exp(-((x-p(1)).^2/(2*p(2)^2)));
for ct = 1:3
    t(:,ct)=f(xax,[mu(ct),sig(ct),I(ct)]);
end

xax=repmat(xax,[1,3]);
t=t+1.8;
t2=t;
sat=t2>3.2;
t2(sat)=3.2;
noise = randn(size(t2));
t=t+0.01*noise;
t2=t2+0.01*noise;
colors = {'r','g','b'};

names ={'Saturation1','Saturation2'};
for ct2 = 1:2
f=figure(1);clf;hold on
for ct = 1:3
    if ct2==1
    plot(xax(:,ct),t(:,ct),[colors{ct},'-']);    
    else
    plot(xax(:,ct),t2(:,ct),[colors{ct},'-']);
    end
end
ylim([1 7])
f.Position=[1000 918 797 420];
f.Children(1).FontSize=14;
f.Children(1).TickLabelInterpreter='latex';
for ct = 1:length(f.Children(1).Children)
    f.Children(1).Children(ct).LineWidth = 2;
end
xlabel('Wavelength(nm)')
ylabel('$\tau$(ns)')
saveas(f,[names{ct2},'.emf'])
end