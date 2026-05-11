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
    %a fixed point in the tau_mean curve seems to be the maximum in the isoP curve. Might even coinside with addition of propranolol
    %search for it in the first 250 seconds
    idx = find(t<250);
    idx2 = find(tau_mean(idx) == max(tau_mean(idx)));
    idx2 = idx(idx2);
    %for each curve we take the mean value in the first 20 seconds B
    %for the maximum we take the value at our fixed-point M
    %the fit is the time after the fixed point where the curve falls below(B+M/2)
    if pl
        figure(1);clf %clf = clear current figure. just in case it was not empty
        hold on;
        plot(t,tau);     %plotting only lifetime data from column 1(col 1 has the time; : means to take everything),(1:2:end is to take from 1st column, then skip the next one and do this till the end; as every alternate column has the time); (then plotting from column 2 and keep skipping one till the end
        plot(t,tau_mean,'k','LineWidth',2);
        plot(t(idx2),tau_mean(idx2),'rx','LineWidth',3);
    end
    fitparameters=nan(1,size(tau,2));  % used in matlab to assign no value to a variable(mostly used) - by using this everything that does not value does not over write from other suceeding row of values
    for ct = 1:size(tau,2)
        temp = tau(:,ct);
        B = mean(temp(t<=20));
        M = temp(idx2);
        crossing = (B+M)/2;
        idx_crossing = idx2+find(temp(idx2:end)<crossing,1,'first')-2;
        %interpolate crossing points
        SP = t(idx_crossing) + (crossing-temp(idx_crossing))              .* (t(idx_crossing+1) - t(idx_crossing)) ./ (temp(idx_crossing+1) - temp(idx_crossing));
        if ~isempty(SP)
            fitparameters(ct) = SP-t(idx2);
        end
        if pl
            figure(2);clf;hold on
            plot(t,temp,'b.-',t(idx2),temp(idx2),'rx',SP,crossing,'rx',[t(1),t(end)],[1,1].*crossing,'k--');
            title(sprintf('%.2f seconds',fitparameters(ct)))
            pause
        end
    end
    fitparameter_data{i,1}=file;
    fitparameter_data{i,2}=fitparameters;
end
%% Statistics. We will compare each set against the ONLY CELLS.
%Welch's t-test
clc
allt=[];
for ct = 1:size(data,1)
    y = cell2mat(data(end,2:end));y=y(parameter,:);y(isnan(y))=[];
    x = cell2mat(data(ct,2:end));x=x(parameter,:);x(isnan(x))=[];
    [t,nu] = welchttest(x,y);
    if nu<120,warning('low sample size for %s',xticklabels{ct});end
    if t>1.645 %one sided 95% confidence
        fprintf(1,'%s is significant \n',xticklabels{ct})
    end
    allt(ct)=t;
end