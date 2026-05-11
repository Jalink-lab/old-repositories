clear all
%% demo simulation
rand(1) %a single random value between [0 1]

%% timing simulation (do not take too long)
tic
rand([1,1E5]);
toc

%% display
a = rand([1,1E5]);
histogram(a)

%% first simulation of a falling ball
clear all
figure(1);clf;
g = -9.81; %m/s^2
t = linspace(0,1,1E3); %simulate a single second (from 0 to 1 second in 10.000 steps)
dt = t(2)-t(1); %s
m = 1; %kg
s = 0.02; %radius
v = 0; %m/s
h = zeros(size(t));
h(1) = 0.6; %drop height in metre
events = [false];
for ct = 2:length(t)
    dv = g*dt;
    v = v + dv;
    dh = v*dt;
    h(ct) = h(ct-1) + dh;
    if h(ct)<s&&v<0
        v = -0.9*v;
    end
    if t(ct)>0.5&&~events(1)
        v = v+2;
        events(1)=true;
    end
    %display
%     plot(0,h(ct),'.')
%     ylim([-0.5,1])
%     xlim([-0.5 0.5])
%     title(['t=',num2str(t(ct))]);
%     pause(0.001);
end
plot(t,h);
xlabel('time(s)')
ylabel('Height(m)')