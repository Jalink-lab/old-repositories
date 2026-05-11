classdef Injector < handle
    %Injector Wrapper for a Arduino Mega that runs three servos and three stepper motors
    
    properties
        mylocation      %location of Injector.m
        port            %Com port
        s				%serial object
        LM              %last recieved message
        servos_vals
    end
    
    methods
        function obj = Injector()
            [p,~,~] = fileparts(mfilename('fullpath'));obj.mylocation=p;
            obj.port=readconfig(fullfile(p,'config.ini'),'Injector','port');
            obj.s = serial(obj.port,'Parity','none','BaudRate',9600,'DataBits',8,'StopBits',1,'FlowControl','none');
            obj.servos_vals = [1000 2000 ; 1000 2000 ; 1000 2000];%calibration
            fopen(obj.s);
        end
        function ServoMove(obj,nr,set)
            msg = '';
            switch nr
                case {1,'isoP'}
                    msg = [msg,'1'];
                case {2,'2','fors'}
                    msg = [msg,'2'];
                case {3,'3','mix'}
                    msg = [msg,'3'];
            end
            if ischar(set)
                switch set
                    case {'Up','up'} %lowest value of servo
                        val = obj.servos_vals(nr,1);
                    case {'Down','down'}
                        val = obj.servos_vals(nr,2);
                end
            else
                val = obj.servos_vals(nr,1) + set*(diff(obj.servos_vals(nr,:))); %0 or 1 as input
            end
            msg = [msg,sprintf('%04d',val)];
            obj.sendm(msg);
            pause(1);
        end
        function StepperMove(obj,motor,dir,steps,mode)
            msg = '';
            switch motor
                case {1,'1','isoP'}
                    msg = [msg,'1'];
                case {2,'2','fors'}
                    msg = [msg,'2'];
                case {3,'3','mix'}
                    msg = [msg,'3'];
            end
            switch dir
                case {1,'up','forward'}
                    msg = [msg,'1'];
                case {0,'down','backward','back','backwards'}
                    msg = [msg,'0'];
            end
            msg = [msg,sprintf('%04d',steps)];
            switch mode
                case {0,'fastest'}
                    msg = [msg,'0'];
                case {1,'fast'}
                    msg = [msg,'1'];
                case {2,'normal'}
                    msg = [msg,'2'];
                case {3,'slow'}
                    msg = [msg,'3'];
                case {4,'slowest'}
                    msg = [msg,'4'];
            end
            obj.sendm(msg);
        end
        %% send message, recieve answer
        function sendm(obj,message)
            if obj.s.BytesAvailable>1 %safety measure
                warning('readbuffer was not empty: it said %s',fscanf(obj.s))
            end
            fprintf(obj.s,message); %send
            %wait for right nr of bytes. maximum 20 sec
            tic
            while obj.s.BytesAvailable<2&&toc<20
                pause(0.01)
            end
            obj.LM='';
            if obj.s.BytesAvailable>1
                obj.LM = fscanf(obj.s);
                obj.LM = obj.LM(1:end-2);
            end
        end
        
        %% when obj deleted, close connection
        function delete(obj)
            fclose(obj.s);
        end
    end
end

