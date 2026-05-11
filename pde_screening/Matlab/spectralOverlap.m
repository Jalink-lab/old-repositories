clear all; close all; fclose all; clc;
set(0,'defaulttextinterpreter','latex')
pth = 'E:\nki_git\Spectra';

%fluorophores
f=figure(1);clf;hold on
mT=fluorophore(fullfile(pth,'mTurquoise2'));
Ve=fluorophore(fullfile(pth,'Venus'));
plot(mT.emission(:,1),mT.emission(:,2),Ve.excitation(:,1),Ve.excitation(:,2),'LineWidth',2)
legend('Emission mTurquoise2','Excitation Venus')
xlabel('Wavelength(nm)')
ylabel('Normalized Intensity')

f.Children(1).FontSize=14;
f.Children(1).Interpreter='latex';
f.Children(2).FontSize=14;
f.Children(2).TickLabelInterpreter='latex';
f.Position=[1000         918         797         420];
saveas(f,'spectra.emf')