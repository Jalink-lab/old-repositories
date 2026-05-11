function [param] = fit_decay_exponential(t,data,pl)
if nargin<3||isempty(pl),pl=false;end
%FIT_DECAY_EXPONENTIAL Summary of this function goes here
%   Detailed explanation goes here
t=t-t(1); % takes the time from 't' and subtracts whatever is the value of t(1). If t(1) is 10, then it subtracts 10 from all time points. So if time values are 10, 20, 30; after the subtraction they become 0,10,20.
data = data - mean(data(end-10:end)); % takes the mean of all the data(but the last 10 data points);(mean because at the bottom of the curve the data is very noisy , so its best to take mean rather than taking minimum. Last 10data points because I want to subtract the values of the baseline to fit all my data in the range of 1-0)
data = data/data(1); %(then divide the data point value with the data(1) to start values from 1 and end them at 0)

f = @(x,param) exp(-x/param(1));  %f is a function containing x values and a parameter and the rate is calculated as e to the power (-x/param); here the param is tau and x is the time
err = @(x,y,param) sum((y-f(x,param)).^2); %calculating the error here ; @(x,y,param) is the values that go in(i.e values from my data) and sum((y-f(x, param)).^2 ) is what comes out as output : which means that we are calculating the error between the fitted curve(f) and the original curve(y) and then adding all errors(sum)(squared to make all values positive)
param = 20; %(set at 20 to have a close estimate of the fit to the actual curve)
param = fminsearch(@(param) err(t,data,param),param); %finds the minimum of the parameter with respect/near to the error values that it has received
if pl
    plot(t,data,'.',t,f(t,param)) % . is to plot a dotted curve instead of a line curve
    title(sprintf('error = %.2f',err(t,data,param))) %sprintf is a function to print the error calculated and %.2f means limit the error value upto 2 decimal places)
end
end
