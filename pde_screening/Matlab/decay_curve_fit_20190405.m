clear all;
pth='..\Data\20190405';
files = dir(fullfile(pth,'*.csv'));
fprintf(1,'found %.0f files\n',length(files));
fitparameter_data = cell(1,length(files));
for i= 1:length(files)
    file = files(i).name;
    data = csvread(fullfile(pth,file),2); %for reading the csv file
    t = data(:,1); %they all have the same time
    tau = data(:,2:2:end);
    figure(1);clf %clf = clear current figure. just in case it was not empty
    hold on;
    plot(t',tau);     %plotting only lifetime data from column 1(col 1 has the time; : means to take everything),(1:2:end is to take from 1st column, then skip the next one and do this till the end; as every alternate column has the time); (then plotting from column 2 and keep skipping one till the end
    tau_mean = mean(tau,2);   %same meaning as the previous line
    
    plot(t,tau_mean,'k','LineWidth',2);
    figure(99);clf;
    t=data(:,1);
    plot(t,tau_mean); %t is x axis data and 'data' is the life time data on y axis
    [x1,~]=ginput(1); % when user inputs the x1 value by selecting from the plot
    idx1 = find(t>=x1,1,'first');
    [x2,~]=ginput(1); % when user inputs the x2 value by selecting from the plot
    idx2 = find(t>=x2,1,'first');
    %x1=915.3342;
    %x2=1.1502e+03;
    t=t((idx1+4):idx2); %takes the time from the newdata after limiting (overwrites the previous data)
    tau_mean=tau_mean(idx1:idx2);
    fitparameters=[];  % used in matlab to assign no value to a variable(mostly used) - by using this everything that does not value does not over write from other suceeding row of values 
    for ct = 1:size(tau,2)
        if any(tau((idx1-4):idx1,ct)>=3.5)
            fitparameters(ct) = nan;
            plot(t,tau((idx1+4):idx2,ct));
            test=0;
        else
            fitparameters(ct) = fit_decay_exponential(t,tau((idx1+4):idx2,ct),false);
        end
    end
    fitparameter_data{i}=fitparameters;
end 
 S = -inf; %assigned the smallest number (-infinity) to S
 for z= 1:length(fitparameter_data) % z runs from 1 to entire length of fitparameter_data
     temp = fitparameter_data{1,z};  %temp is a temporary file that contains all the data when extracting all the data out from fitparameter_data{1,z}...
    S=max([S,size(temp,2)]); %now S is assigned to have the maximum value as it runs over all the data stored in temp
 end 
newdata = nan(length(fitparameter_data),S); %here, at first all columns and rows are first assigned nan as for every experiment, there aren't equal number of data points. So to avoid over writing, all are assigned nan first
for z= 1:length(fitparameter_data) % following that, from here the loop runs from 1 through the entire length of fitparameter_data
    temp = fitparameter_data{1,z}; % temp is assigned to store values as the loop runs over all the total number of experiments(only to make the code look shorter and simpler)
    newdata(z,1:size(temp,2)) = temp;  % newdata now has (z,1:size(temp,2)) i.e z =6 and temp file has the maximum no. of files as 53(S value), so newdata is 6x53 matrix 
 end 

edges = linspace(min(newdata),max(newdata),ceil(sqrt(length(newdata))));
bw = edges(2)-edges(1);
edges=0:bw:200;
histogram(newdata,edges);
m= mean(newdata,'omitnan');
s= std(newdata,'omitnan');
title(sprintf('mean = %.2f ; std = %.2f',m,s));
xlabel('')
ylabel('#')

files

%edges=linspace(0,200,8);


%data = sort(newdata);
%bin_size = 10;
%subs = ceil(newdata/bin_size);
%M = accumarray(subs, data', [length(unique(subs)),1], @mean)
%S = accumarray(subs, data', [length(unique(subs)),1], @std)


return;


%%x=data(:,1:2:end);
%%y=data_mean;
%%xlabel('time(seconds)')
%%ylabel('lifetime(ns)')
%title('40nM IsoProterenol(96WP)')
%%title('40nM IP + 60nM P(12mins) + F')




%%x=2;mod(x,2)==0 % for checking odd or even 





%axis([0 600 1.8 3.4]); % for limitation of axis
%halfMax = (min(data_mean) + max(data_mean)) / 2;

% Find where the data first drops below half the max.

%%index2 = find(data_mean >= halfMax, 1, 'last');

%fwhm = index2-index1 + 1;

%plot([x(index1)-50 50+x(index2)], [halfMax halfMax]) % for drawing a line at fwhm

%find(x>=300,1,'first');
%val300 = find(x>=300,1,'first');
%max(data_mean(1:val300));

%firstpeakvalue = max(data_mean(1:val300));

%axis([0 1000 1.8 3.6]); % for limitation of axis