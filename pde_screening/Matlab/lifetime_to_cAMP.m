%% fit two components
% use the intensity of the components
% and the kd of the sensor
% to find the final concentration of cAMP
clear all
t = linspace(0,25,1E5); %ns
tau = [0.6,3.4]; %ns
N(1) = 2000;
N(2) = 1000;
I(1,:) = N(1)*exp(-t/tau(1));
I(2,:) = N(2)*exp(-t/tau(2));
plot(t,I) ;
sum(I,2)*(t(2)-t(1))./tau'

% [cAMP_EPAC] <==> [cAMP] + [EPAC]
% k = binding constant of EPAC
%  k = ([cAMP] * [EPAC]) / [cAMP_EPAC]
%  k = (a*b) / c 
%  a = (c*k) / b
% [cAMP ] = ([cAMP_EPAC]*k)/[EPAC]
