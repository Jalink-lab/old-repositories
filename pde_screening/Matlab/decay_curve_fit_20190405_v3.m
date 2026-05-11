%fit logistic function to the decay
clear all;close all; clc;
pl=false;
pth='..\Data\20190405';
files = dir(fullfile(pth,'*.csv'));
fprintf(1,'found %.0f files\n',length(files));
fitparameter_data = cell(length(files),2);
for i= 1:length(files)
    file = files(i).name;
    data = csvread(fullfile(pth,file),2); %for reading the csv file
    t = data(:,1); %they all have the same time
    tau = data(:,2:2:end);
    tau_mean = mean(tau,2);   %same meaning as the previous line
    %the analysis requires a fixed point as a reference to time the decay
    %a fixed point in the tau_mean curve seems to be the maximum in the isoP curve. 
    %probably caused by the mixing of the medium caused by addition of propranolol.
    %search for it in the first 250 seconds
    idx = find(t<250);
    idx2 = find(tau_mean(idx) == max(tau_mean(idx)));
    PPP = idx(idx2); %propranololpoint
    %for each curve we want to fit a logistics function
    %it can start at the propranololpoint, but must finish before the
    %forskolin is added. This we can find from the mean as follows:
    %As a maximum we take the value at our fixed-point. M
    %As a minimum we take the mean of the datapoints untill 20 seconds. B
    %The last time the curve rises through ((B+M)/2) we take as the FKP(forskolinpoint)
    %The fit will go untill two timepoints (10 second)s before it.
    B = mean(tau_mean(t<=20));
    M = tau_mean(PPP);
    crossings = find(diff(tau_mean<((B+M)/2))); %diff detects change. If tau_mean becomes higher or lower than (B+M)/s it becomes 1 or -1. Find finds those values
    FKP = crossings(end)-2;
    if pl
        figure(1);clf %clf = clear current figure. just in case it was not empty
        hold on;
        plot(t,tau);     %plotting only lifetime data from column 1(col 1 has the time; : means to take everything),(1:2:end is to take from 1st column, then skip the next one and do this till the end; as every alternate column has the time); (then plotting from column 2 and keep skipping one till the end
        plot(t,tau_mean,'k','LineWidth',2);
        plot(t(PPP),tau_mean(PPP),'rx',t(FKP),tau_mean(FKP),'rx','LineWidth',3);
    end
    fitparameters=nan(5,size(tau,2));  % used in matlab to assign no value to a variable(mostly used) - by using this everything that does not value does not over write from other suceeding row of values
    for ct = 1:size(tau,2)
        %a fit needs an initial guess. The better it is, the better the fit
        %will be.
        % p(1) = x_midpoint
        % p(2) = startpoint
        % p(3) = endpoint
        % p(4) = growthrate
        f = @(x,p) p(2) + (p(3)-p(2))./(1+exp(-p(4)*(x-p(1)))); 
        err = @(x,y,p) sum((y-f(x,p)).^2);
        %for the midpoint we use our previous function
        temp = tau(:,ct);
        B = mean(temp(t<=20));
        M = temp(idx2);
        crossing = (B+M)/2;
        idx_crossing = idx2+find(temp(idx2:end)<crossing,1,'first')-2;
        if isempty(idx_crossing),continue;end
        %interpolate crossing points
        p(1) = t(idx_crossing) + (crossing-temp(idx_crossing)) .* (t(idx_crossing+1) - t(idx_crossing)) ./ (temp(idx_crossing+1) - temp(idx_crossing));
        p(2) = tau(PPP,ct);
        p(3) = tau(FKP,ct);
        p(4) = 0.1; %value that is decently close to optimal
        p = fminsearch(@(p) err(t(PPP:FKP),tau(PPP:FKP,ct),p),p);
        p(5) = err(t(PPP:FKP),tau(PPP:FKP,ct),p)/length(tau(PPP:FKP,ct)); %mean error (can be used to exclude bad fits from the histograms and boxplots later)
        if pl
            figure(2);clf;hold on
            plot(t,temp,'b.-',t,f(t,p),'r--');YL = ylim;
            plot([t(PPP),t(PPP)],YL,'k--',[t(FKP),t(FKP)],YL,'k--');ylim(YL);
            title(sprintf('p = <%.2f,%.2f,%.2f,%.2f,%.2e>',p(1),p(2),p(3),p(4),p(5)))
            pause
        end
        p(4) = 1/p(4); %from rateconstant to "typical decay time" in seconds.
        if p(5)>4E-3,continue;end %value of 4E-3 found by first running without selection
        if p(3)>2.5,continue;end %endpoint
        if p(3)<2,continue;end
        if p(2)>3.5,continue;end %start of fit
        if p(2)<2.8,continue;end
        p(1) = p(1)-t(PPP); %time from propranololpoint to midpoint
        fitparameters(:,ct) = p;
    end
    fitparameter_data{i,1}=file;
    fitparameter_data{i,2}=fitparameters;
end
%% lets have a look at all the fit errors
dat = cell2mat(fitparameter_data(:,2)');
histogram(dat(5,:))
title(sprintf('%.2f%% of cells are removed',100*sum(isnan(dat(5,:)))/size(dat,2)))
%a cuttoff of 0.06 seems reasonable.