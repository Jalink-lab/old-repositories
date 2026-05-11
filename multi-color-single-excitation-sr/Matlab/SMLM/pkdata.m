classdef pkdata
    %PKDATA Summary of this class goes here
    %   Detailed explanation goes here
    properties (SetAccess = immutable, Hidden = true)
        filename
    end
    properties 
        n
        data
        header
    end
    properties
        index %1 id, 2 frame, 3 x, 4 y, 5 sigma, 6 intensity, 7 offset, 8 bkgstd, 9 ch2, 10 uncertainty_xy
        rm
    end
    
    methods
        function obj = pkdata(filename)
            if ~strcmp(filename(end-3:end),'.csv'),filename=[filename,'.csv'];end
            obj.filename = filename;
            obj.data = csvread(filename,1,0); %skip first row
            obj.n = size(obj.data,1);
            fid = fopen(filename);
            l = fgetl(fid);
            obj.header = regexp(l,',','split');
            fclose(fid);
            obj = obj.checkheader();
        end
        
        function obj = checkheader(obj)
            %checkheader finds all entries and makes a vector
            list = {'"id"','"frame"','"x [nm]"','"y [nm]"','"sigma [nm]"','"intensity [photon]"','"offset [photon]"','"bkgstd [photon]"','"chi2"','"uncertainty_xy [nm]"'};
            obj.index = nan(1,length(list));
            for ct = 1:length(list)
                temp = find(ismember(obj.header,list{ct}));
                if ~isempty(temp),obj.index(ct) = temp;end
            end
        end
        function [xy] = getxy(obj,frame)
            if nargin<2||isempty(frame)
                xy(:,1)=obj.data(:,obj.index(3));
                xy(:,2)=obj.data(:,obj.index(4));
            else
                xy(:,1)=obj.data(obj.data(:,obj.index(2))==frame,obj.index(3));
                xy(:,2)=obj.data(obj.data(:,obj.index(2))==frame,obj.index(4));
            end
        end
        function f = maxframe(obj)
            f = max(obj.data(:,obj.index(2)));
        end
        function f = minframe(obj)
            f = min(obj.data(:,obj.index(2)));
        end
        function obj = keep(obj,p)
            %p: [idx,min,max]
            obj.data(obj.data(:,obj.index(p(1)))<=p(2),:)=[];
            obj.data(obj.data(:,obj.index(p(1)))>=p(3),:)=[];
            obj.rm = obj.n - size(obj.data,1); %removed peaks
            obj.n=size(obj.data,1);
        end
        function plot(obj)
            plot(obj.data(:,obj.index(3)),obj.data(:,obj.index(4)),'.');
        end
    end
end

