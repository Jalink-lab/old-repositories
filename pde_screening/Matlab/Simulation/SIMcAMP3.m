%% Two times Michaelis Menten kinetics
% Naming:
% E + S <-> ES -> E + P
% Forward rate kf, reverse rate kr, catalytic rate kcat
% We use conventional Michaelis-Menten kinetics.
% Rate of production d[P]/dt = (Vmax [S]) / (Km + [S])
% Vmax = kcat[E0] , so depends on total enzyme concentration
% Km = (kr+kcat)/kf , so depends on rate-constants only
%
% Production
% AC + ATP <-> AC_ATP -> AC + cAMP
% Breakdown
% PDE + cAMP <-> PDE_cAMP -> PDE + AMP

clear all;
t_max = 2500;
v = @(Vmax,Km,S) (Vmax.*S)./(Km+S);
t = linspace(0,t_max,5E3);dt=t(2)-t(1); %s/cycle
cAMP = nan(size(t));
cAMP(1) = 15; %start concentration of cAMP molecules (nM)
ATP = 1E6;    %concentration of ATP (nM) 

%PDE is a matrix with [km, concentration]
PDE = ones(2,2); %PDE5 PDE9 D.P.Rotella 2007
PDE(1,1) = 1000;    %km nM
PDE(2,1) = 70;      %km nM
PDE(1,2) = 2600/60; %Vmax nM per second
PDE(2,2) = 4.9/60;  %Vmax nM per second

%AC is a matrix with [Kd, concentration]
%binding: kd_ac = [PDE][cAMP]/[PDE_cAMP]
AC = ones(1,2); %The catalytic mechanism of mammalian adenylyl cyclase (1997) doi: 
AC(:,1) = 340E6;       %km nM
AC(:,2) = 68E3/60;     %Vmax nM per second

AC(:,2) = AC(:,2)*dt;   %Converted Vmax to nM per cycle
PDE(:,2) = PDE(:,2)*dt; %Converted Vmax to nM per cycle

%find starting concentration
for ct = 0:1000
    old = mod(ct,2)+1;
    new = mod(ct+1,2)+1;
    %production
    dP = v(AC(:,2),AC(:,1),ATP);
    %breakdown
    dB = v(PDE(:,2),PDE(:,1),cAMP(old));
    
    cAMP(new) = cAMP(old) + sum(dP) - sum(dB);
end

events = false([1,10]);AC_add = 100*(68E3/60)*dt;
stop = 1E3;
for ct = 2:length(t)
    %production
    dP = v(AC(:,2),AC(:,1),ATP);
    %breakdown
    dB = v(PDE(:,2),PDE(:,1),cAMP(ct-1));
    
    cAMP(ct) = cAMP(ct-1) + sum(dP) - sum(dB);
    
    if ~events(1)&&t(ct)>100
        events(1)=true;
        AC(:,2) = AC(:,2)+AC_add; %activate AC's
    end
    if ~events(2)&&t(ct)>140
        AC(:,2) = AC(:,2)-AC_add/(1+sum(t>140&t<180)); %deactivate AC's
        if t(ct)>180
            events(2)=true;
        end
    end
end
epacBound = @(cAMP,kd) cAMP./(cAMP+kd);
fretresponse = @(bound,FretB,FretUB) bound*FretB + (1-bound)*FretUB;
lifetimeresponse = @(fret,tau_NF)  -(fret-1)*tau_NF;

figure(1);clf;
%subplot(1,2,1);
plot(t,cAMP,'.');
xlabel('time(s)');ylabel('cAMP(nM)');title('linear')
% subplot(1,2,2);semilogy(t,cAMP,'.')
% xlabel('time(s)');ylabel('cAMP(nM)');title('log')
figure(2);clf;
fret = fretresponse(epacBound(cAMP,3E3),0.21,0.575);
plot(t,fret,'.')
xlabel('time(s)');ylabel('FRET');title('Fret over time')
figure(3);clf
plot(t,lifetimeresponse(fret,4.1),'.')
xlabel('time(s)');ylabel('tau(ns)');title('Tau over time')