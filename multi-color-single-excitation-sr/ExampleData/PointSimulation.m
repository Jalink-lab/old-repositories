% make a deformation map and generate sets of points that are deformed and
% shifted
clear all;close all; fclose all;
area = [10000,10000]; %nm
shift = [0,0]; %x,y (nm)
N = 100;
fr = 1000;

deformPoints = [0    ,0    , 10, 20;... %[x,y,dx,dy]
                10000,0    ,-30, 10;...
                0    ,10000,-20, 50;...
                10000,10000, 50, 20;...
                1000,7000,-50,-10;...
                8000,8000, 50,-10];
%show the map
figure(1);clf
quiver(deformPoints(:,1),deformPoints(:,2),deformPoints(:,3),deformPoints(:,4))
[X,Y] = meshgrid(0:1000:area(1),0:1000:area(2));
dP_interp(:,1)=X(:);
dP_interp(:,2)=Y(:);
dP_interp(:,3)=griddata(deformPoints(:,1),deformPoints(:,2),deformPoints(:,3),X(:),Y(:),'cubic');
dP_interp(:,4)=griddata(deformPoints(:,1),deformPoints(:,2),deformPoints(:,4),X(:),Y(:),'cubic');
f2=figure(2);clf
quiver(dP_interp(:,1),dP_interp(:,2),dP_interp(:,3),dP_interp(:,4))
saveas(f2,'simdat.svg')
%make points
ptL = nan(N*fr,3); %fr, x, y
ptL(:,1) = floor(1:1/N:(fr+1)-1/N);
ptL(:,2:3) = rand(N*fr,2).*area;
ptR = ptL;
ptR(:,2:3)=ptR(:,2:3)+shift;
%deform
dx = griddata(deformPoints(:,1),deformPoints(:,2),deformPoints(:,3),ptR(:,2),ptR(:,3),'cubic');
dy = griddata(deformPoints(:,1),deformPoints(:,2),deformPoints(:,4),ptR(:,2),ptR(:,3),'cubic');
ptR(:,2) = ptR(:,2) + dx;
ptR(:,3) = ptR(:,3) + dy;
%sanitize
ptR(ptR(:,2)<0,:)=[];
ptR(ptR(:,2)>area(1),:)=[];
ptR(ptR(:,3)<0,:)=[];
ptR(ptR(:,3)>area(2),:)=[];
figure(3);
plot(ptL(1:100,2),ptL(1:100,3),'.b',ptR(1:100,2),ptR(1:100,3),'.r')


h = {'"frame"','"x [nm]"','"y [nm]"'};
fidL = fopen('LeftSim.csv','wt');
fidR = fopen('RightSim.csv','wt');
for ct = 1:length(h)-1
    fprintf(fidL,[h{ct},',']);
    fprintf(fidR,[h{ct},',']);
end
fprintf(fidL,[h{end},'\n']);
fprintf(fidR,[h{end},'\n']);
for ct = 1:size(ptL,1)-1
    fprintf(fidL,'%.0f,%.2f,%.2f\n',ptL(ct,:));
end
for ct = 1:size(ptR,1)-1
    fprintf(fidR,'%.0f,%.2f,%.2f\n',ptR(ct,:));
end
fprintf(fidL,'%.0f,%.2f,%.2f',ptL(end,:));
fprintf(fidR,'%.0f,%.2f,%.2f',ptR(end,:));
fclose(fidL);
fclose(fidR);
