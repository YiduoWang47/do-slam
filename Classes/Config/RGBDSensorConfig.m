%--------------------------------------------------------------------------
% Author: Mina Hnenein - mina.henein@anu.edu.au - 20/06/17
% Contributors:
%--------------------------------------------------------------------------

classdef RGBDSensorConfig < Config
    % RGBDSensorCONFIG is example of Config for specific application
    % This subclass used to add properties specific to a certain
    % application that should not be in base Config class
    %% 1. Properties
    properties(GetAccess = 'public', SetAccess = 'private')
        synchronizedData
        rgbImagesFolderName
        depthImagesFolderName
        firstRGBImageName
        firstDepthImageName
        poseRotationRepresentation
    end
    
    %% 2. Methods
    % Constructor
    methods(Access = public) 
        function self = RGBDSensorConfig()
            self.initPath();
        end
    end
    
    % Get & Set
    methods(Access = public) 
    	function out = getSwitch(self,property)
        	out = self.(property);
        end
        
        function self = setSwitch(self,property,value)
        	self.(property) = value;
        end
    end
end

