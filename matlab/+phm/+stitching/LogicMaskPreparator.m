classdef LogicMaskPreparator < phm.core.phmCore
    %LOGICMASKPREPARATIONSTEP Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = LogicMaskPreparator(configs)
            obj = obj@phm.core.phmCore(configs);
            obj.reset();
        end
        
        function [] = reset (obj)
            reset@phm.core.phmCore(obj);
        end
        
        function [prep] = process (obj, frame)
            prep = frame;
            msk = frame.WarppedMask;
%             
%             edMask = edge(msk,obj.edgeMethod);
%             edMask = imdilate(edMask, strel('disk',obj.edgeSpread));
%             edMask = imgaussfilt(double(edMask),obj.edgeBlur);
%             edMask(msk == 0) = 0;
%             edMask(msk ~= 0) = 1 - edMask(msk ~= 0);
%             
%             prep.BlendMask = edMask;
            prep.BlendMask = msk;
        end
    end
end

