%icra18 main
% 0- $ roscore

% I- copy to a new terminal
    % $ rostopic echo /odom >> odom.txt
    % $ rostopic echo /mobile_base/sensors/imu_data >> imu.txt
    % $ rosbag play <rosbag_name.bag>
    
% II- run the matlab script writeOdomMeas.m
writeOdomMeas()
filePath = '/home/mina/workspace/src/Git/do-slam/Utils/icra18/odometryMeasGraphFile.txt';
modifyOdometryFile(filePath,51)

% III- in a new terminal
    % $ cd catkin_ws/
    % $ catkin_make
    % $ source devel/setup.bash
    % $ rosrun depth_extraction extract_depth_images.py
    
% III- in a different terminal
    % $ roscore 
    % $ rosbag play <rosbag_name.bag>

% IV-
%% GT & Measurements Graph Files
n = 51;
VICONFilePath = '/home/mina/Downloads/icra18/VICON/';
writeVICONGroundtruth(VICONFilePath,'robot.txt')
filePath = '/home/mina/workspace/src/Git/do-slam/Utils/icra18/';
modifyGTFile(strcat(filePath,'cameraGroundtruth.txt'),n)
writeVICONGroundtruth(VICONFilePath,'obj1.txt')
modifyGTFile(strcat(filePath,'obj1Groundtruth.txt'),n)
writeVICONGroundtruth(VICONFilePath,'obj2.txt')
modifyGTFile(strcat(filePath,'obj2Groundtruth.txt'),n)

rgbImagesPath =  '/home/mina/Downloads/icra18/images/rgb/';
depthImagesPath =  '/home/mina/Downloads//icra18/images/depth/';
K_Cam = [526.37013657, 0.00000000  , 313.68782938;
         0.00000000  , 526.37013657, 259.01834898;
         0.00000000  , 0.00000000  , 1.00000000 ];
     
[pointsMeasurements,pointsLabels,pointsTurtlebotID,pointsCameras] = ...
    manualLandmarkExtraction(rgbImagesPath,depthImagesPath, K_Cam);
pointsMeasurements = reshape(pointsMeasurements,[3,size(pointsMeasurements,1)/3])';
save('pointsMeasurements','pointsMeasurements');
save('pointsLabels','pointsLabels');
save('pointsTurtlebotID','pointsTurtlebotID');
save('pointsCameras','pointsCameras');
writeLandmarkMeas(pointsMeasurements,pointsLabels,pointsCameras)

unique3DPoints = extractUnique3DPoints(filePath);
writeGroundtruthGraphFile(filePath,unique3DPoints)
writeMeasurementsGraphFile(filePath)