function [t,nu] = welchttest(x,y)
%Welch's t-test 
t = (mean(x)-mean(y))/sqrt((var(x)/length(x))+(var(y)/length(y)));
%Welch-Satterthwaite equation
nu = ((var(x)/length(x))+(var(y)/length(y)))^2 / ((var(x)^2/(length(x)^2*(length(x)-1)))+(var(y)^2/(length(y)^2*(length(y)-1))));

end

