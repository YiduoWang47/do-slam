% Testing wrong motion estimate of vertex 23269 in vk-0001-335-426
motionVertexId = 23269;
K = [725, 0, 620.5; 0, 725, 187.0; 0, 0, 1];

measFilePath = '/home/mina/workspace/src/Git/gtsam/Data/GraphFiles/vk-Mina/vk-0001-335-426_Meas.graph';
fileID = fopen(measFilePath,'r');
measData = textscan(fileID,'%s','delimiter','\n','whitespace',' ');
measCStr = measData{1};
fclose(fileID);
IndexC = strfind(measCStr, '2PointsDataAssociation');
Index = find(~cellfun('isempty', IndexC));
pointIndices1 = [];
pointIndices2 = [];
for i=1:length(Index)
    fileID = fopen(measFilePath,'r');
    line = textscan(fileID,'%s',1,'delimiter','\n','headerlines',Index(i)-1);
    splitLine = strsplit(cell2mat(line{1,1}),' ');
    index1 = str2double(splitLine{1,2});
    index2 = str2double(splitLine{1,3});
    object = str2double(splitLine{1,4});
    if object == motionVertexId
        pointIndices1 = [pointIndices1, index1];
        pointIndices2 = [pointIndices2, index2];
    end
end

gtFilePath = '/home/mina/workspace/src/Git/gtsam/Data/GraphFiles/vk-Mina/vk-0001-335-426_GT.graph';
fileID = fopen(gtFilePath,'r');
gtData = textscan(fileID,'%s','delimiter','\n','whitespace',' ');
gtCStr = gtData{1};
fclose(fileID);

resultFilePath = '/home/mina/workspace/src/Git/gtsam/Data/GraphFiles/vk-Mina/vk-0001-335-426_result.graph';
fileID = fopen(resultFilePath,'r');
resultData = textscan(fileID,'%s','delimiter','\n','whitespace',' ');
resultCStr = resultData{1};
fclose(fileID);

cam1 = pointIndices1(1)-1;
IndexC = strfind(resultCStr, strcat({'VERTEX_POSE_R3_SO3'},{' '},...
        {num2str(cam1)},{' '}));
lineIndex = find(~cellfun('isempty', IndexC));
splitLine = strsplit(resultCStr{lineIndex,1},' ');
resultCamera1PoseMatrix = poseToTransformationMatrix(str2double(splitLine(3:end))');
figure;
imshow('00423.png')
hold on;
for i=1:length(pointIndices1) 
    IndexC = strfind(resultCStr, strcat({'VERTEX_POINT_3D'},{' '},...
        {num2str(pointIndices1(i))},{' '}));
    lineIndex = find(~cellfun('isempty', IndexC));
    splitLine = strsplit(resultCStr{lineIndex,1},' ');
    world3DPoint = str2double(splitLine(3:end))';
    % world --> camera
    nextCamera3DPoint = resultCamera1PoseMatrix\[world3DPoint;1];
    nextCamera3DPoint = nextCamera3DPoint(1:3,1);
    % camera --> image
    resultImagePoint = K * nextCamera3DPoint;
    resultImagePoint = resultImagePoint/resultImagePoint(3);
    scatter(resultImagePoint(1),resultImagePoint(2));
    hold on
end
hold off

IndexC = strfind(gtCStr, strcat({'VERTEX_POSE_R3_SO3'},{' '},...
        {num2str(cam1)},{' '}));
lineIndex = find(~cellfun('isempty', IndexC));
splitLine = strsplit(gtCStr{lineIndex,1},' ');
gtCamera1PoseMatrix = poseToTransformationMatrix(str2double(splitLine(3:end))');
figure;
imshow('00423.png')
hold on;
for i = 1:length(pointIndices1)
    IndexC = strfind(gtCStr, strcat({'VERTEX_POINT_3D'},{' '},...
        {num2str(pointIndices1(i))},{' '}));
    lineIndex = find(~cellfun('isempty', IndexC));
    splitLine = strsplit(gtCStr{lineIndex,1},' ');
    world3DPoint = str2double(splitLine(3:end))';
    % world --> camera
    nextCamera3DPoint = gtCamera1PoseMatrix\[world3DPoint;1];
    nextCamera3DPoint = nextCamera3DPoint(1:3,1);
    % camera --> image
    gtImagePoint = K * nextCamera3DPoint;
    gtImagePoint = gtImagePoint/gtImagePoint(3);
    scatter(gtImagePoint(1),gtImagePoint(2));
    hold on
end
hold off

cam2 = pointIndices2(1)-1;
IndexC = strfind(resultCStr, strcat({'VERTEX_POSE_R3_SO3'},{' '},...
        {num2str(cam2)},{' '}));
lineIndex = find(~cellfun('isempty', IndexC));
splitLine = strsplit(resultCStr{lineIndex,1},' ');
resultCamera2PoseMatrix = poseToTransformationMatrix(str2double(splitLine(3:end))');
figure;
imshow('00424.png')
hold on;
for i=1:length(pointIndices2) 
    IndexC = strfind(resultCStr, strcat({'VERTEX_POINT_3D'},{' '},...
        {num2str(pointIndices2(i))},{' '}));
    lineIndex = find(~cellfun('isempty', IndexC));
    splitLine = strsplit(resultCStr{lineIndex,1},' ');
    world3DPoint = str2double(splitLine(3:end))';
    % world --> camera
    nextCamera3DPoint = resultCamera2PoseMatrix\[world3DPoint;1];
    nextCamera3DPoint = nextCamera3DPoint(1:3,1);
    % camera --> image
    resultImagePoint = K * nextCamera3DPoint;
    resultImagePoint = resultImagePoint/resultImagePoint(3);
    scatter(resultImagePoint(1),resultImagePoint(2));
    hold on
end
hold off

IndexC = strfind(gtCStr, strcat({'VERTEX_POSE_R3_SO3'},{' '},...
        {num2str(cam2)},{' '}));
lineIndex = find(~cellfun('isempty', IndexC));
splitLine = strsplit(gtCStr{lineIndex,1},' ');
gtCamera2PoseMatrix = poseToTransformationMatrix(str2double(splitLine(3:end))');
figure;
imshow('00424.png')
hold on;
for i = 1:length(pointIndices2)
    IndexC = strfind(gtCStr, strcat({'VERTEX_POINT_3D'},{' '},...
        {num2str(pointIndices2(i))},{' '}));
    lineIndex = find(~cellfun('isempty', IndexC));
    splitLine = strsplit(gtCStr{lineIndex,1},' ');
    world3DPoint = str2double(splitLine(3:end))';
    % world --> camera
    nextCamera3DPoint = gtCamera2PoseMatrix\[world3DPoint;1];
    nextCamera3DPoint = nextCamera3DPoint(1:3,1);
    % camera --> image
    gtImagePoint = K * nextCamera3DPoint;
    gtImagePoint = gtImagePoint/gtImagePoint(3);
    scatter(gtImagePoint(1),gtImagePoint(2));
    hold on
end
hold off