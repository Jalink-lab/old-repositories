%% General outline
% 1) The coarse allignment
%    - find N distances within a large distance R from pkL to pkR
%    - make histogram in x and y. The maximum is the coarse allignment
% 2) The fine allignment
%    - Find nearest neighbor for each point within a distance of 100nm
%    - Make a 2D histogram at 100nm bins and calculate mean magnitude and
%      angle of locations in the bin.
clear all;
if ~exist('pkdata.m','file'),addpath('SMLM');end
if ~exist('kdtree_build.m','file'),addpath('kdtree');end
if exist('kdtree_build')~=3,kdtree_compile;end

% can generate substacks from big original data
% or take already present substack
switch 3
    case 1
        pth = 'D:\temp\DC_SR\20181113';
        leftfile = 'Left.csv';
        pkL = pkdata(fullfile(pth,leftfile));  %3.059.933 peaks
        pkL = pkL.keep([2,1,1000]);
        rightfile = 'Right.csv';
        pkR = pkdata(fullfile(pth,rightfile)); %3.365.069 peaks
        pkR = pkR.keep([2,1,1000]);
    case 2 
        pth = '..\ExampleData';
        leftfile = 'left.csv';
        rightfile = 'right.csv';
        pkL = pkdata(fullfile(pth,leftfile));
        pkR = pkdata(fullfile(pth,rightfile));
    case 3
        pth='..\ExampleData';
        leftfile = 'LeftSim.csv';
        rightfile = 'RightSim.csv';
        pkL = pkdata(fullfile(pth,leftfile));
        pkR = pkdata(fullfile(pth,rightfile));
end
minmaxF = [min([minframe(pkL),minframe(pkR)]),max([maxframe(pkL),maxframe(pkR)])];
figure(99);clf;plot(pkR);hold on;plot(pkL)
%% 1 first get N distances within a distance R from pkL to pkR
tic
N = 1E5;
R = 1000;
dist = nan(N,2);
distLoc = 1;distLocEnd=[];
go=true;fr=minmaxF(1);debug=false;
while go&&fr<=minmaxF(2)
    pkRxy = getxy(pkR,fr);
    pkLxy = getxy(pkL,fr);
    treeL = kdtree_build(pkLxy);
    for pk = 1:size(pkRxy,1)
        idxs = kdtree_ball_query(treeL, pkRxy(pk,:), R);
        if debug
            figure(1);clf;
            ph=linspace(0,2*pi,1E3);
            plot(pkLxy(:,1),pkLxy(:,2),'r.',pkRxy(:,1),pkRxy(:,2),'.b',pkLxy(idxs,1),pkLxy(idxs,2),'ro',pkRxy(pk,1),pkRxy(pk,2),'bx');
            hold on
            plot(pkRxy(pk,1)+R*cos(ph),pkRxy(pk,2)+R*sin(ph),'r--');
            clear ph;
            pause
        end
        if isempty(idxs),continue;end
        distLocEnd = distLoc+length(idxs)-1;
        if distLocEnd>N
            go=false;
            break;
        end
        dist(distLoc:distLocEnd,:) = pkRxy(pk,:)-pkLxy(idxs,:);
        distLoc=distLoc+length(idxs);
    end
    fr=fr+1;
end
%find maximum (square in a circle has size sqrt(2)*R, but seems not needed)
[n,edges] = histcounts(dist(:,1),round(sqrt(size(dist,1))));
centres = (edges(1:end-1)+edges(2:end))/2;
coarse(1) = centres(n==max(n));
[n,edges] = histcounts(dist(:,2),round(sqrt(size(dist,1))));
centres = (edges(1:end-1)+edges(2:end))/2;
coarse(2) = centres(n==max(n));
toc


%% 2 nearest neighbor distance from pkL to pkR
tic
dist = nan(pkR.n,4); %x,y,dx,dy
distLoc=1;
for fr = minmaxF(1):minmaxF(2)
    pkRxy = getxy(pkR,fr)-coarse;
    pkLxy = getxy(pkL,fr);
    treeL = kdtree_build(pkLxy);
    [idxs] = kdtree_nearest_neighbor( treeL, pkRxy);
    dist(distLoc:distLoc+length(idxs)-1,1:2) = pkRxy;
    dist(distLoc:distLoc+length(idxs)-1,3:4) = pkRxy-pkLxy(idxs,:);
    distLoc=distLoc+length(idxs);
end
dist(:,5) = sqrt(dist(:,3).^2+dist(:,4).^2); %actual distance
dist(dist(:,5)>200,:)=[]; %remove >100nm
toc
figure(1);clf;quiver(dist(:,1),dist(:,2),dist(:,3),dist(:,4));title('all arrows');
axis equal
figure(3);clf
histogram(dist(:,5));title('all arrows')
% bin them
binSize = 1000;
xedge = 0:binSize:(max(dist(:,1))+binSize);
yedge = 0:binSize:(max(dist(:,2))+binSize);
% watch and awe, no for loops!
[N,~,~,binx,biny] = histcounts2(dist(:,1),dist(:,2),xedge,yedge);
dx = accumarray([binx,biny],dist(:,3),[],@mean)+coarse(1);
dy = accumarray([binx,biny],dist(:,4),[],@mean)+coarse(2);
dx(N<10)=nan; %remove if based on too few datapoints
dy(N<10)=nan;
[X,Y]=meshgrid((xedge(2:end)+xedge(1:end-1))/2,(yedge(2:end)+yedge(1:end-1))/2);
figure(2);clf;quiver(X(:),Y(:),dx(:),dy(:));title('combined arrows');
axis equal
figure(4);clf
absDist = sqrt(dx.^2+dy.^2);
histogram(absDist(:));title('combined arrows')