%--------------------------------------------------------------------------
% Author: Montiel Abello - montiel.abello@gmail.com - 23/05/17
% Contributors:
%--------------------------------------------------------------------------

clear all 
% close all 

%% 1. Config
% time
nSteps = 51;
t0 = 0;
tN = 10;
t  = linspace(t0,tN,nSteps);
% waypoints
staticPose1  = [5,8,0,0,0,0]';
staticPose2  = [4 16 4 pi/2 0 0]';
dynamicWaypoints = [0:2:tN; 4 5 7 10 7 3; 12 11 10 5 8 14; 8 5 2 3 6 4];

% construct trajectories
staticTrajectory1 = StaticPoseTrajectory(staticPose1,'R3xso3');
staticTrajectory2 = StaticPoseTrajectory(staticPose2,'R3xso3');
robotTrajectory   = PositionModelPoseTrajectory(dynamicWaypoints,'R3','smoothingspline');

% construct config & set properties
% CameraConfig is subclass of Config with properties specific to
% applications with a camera
config = CameraConfig();
% set properties of Config
config.set('t',t);
config.set('rngSeed',1);
config.set('noiseModel','Gaussian');
config.set('poseParameterisation','R3xso3');
config.set('poseVertexLabel'     ,'VERTEX_POSE_LOG_SE3');
config.set('pointVertexLabel'    ,'VERTEX_POINT_3D');
config.set('planeVertexLabel'    ,'VERTEX_PLANE_4D');
config.set('posePoseEdgeLabel'   ,'EDGE_LOG_SE3');
config.set('posePointEdgeLabel'  ,'EDGE_3D');
config.set('pointPlaneEdgeLabel' ,'EDGE_1D');
config.set('graphFileFolderName' ,'Testing');
config.set('groundTruthFileName' ,'groundTruth.graph');
config.set('measurementsFileName','measurements.graph');
config.set('stdPosePrior' ,[0.001,0.001,0.001,pi/600,pi/600,pi/600]');
config.set('stdPointPrior',[0.001,0.001,0.001]');
config.set('stdPosePose'  ,[0.01,0.01,0.01,pi/90,pi/90,pi/90]');
config.set('stdPosePoint' ,[0.02,0.02,0.02]');
config.set('stdPointPlane',0.001);
% set properties of RGBDSensorConfig
config.set('synchronizedData',0)
config.set('rgbImagesFolderName','rgb')
config.set('depthImagesFolderName','depth')
config.set('firstRGBImageName','1341847980.722988.png')
config.set('firstDepthImageName','1341847980.723020.png')
config.set('poseRotationRepresentation','quaternion')

%% 2. Generate Environment
if config.rngSeed; rng(config.rngSeed); end;
environment = Environment();
environment.set('environmentPoints',unique3DPoints)

%% 3. Initialise Sensor
cameraTrajectory = RelativePoseTrajectory(robotTrajectory,config.cameraRelativePose);
sensor = RGBDImageSensor();
sensor.addEnvironment(environment);
sensor.addCamera(config.fieldOfView,cameraTrajectory);

%% 5. Generate Measurements & Save to Graph File
sensor.generateMeasurements(config);

%% 6. Plot
figure
viewPoint = [-50,25];
axisLimits = [-1,15,-1,20,-1,10];
title('Environment')
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
view(viewPoint)
axis(axisLimits)
hold on
staticTrajectory1.plot()
staticTrajectory2.plot()
cameraTrajectory.plot(t)
environment.plot(t)
