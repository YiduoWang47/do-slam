%--------------------------------------------------------------------------
% Author: Mina Henein - mina.henein@anu.edu.au - 10/12/2018
% Testing mean and std of motion edges
%--------------------------------------------------------------------------
%% 1. Config
% time
t0 = 0;
nSteps = 51;
tN = 50;
dt = (tN-t0)/(nSteps-1);
t  = linspace(t0,tN,nSteps);
 
config = CameraConfig();
config = setAppConfig(config); 
config.set('t',t);
config.set('nSteps',nSteps);
config.set('groundTruthFileName','Test_motionEdges_mean_std_GT.graph');
config.set('measurementsFileName','Test_motionEdges_mean_std_Meas.graph');
 
% SE3 Motion
config.set('motionModel','constantSE3MotionDA');
config.set('stdPosePose'  ,[0.03,0.03,0.03,pi/100,pi/100,pi/100]');
config.set('stdPosePoint' ,[0.06,0.06,0.06]');
config.set('std2PointsSE3Motion', [0.5,0.5,0.5]');
config.set('SE3MotionVertexInitialization','GT');
config.set('newMotionVertexPerNLandmarks',inf);
config.set('landmarksSlidingWindowSize',inf);
config.set('objectPosesSlidingWindow',false);
config.set('objectPosesSlidingWindowSize',inf);
config.set('newMotionVertexPerNObjectPoses',inf);
config.set('pointMotionMeasurement','point2DataAssociation');
config.set('pointsDataAssociationLabel','2PointsDataAssociation');

 
%% 2. Generate Environment
if config.rngSeed
    rng(config.rngSeed); 
end
 
% construct primitive trajectory
primitiveInitialPose_R3xso3 = [10 0 0 0 0 0.2]';
primitiveMotion_R3xso3 = [1.5*dt; 0; 0; arot(eul2rot([0.05*dt,0,0.005*dt]))];
primitiveTrajectory = ConstantMotionDiscretePoseTrajectory(t,primitiveInitialPose_R3xso3,primitiveMotion_R3xso3,'R3xso3');
 
constantSE3ObjectMotion = primitiveTrajectory.RelativePoseGlobalFrameR3xso3(t(1),t(2));
config.set('constantSE3Motion',constantSE3ObjectMotion);

% construct  robot trajectories
sampleTimes = t(1:floor(numel(t)/5):numel(t));
sampleWaypoints = primitiveTrajectory.get('R3xso3Pose',sampleTimes);
robotWaypoints = [linspace(0,tN+3,numel(sampleTimes)+1); 0 sampleWaypoints(1,:); 0 (sampleWaypoints(2,:)+0.1); 0 (sampleWaypoints(3,:)-0.1)];
robotTrajectory = PositionModelPoseTrajectory(robotWaypoints,'R3','smoothingspline');
 
environment = Environment();
environment.addEllipsoid([5 2 3],8,'R3',primitiveTrajectory);
 
%% 3. Initialise Sensor
cameraTrajectory = RelativePoseTrajectory(robotTrajectory,config.cameraRelativePose);
sensor = SimulatedEnvironmentOcclusionSensor();
sensor.addEnvironment(environment);
sensor.addCamera(config.fieldOfView,cameraTrajectory);
sensor.setVisibility(config,environment);
 
%% 4. Generate Measurements & Save to Graph File
sensor.generateMeasurements(config);
 
%% 5. load graph filesmeasurementsCell = graphFileToCell(config,config.measurementsFileName);
writeDataAssociationObjectIndices(config,1)
config.set('measurementsFileName',strcat(config.measurementsFileName(1:end-6),'Test.graph'));
config.set('groundTruthFileName',strcat(config.groundTruthFileName(1:end-6),'Test.graph'));
 
measurementsCell = graphFileToCell(config,config.measurementsFileName);
groundTruthCell  = graphFileToCell(config,config.groundTruthFileName);
 
%% 5. Solve
%no constraints
timeStart = tic;
graph0 = Graph();
config.set('mode','initialisation');
solver = graph0.process(config,measurementsCell,groundTruthCell);
solverEnd = solver(end);
totalTime = toc(timeStart);
fprintf('\nTotal time solving: %f\n',totalTime)
 
%get desired graphs & systems
graph0  = solverEnd.graphs(1);
graphN  = solverEnd.graphs(end);
%save results to graph file
graphN.saveGraphFile(config,'Test_motionEdges_mean_std_results.graph');

%% 6. Mean and std of motion ternary edges
filepath = strcat(config.savePath,'/Data/GraphFiles/Test_motionEdges_mean_std_results.graph');
fileID = fopen(filepath,'r');
Data = textscan(fileID,'%s','delimiter','\n','whitespace',' ');
CStr = Data{1};
fclose(fileID);
IndexC = strfind(CStr, config.pointSE3MotionEdgeLabel);
% find lines with a DataAssociation entry
Index = find(~cellfun('isempty', IndexC));
motionEdgesValues = zeros(3,length(Index));
motionEdgesNorm = zeros(1,length(Index));
for i=1:length(Index)
    line = strsplit(CStr{Index(i),1},' ');
    value = str2double(line(5:7));
    motionEdgesValues(:,i) = value';
    motionEdgesNorm(1,i)   = norm(value);
end

meanMotionEdges = mean(motionEdgesValues,2);
stdMotionEdges  = std(motionEdgesValues,0,2);

meanMotionEdgesNorm = mean(motionEdgesNorm);
stdMotionEdgesNorm = std(motionEdgesNorm);