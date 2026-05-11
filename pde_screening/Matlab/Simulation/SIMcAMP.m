%% Two times Michaelis Menten kinetics
% Naming:
% E + S <-> ES -> E + P
% Forward rate kf, reverse rate kr, catalytic rate kcat
% Production
% AC + ATP <-> AC_ATP -> AC + cAMP
% Breakdown
% PDE + cAMP <-> PDE_cAMP -> PDE + AMP
%
% We assume equilibrium between E + S <-> ES
% kf[E][S] = kr[ES]
% We do not assume excess of substrate, but calculate the
% concentration of ES from the total concentration of E and S.
% [E] = [E0] - [ES]
% [S] = [S0] - [ES]
% 
% kf([E0] - [ES])([S0] - [ES]) = kr[ES]
% [ES] = (1/2)*(-sqrt([E0].^2-2*[E0].*([S0]-kd)+([S0]+kd).^2)+[E0]+[S0]+kd);
% kd = kr/kf

clear all;
t = linspace(0,400,1E3);dt=t(2)-t(1);
cAMP = nan(size(t));
cAMP(1) = 500; %start concentration of cAMP molecules (nM)
ATP = 1E6;  %concentration of ATP (nM) 

ES = @(E,S,kd) 0.5*(-sqrt(E.^2-2*E.*(S-kd)+(S+kd).^2)+E+S+kd);

%PDE is a matrix with [km, concentration]
PDE = ones(2,3);
PDE(1,1) = 10;     %kd nM
PDE(2,1) = 10;     %kd nM
PDE(1,2) = 300;    %total concentration nM
PDE(2,2) = 1E3;    %total concentration nM
PDE(1,3) = 0.25;   %kcat nM per second
PDE(2,3) = 0.05;   %kcat nM per second

%AC is a matrix with [Kd, concentration]
%binding: kd_ac = [PDE][cAMP]/[PDE_cAMP]
AC = ones(1,2);
AC(:,1) = 10;     %kd nM
AC(:,2) = 1E3;    %total concentration nM
AC(:,3) = 0.1;    %kcat nM per second

AC(:,3) = AC(:,3)*dt; %Converted fraction per cycle
PDE(:,3) = PDE(:,3)*dt; %Converted fraction per cycle

%find starting concentration
for ct = 0:1000
    old = mod(ct,2)+1;
    new = mod(ct+1,2)+1;
    PDE_cAMP = ES(PDE(:,2),cAMP(old),PDE(:,1));
    AC_ATP = ES(AC(:,2),ATP,AC(:,1));
    cAMP(new) = cAMP(old) + 10*sum(AC(:,3).*AC_ATP) - 10*sum(PDE(:,3).*PDE_cAMP);
end

events = false([1,10]);
stop = 1E3;
for ct = 2:length(t)
    %bound PDE concentration
    PDE_cAMP = ES(PDE(:,2),cAMP(ct-1),PDE(:,1));
    
    %bound AC concentration
    AC_ATP = ES(AC(:,2),ATP,AC(:,1));
    
    %add and remove
    cAMP(ct) = cAMP(ct-1) + sum(AC(:,3).*AC_ATP) - sum(PDE(:,3).*PDE_cAMP);
    if ~events(1)&&t(ct)>100
        events(1)=true;
        AC(:,2) = AC(:,2)+1E3; %activate AC's
    end
    if ~events(2)&&t(ct)>120
        AC(:,2) = AC(:,2)-1E3/(1+sum(t>120&t<140)); %deactivate AC's
        if t(ct)>140
            events(2)=true;
        end
    end
    
end
figure(1);clf;
subplot(1,2,1);plot(t,cAMP,'.');
xlabel('time(s)');ylabel('cAMP');title('linear')
subplot(1,2,2);semilogy(t,cAMP,'.')
xlabel('time(s)');ylabel('cAMP');title('log')