% variables
dataset = 'kitti'; %choose from {kitti,vkitti}
sequence = '0005';
variation = 'clone';
imageRange = 185:229;
nFeaturesPerFrame = 600; % number of features per frame
maxBackgroundFeaturesPerFrame = 200; % max number of static background features per frame
nFeaturesPerObject = 100; % number of features per object

settings.objectSegmentationMethod = 'GT'; % choose from {GT, MASK-RCNN, TRACK-RCNN}

settings.depth = 'GT';% choose from {GT, SPSS}
settings.applyDepthNoise = 0;
settings.featureMatchingMethod = 'GT';% choose from {GT, PWC-Net, flow-Net}
settings.applyMeasurementNoise = 1;

settings.applyOdometryNoise = 1;
settings.noiseArray = [0.0004 0.0004 0.06 0.0001 0.00004 0.00009 0.012 0.012 0.012];
rng(12);

% setup
cd /home/mina/workspace/src/Git/do-slam
if strcmp(dataset,'kitti')
    dir = '/media/mina/ACRV Samsung SSD T5/KITTI dataset/';
    settings.dataset = 'kitti';
    settings.depth = 'SPSS';
    settings.featureMatchingMethod = 'PWC-Net';
    settings.distanceThreshold = 0.0001;
    switch sequence
        case{'0000','0001','0002','0003','0004','0005','0006','0007','0008','0009','0010','0011','0012','0013'}
            K = [7.215377000000e+02 0.000000000000e+00 6.095593000000e+02; 
                0.000000000000e+00 7.215377000000e+02 1.728540000000e+02;
                0.000000000000e+00 0.000000000000e+00 1.000000000000e+00];
        case{'0014','0015','0016','0017'}
            K = [7.070493000000e+02 0.000000000000e+00 6.040814000000e+02; 
                0.000000000000e+00 7.070493000000e+02 1.805066000000e+02;
                0.000000000000e+00 0.000000000000e+00 1.000000000000e+00];
        case{'0018','0019','0020'}
            K = [7.183351000000e+02 0.000000000000e+00 6.003891000000e+02;
                0.000000000000e+00 7.183351000000e+02 1.815122000000e+02;
                0.000000000000e+00 0.000000000000e+00 1.000000000000e+00];
    end
    settings.K = K;
    % directories
    rgbDir = 'tracking/data_tracking_image_2/training/image_02/';
    depthDir = 'tracking/depth/';
    flowDir = 'tracking/flow/';
    objSegDir = 'mots/instances/';
    %objSegDir = 'tracking/mask/0000-gt/';
    motDir = 'tracking/data_tracking_label_2/training/label_02/';
    extrinsicsDir = 'tracking/extrinsics/';
    % data
    rgbI = strcat(dir,rgbDir,sequence,'/');
    depthI = strcat(dir,depthDir,sequence,'/');
    flowI = strcat(dir,flowDir,sequence,'/');
    maskI = strcat(dir,objSegDir,sequence,'/');
    %maskI = strcat(dir,objSegDir,'/');
    motFile = strcat(dir,motDir,sequence,'.txt');
    extrinsicsFile = strcat(dir,extrinsicsDir,sequence,'.txt');
elseif strcmp(dataset,'vkitti')
    settings.dataset = 'vkitti';
    settings.distanceThreshold = 0.0001;
    dir = '/media/mina/Data/mina/Downloads/Virtual_KITTI/';
    settings.K = [725, 0, 620.5; 0, 725, 187.0; 0, 0, 1];
    % directories
    rgbDir = 'vkitti_1.3.1_rgb/';
    depthDir = 'vkitti_1.3.1_depthgt/';
    objSegDir = 'vkitti_1.3.1_scenegt/';
    motDir = 'vkitti_1.3.1_motgt/';
    extrinsicsDir = 'vkitti_1.3.1_extrinsicsgt/';
    if strcmp(settings.objectSegmentationMethod,'MASK-RCNN')
     objSegDir = 'vkitti_MASK-RCNN/';
    end
    if strcmp(settings.featureMatchingMethod,'PWC-Net')
     flowDir = 'flow-PWC-Net/';
    elseif strcmp(settings.featureMatchingMethod,'flow-Net')
     flowDir = 'flow-FlowNet/';
    end
    % data
    rgbI = strcat(dir,rgbDir,sequence,'/',variation,'/');
    depthI = strcat(dir,depthDir,sequence,'/',variation,'/');
    if strcmp(settings.featureMatchingMethod,'PWC-Net') || strcmp(settings.featureMatchingMethod,'flow-Net')
        flowI = strcat(dir,flowDir,sequence,'/');
    else
        flowI = '';
    end
    maskI = strcat(dir,objSegDir,sequence,'/',variation,'/');
    motFile = strcat(dir,motDir,sequence,'_',variation,'.txt');
    extrinsicsFile = strcat(dir,extrinsicsDir,sequence,'_',variation,'.txt');
end
% pre-processing
fprintf('Preprocessing data ...\n')
cameraPoses = preprocessExtrinsics(extrinsicsFile,imageRange, settings);
odometry = extractOdometry(cameraPoses);
% feature extraction
fprintf('Feature extraction and tracking ...\n')
[frames,globalFeatures] = featureExtractionTracking(imageRange,settings.K,rgbI,depthI,flowI,maskI,...
    motFile,cameraPoses,nFeaturesPerFrame,nFeaturesPerObject,maxBackgroundFeaturesPerFrame,settings);
% graph files
fprintf('Writing graph files ...\n')
[globalCamerasGraphFileIndx, globalFeaturesGraphFileIndx, globalObjectsGraphFileIndx] = ...
    writeGTGraphFile(frames, globalFeatures, imageRange, sequence, settings);
settings.globalObjectsGraphFileIndx = globalObjectsGraphFileIndx;
writeMeasGraphFile(frames,globalFeatures,imageRange,sequence,...
    globalCamerasGraphFileIndx,globalFeaturesGraphFileIndx,globalObjectsGraphFileIndx,settings); 
