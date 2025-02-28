%--------------------------------------------------------------------------
% Author: Mina Henein - mina.henein@anu.edu.au - 14/06/17
% Contributors:
%--------------------------------------------------------------------------

classdef RGBDImageSensor < Sensor
    % RGBDImageSensor represents a sensor used to generate
    % measurements from images captured by an RGBD camera
    %   -RGBDImageSensor converts the environment primitives and
    %    environment points to objects and points
    %   -This intermediate object representation allows more freedom in the
    %    kinds of observations and constraints which can be generated from
    %    environment primitives and points
    %   -Measurements of these points are generated and stored in a graph
    %    file.
    %
    %   ***Building your own sensor:
    %   1. Create subclass of Sensor
    %   2. Write an addEnvironment method that converts environment to
    %      objects you require 
    %   3. Write generateMeasurements method that simulates measurements of
    %      those objects and writes them to a graph file
    
    %% 1. Properties
    properties(GetAccess = 'protected', SetAccess = 'protected')
        points
        objects
        K
    end
    
    properties(Dependent)
        nPoints
        nObjects
    end
    
    %% 2. Methods
    % Dependent properties
    methods
        function nPoints = get.nPoints(self)
            nPoints = numel(self.points);
        end
        function nObjects = get.nObjects(self)
            nObjects = numel(self.objects);
        end
    end
    
    % Getter & Setter
    methods(Access = public) %set to protected later??
        function out = getSwitch(self,property,varargin)
            switch property
                case {'GP_Pose','R3xso3Pose','logSE3Pose','R3xso3Position','logSE3Position','axisAngle','R'}
                    out = self.trajectory.get(property,varargin{1});
                case 'static'
                    out = self.trajectory.get(property);
                case 'points'
                    if numel(varargin)==1
                        out = self.points(varargin{1});
                    else
                        out = self.points;
                    end
                case 'objects'
                    if numel(varargin)==1
                        out = self.objects(varargin{1});
                    else
                        out = self.objects;
                    end
                otherwise
                    out = self.(property);
            end
        	
        end
        
        function self = setSwitch(self,property,value)
        	self.(property) = value;
        end
    end
    
    % Constructor
    methods(Access = public)
        function self = RGBDImageSensor()
        end
    end
    
    % Add environment
    methods(Access = public)
        function self = addEnvironment(self,environment)
            points(environment.nEnvironmentPoints) = Point();
            %loop over environmentPoints, create Points
            for i = 1:environment.nEnvironmentPoints
                points(i) = Point(environment.get('environmentPoints',i));
            end
            
            %loop over environmentPrimitives, create objects
            objects(environment.nEnvironmentPrimitives) = SensorObject();
            for i = 1:environment.nEnvironmentPrimitives
                switch class(environment.get('environmentPrimitives',i))
                    case 'EP_Rectangle'
                        objects(i) = GEO_Plane(environment.get('environmentPrimitives',i));
                    case 'EP_default'
                        objects(i) = RigidBodyObject();
                        objects(i).RBOfromEP(environment.get('environmentPrimitives',i)); % runs special internal function for rigid body
                        % that creates from Environment Primitives
                    otherwise
                        error('Error: object conversion for %s not yet implemented',class(environment.get('environmentPrimitives',i)))
                end
            end
            
            %add properties
            self.points  = points;
            self.objects = objects;
        end
    end
    
    % Add camera
    methods(Access = public)
        function self = addCamera(self,trajectory)
            self.trajectory  = trajectory;
        end
    end
    
    %Declare external methods
    methods(Access = public)
        % Data Synchronization
        syncedData = synchroniseData(self,config)
        % Feature Extraction & Tracking
         [unique3DPoints,unique3DPointsCameras] = ...
             extractTrackFeatures(self,config,firstFrame,increment,lastFrame,method)        
        % Measurements
        generateRGBDImageMeasurements(self,config,unique3DPoints,unique3DPointsCameras)
    end
    
end

