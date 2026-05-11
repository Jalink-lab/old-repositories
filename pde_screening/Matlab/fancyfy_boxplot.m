set(0,'defaulttextinterpreter','latex')
f=gcf;
f.Position=[100 200 800 450];

f.Children(1).TickLabelInterpreter='latex';
f.Children(1).FontSize=10;

ax.XTickLabel = strrep(xticklabels,'_','\textsuperscript');
ax.XTickLabelRotation = -45;
saveas(f,'boxplot1.emf')