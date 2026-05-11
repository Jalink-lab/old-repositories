%clear all;clc;close all;
if ~exist('inj','var'),inj = Injector();end
inj.ServoMove(1,'up');
inj.ServoMove(2,'up');
inj.ServoMove(3,'up');pause(1);

fprintf(1,'Getting fluid\n');
inj.ServoMove(1,'down');pause(1);
inj.StepperMove(1,'backward',1000,'fastest')
inj.ServoMove(1,'up');pause(1)
fprintf(1,'Move stage around\n');
pause(2);
fprintf(1,'Eject\n');
inj.ServoMove(1,'down');pause(1);
inj.StepperMove(1,'forward',1000,'fastest')
inj.ServoMove(1,'up');
inj.ServoMove(3,'down');pause(1);
inj.StepperMove(3,'backward',1000,'fastest')
inj.StepperMove(3,'forward',1000,'fastest')
inj.ServoMove(3,'up');pause(1);
fprintf(1,'run complete\n');