classdef ReflectionBasedBlender < phm.core.phmCore

    methods
        function obj = ReflectionBasedBlender(varargin)
            obj = obj@phm.core.phmCore(varargin);
            obj.reset();
        end
        
        function [] = reset (obj)
            reset@phm.core.phmCore(obj);
        end
        
        function [result, mask] = process (~, frames, refmap)
            frms = cell2mat(frames);
            fms = cat(3,frms.WarppedFrame);
            msks = cat(3,frms.BlendMask);
            
            result = sum(fms .* msks, 3) ./ sum(msks,3);
            mask = mat2gray(sum(msks,3));
            
            pixarr = reshape(fms,[],size(fms,3));
            pixarr = mat2cell(pixarr,ones(1,size(pixarr,1)),size(pixarr,2));
            pixarr = reshape(pixarr, [size(fms,1), size(fms,2)]);
            pixarr = cellfun(@(x) min(nonzeros(x)), pixarr, 'UniformOutput', false);
            pixarr(refmap == 0) = {0};
            pixarr = cell2mat(pixarr);
            
            result(refmap ~= 0) = pixarr(refmap ~= 0);
        end
    end
end