clear all;close all; clc;
setup.phi = pi/2-0.9;  % base offset in phase of the setup
setup.M = 0.9;  % base modulation
setup.f = 40E6;  %Hz
setup.ph = 12; 
ref.tau = 0.08E-9;  % ns
sam.tau = 5.0E-9;  % ns

% relative pulsewidth
relative_pulsewidth = ones(1,setup.ph);
relative_pulsewidth(1:6)=1.05; relative_pulsewidth(7:12)=0.95;

% some functions
tau2mod = @(tau,f) sqrt(1./((tau*2*pi*f).^2+1));
mod2tau = @(M,f) sqrt((1./M.^2)-1)/(2*pi*f);
tau2phi = @(tau,f) atan(tau*2*pi*f);
phi2tau = @(phi,f) tan(phi)/(2*pi*f);

% generate the reference and sample signal
ph = linspace(0,2*pi,setup.ph+1);ph(end)=[];
ref.M = setup.M*tau2mod(ref.tau,setup.f);
ref.phi = tau2phi(ref.tau,setup.f)-setup.phi;
ref.St = 1+ref.M*sin(ph+ref.phi); %top register
ref.Sb = 1+ref.M*sin(pi+ph+ref.phi); %bottom register
sam.M = setup.M*tau2mod(sam.tau,setup.f);
sam.phi = tau2phi(sam.tau,setup.f)-setup.phi;
sam.St = 1+sam.M*sin(ph+sam.phi); %top register
sam.Sb = 1+sam.M*sin(pi+ph+sam.phi); %bottom register

% multiply with relative pulsewidth
ref.St = ref.St.*relative_pulsewidth;
sam.St = sam.St.*relative_pulsewidth;
ref.Sb = ref.Sb.*relative_pulsewidth;
sam.Sb = sam.Sb.*relative_pulsewidth;

% fit and display signals
figure(1);clf;hold on
ref_fit_top = phimod_simple(ref.St,1,'r');
ref_fit_bottom = phimod_simple(ref.Sb,1,'g');
sam_fit_top = phimod_simple(sam.St,1,'b');
sam_fit_bottom = phimod_simple(sam.Sb,1,'k');
title('reference and sample for top and bottom register')

% calculate tau_phi and tau_mod of the sample
phict = atan(setup.f*2*pi*ref.tau) - ref_fit_top.phi;
phicb = atan(setup.f*2*pi*ref.tau) - ref_fit_bottom.phi;
modct = ref_fit_top.mod / sqrt(1/((setup.f*2*pi*ref.tau)^2+1));
modcb = ref_fit_bottom.mod / sqrt(1/((setup.f*2*pi*ref.tau)^2+1));
sam_phi_top = sam_fit_top.phi+phict;
sam_phi_bottom = sam_fit_bottom.phi+phicb;
sam_mod_top = sam_fit_top.mod/modct;
sam_mod_bottom = sam_fit_bottom.mod/modcb;
tau_phi_top = phi2tau(sam_phi_top,setup.f);
tau_phi_bottom = phi2tau(sam_phi_bottom,setup.f);
tau_mod_top = mod2tau(sam_mod_top,setup.f);
tau_mod_bottom = mod2tau(sam_mod_bottom,setup.f);

% show position on the phasor plot
f=figure(2);clf;hold on
circTau = [1:6]*1E-9;
circPhi = tau2phi(circTau,setup.f);
circMod = tau2mod(circTau,setup.f);
circPh = linspace(0,pi,1E3);
plot(0.5+cos(circPh)*0.5,sin(circPh)*0.5,'-')
plot(sam_mod_top*cos(sam_phi_top),sam_mod_top*sin(sam_phi_top),'ob','LineWidth',3)
plot(sam_mod_bottom*cos(sam_phi_bottom),sam_mod_bottom*sin(sam_phi_bottom),'xr','LineWidth',3)
plot(circMod.*cos(circPhi),circMod.*sin(circPhi),'.b','MarkerSize',10)
axis equal
ylim([0,0.6]);xlim([0 1]);
legend('circle','top register','bottom register')
%f.Position = [1000 800 725 480];

function [out,f] = phimod_simple(in,show,color)
    if nargin<2||isempty(show),show=False;end
    if nargin<3||isempty(color),color='b';end
    infft = fft(in);
    infft = infft./length(in);
    F0=squeeze( real(infft(1)));
    Fs=squeeze(-imag(infft(2)));
    Fc=squeeze( real(infft(2)));
    out.mod = (2*(sqrt(Fs.^2 + Fc.^2)))./F0;
    out.phi = atan2(Fc,Fs);
    out.dc = F0;
    f = @(ph,out) out.dc*(1+out.mod*sin(ph+out.phi));
    if show
        phI = linspace(0,2*pi,1E3+1);phI(end)=[];
        ph = linspace(0,2*pi,length(in)+1);ph(end)=[];
        plot(ph,in,[color,'o'],phI,f(phI,out),[color,'-'])
        xlim([0 2*pi])
    end
end