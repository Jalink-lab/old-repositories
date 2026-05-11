%% Two times Michaelis Menten kinetics
% Production
% AC + ATP <-> AC_ATP -> AC + cAMP
% Breakdown
% PDE + cAMP <-> PDE_cAMP -> PDE + AMP
% 
% six rate constants
% seven concentrations that change over time
clear all;
t = linspace(0,10,1E4); dt = t(2)-t(1); %time axis
C = nan([length(t),7]); %AC,ATP,AC_ATP,cAMP,PDE,PDE_cAMP,AMP (nM)
k = [1,1,1,1,1,1]; %kfp,krp,kcatp,kfb,krb,kcatb (kr and kcat in 1/s, kf in nM/s)

C(1,:) = [0,1000,100,0,100,0,1000]; %starting conditions
event = false;
for ct = 2:length(t)
    % Production
    dEp = -k(1)*C(ct-1,1)*C(ct-1,2) + k(2)*C(ct-1,3) + k(3)*C(ct-1,3); %Ep = AC
    dSp = -k(1)*C(ct-1,1)*C(ct-1,2) + k(2)*C(ct-1,3);                  %Sp = ATP
    dESp = k(1)*C(ct-1,1)*C(ct-1,2) - k(2)*C(ct-1,3) - k(3)*C(ct-1,3); %ES = AC_ATP
    dPp = k(3)*C(ct-1,3);                                              %Pp = cAMP
    
    % Breakdown
    dEb = -k(4)*C(ct-1,5)*C(ct-1,4) + k(5)*C(ct-1,6) + k(6)*C(ct-1,6); %Ep = PDE
    dSb = -k(4)*C(ct-1,5)*C(ct-1,4) + k(5)*C(ct-1,6);                  %Sp = cAMP
    dESb = k(4)*C(ct-1,5)*C(ct-1,4) - k(5)*C(ct-1,6) - k(6)*C(ct-1,6); %ES = PDE_cAMP
    dPb = k(6)*C(ct-1,3);                                              %Pp = AMP
    
    C(ct,1) = C(ct-1,1) + dEp*dt;           %AC
    C(ct,2) = C(ct-1,2) + dSp*dt;           %ATP
    C(ct,3) = C(ct-1,3) + dESp*dt;          %AC_ATP
    C(ct,4) = C(ct-1,4) + dPp*dt + dSb*dt;  %cAMP
    C(ct,5) = C(ct-1,5) + dEb*dt;           %PDE
    C(ct,6) = C(ct-1,6) + dESb*dt;          %PDE_cAMP
    C(ct,7) = C(ct-1,7) + dPb*dt;           %AMP
    
    C(ct,2) = C(1,2); %ATP constant
    C(ct,7) = C(1,7); %AMP constant
%     if t(ct)>100&&~event(1)
%         C(ct,1) = C(ct,1) +1;
%         event=true;
%     end
end
%%
figure(1);clf
display = [1,3,4,5,6];
plot(t,C(:,display),'LineWidth',2)
ylim([-100 200]);
names = {'AC','ATP','AC-ATP','cAMP','PDE','PDE-cAMP','AMP'};
legend(names(display))

% figure(2);clf; %sanity check
% subplot(1,2,1);plot(t,C(:,1)+C(:,3));title('total AC')
% subplot(1,2,2);plot(t,C(:,5)+C(:,6));title('total PDE')