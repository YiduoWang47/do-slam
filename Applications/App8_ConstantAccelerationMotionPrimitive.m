%--------------------------------------------------------------------------
% Author: Mina Henein - mina.henein@anu.edu.au - 06/12/2017
% Contributors:
%--------------------------------------------------------------------------
clear all 
% close all 

%% 1. Config
% time
nSteps = 121;
t0 = 0;
tN = 120;
dt = (tN-t0)/(nSteps-1);
t  = linspace(t0,tN,nSteps);

config = CameraConfig();
config = setAppConfig(config); % copy same settings for error Analysis
% config = setLowErrorAppConfig(config);
% config = setHighErrorAppConfig(config);
config.set('t',t);
config.set('nSteps',nSteps);
% config.set('noiseModel','Off');

% SE3 Motion
config.set('motionModel','constantAccelerationSE3MotionDA');
config.set('std2PointsSE3Motion', [0.1,0.1,0.1]');

%% 2. Generate Environment
if config.rngSeed
    rng(config.rngSeed); 
end

% construct primitive trajectory
primitiveInitialPose_R3xso3 = [10 0 0 0 0 0.2]';
primitiveMotion_R3xso3 = [1.5*dt; 0; 0; arot(eul2rot([0.05*dt,0,0.005*dt]))];
primitiveAcceleration_R3xso3 = [0.002;0.01;0.01;0.8;0.2;0.2];
primitiveTrajectory = ConstantAccelerationDiscretePoseTrajectory(t,primitiveInitialPose_R3xso3,...
    primitiveMotion_R3xso3,primitiveAcceleration_R3xso3,'R3xso3');

% construct  robot trajectories
sampleTimes = t(1:floor(numel(t)/5):numel(t));
sampleWaypoints = primitiveTrajectory.get('R3xso3Pose',sampleTimes);
robotWaypoints = [linspace(0,tN+3,numel(sampleTimes)+1); 0 sampleWaypoints(1,:); 0 (sampleWaypoints(2,:)+0.1); 0 (sampleWaypoints(3,:)-0.1)];
robotTrajectory = PositionModelPoseTrajectory(robotWaypoints,'R3','smoothingspline');
% Constant Acceleration - Assuming constant SE3 Motion between consecutive time steps
constantSE3ObjectMotion = zeros(6,length(t)-1);
for i = 1:numel(t)-1
    constantSE3ObjectMotion(:,i) = primitiveTrajectory.RelativePoseGlobalFrameR3xso3(t(i),t(i+1));
end
environment = Environment();
environment.addEllipsoid([5 2 3],8,'R3',primitiveTrajectory);

%% 3. Initialise Sensor
cameraTrajectory = RelativePoseTrajectory(robotTrajectory,config.cameraRelativePose);

% occlusion sensor
sensor = SimulatedEnvironmentOcclusionSensor();
sensor.addEnvironment(environment);
sensor.addCamera(config.fieldOfView,cameraTrajectory);
sensor.setVisibility(config,environment);

figure
spy(sensor.get('pointVisibility'));

% 4. Plot Environment
figure
hold on
grid on
axis equal
viewPoint = [-50,25];
axisLimits = [-30,50,-10,60,-10,25];
axis equal
xlabel('x (m)')
ylabel('y (m)')
zlabel('z (m)')
view(viewPoint)
axis(axisLimits)
primitiveTrajectory.plot(t,[0 0 0],'axesOFF')
cameraTrajectory.plot(t,[0 0 1],'axesOFF')
% set(gcf,'Position',[0 0 1024 768]);
frames = sensor.plot(0,environment);
% implay(frames);

%% 5. Generate Measurements & Save to Graph File, load graph file as well
config.set('constantAccelerationSE3Motion',constantSE3ObjectMotion);
    %% 5.1 For initial (without SE3)
    config.set('pointMotionMeasurement','Off')
    config.set('measurementsFileName','app8_measurementsNoSE3.graph')
    config.set('groundTruthFileName','app8_groundTruthNoSE3.graph')
    sensor.generateMeasurements(config);
    groundTruthNoSE3Cell = graphFileToCell(config,config.groundTruthFileName);
    measurementsNoSE3Cell = graphFileToCell(config,config.measurementsFileName);
    
    %% 5.2 For test (with SE3)
    config.set('pointMotionMeasurement','point2DataAssociation');
    config.set('measurementsFileName','app8_measurements.graph');
    config.set('groundTruthFileName','app8_groundTruth.graph');
    sensor.generateMeasurements(config);
    writeDataAssociationVerticesEdges_constantAcceleration(config,constantSE3ObjectMotion);
    measurementsCell = graphFileToCell(config,config.measurementsFileName);
    groundTruthCell  = graphFileToCell(config,config.groundTruthFileName);

%% 6. Solve
    %% 6.1 Without SE3
    timeStart = tic;
    initialGraph0 = Graph();
    initialSolver = initialGraph0.process(config,measurementsNoSE3Cell,groundTruthNoSE3Cell);
    initialSolverEnd = initialSolver(end);
    totalTime = toc(timeStart);
    fprintf('\nTotal time solving: %f\n',totalTime)

    %get desired graphs & systems
    initialGraph0  = initialSolverEnd.graphs(1);
    initialGraphN  = initialSolverEnd.graphs(end);
    %save results to graph file
    initialGraphN.saveGraphFile(config,'app8_resultsNoSE3.graph');
    
    %% 6.2 With SE3
    %no constraints
    timeStart = tic;
    graph0 = Graph();
    solver = graph0.process(config,measurementsCell,groundTruthCell);
    solverEnd = solver(end);
    totalTime = toc(timeStart);
    fprintf('\nTotal time solving: %f\n',totalTime)

    %get desired graphs & systems
    graph0  = solverEnd.graphs(1);
    graphN  = solverEnd.graphs(end);
    %save results to graph file
    graphN.saveGraphFile(config,'app8_results.graph');

%% 7. Error analysis
%load ground truth into graph, sort if required
graphGTNoSE3 = Graph(config,groundTruthNoSE3Cell);
graphGT = Graph(config,groundTruthCell);
fprintf('\nInitial results for without SE(3) Transform:\n')
resultsNoSE3 = errorAnalysis(config,graphGTNoSE3,initialGraphN);
fprintf('\nFinal results for SE(3) Transform:\n')
resultsSE3 = errorAnalysis(config,graphGT,graphN);

%% 8. Plot
    %% 8.1 Plot initial, final and ground-truth solutions
%no constraints
figure
subplot(1,2,1)
spy(solverEnd.systems(end).A)
subplot(1,2,2)
spy(solverEnd.systems(end).H)

h = figure; 
xlabel('x (m)')
ylabel('y (m)')
zlabel('z (m)')
hold on
grid on
axis equal
axisLimits = [-30,50,-10,60,-25,25];
axis(axisLimits)
view([-50,25])
%plot groundtruth
plotGraphFileICRA(config,groundTruthCell,'groundTruth');
%plot results
resultsNoSE3Cell = graphFileToCell(config,'app8_resultsNoSE3.graph');
resultsCell = graphFileToCell(config,'app8_results.graph');
plotGraphFileICRA(config,resultsNoSE3Cell,'initial',resultsNoSE3.relPose.get('R3xso3Pose'),resultsNoSE3.posePointsN.get('R3xso3Pose'))
plotGraphFileICRA(config,resultsCell,'solverResults',resultsSE3.relPose.get('R3xso3Pose'),resultsSE3.posePointsN.get('R3xso3Pose'))