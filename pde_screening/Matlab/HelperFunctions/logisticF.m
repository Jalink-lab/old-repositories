function [y] = logisticF(x,p)
% Logistic function with parameters
% p(1) = x_midpoint
% p(2) = minimum (startpoint)
% p(3) = maximum (endpoint)
% p(4) = growthrate
y = p(2) + (p(3)-p(2))./(1+exp(-p(4)*(x-p(1)))); %sigmoid from 0 to 1 with 
end

