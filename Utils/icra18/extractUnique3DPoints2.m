function unique3DPoints = extractUnique3DPoints2(filePath)

% define relative landmark positions to their corresponding objects
landmark1Obj1 = [-5.5;-175;-135]/1000;
landmark2Obj1 = [-175;-2.5;-115]/1000;
landmark3Obj2 = [175;-7.5;-180]/1000;
landmark4Obj2 = [-67.5;-175;-110]/1000;
landmark5Static = [1880;-80;330]/1000;
landmark6Static = [190;0;0]/1000;
landmark7Static = [0;0;0]/1000;
landmark8Static = [-150;0;0]/1000;
landmark9Static = [0;400;0]/1000;
landmark10Static = [-240;-350;0]/1000;
landmark11Static = [-1610;-480;0]/1000;
landmark12Static = [-1550;100;0]/1000;
landmarksStatic= [landmark5Static,landmark6Static,landmark7Static,...
    landmark8Static,landmark9Static,landmark10Static,landmark11Static,landmark12Static];

% open obj1Groundtruth
file1ID = fopen(strcat(filePath,'landmarkMeasGraphFile.txt'),'r');
landmarkData = textscan(file1ID, '%s', 'delimiter', '\n', 'whitespace', '');
landmark = landmarkData{1};
fclose(file1ID);

% open obj1Groundtruth
file1ID = fopen(strcat(filePath,'obj1Groundtruth.txt'),'r');
Data1 = textscan(file1ID, '%s', 'delimiter', '\n', 'whitespace', '');
CStr1 = Data1{1};
fclose(file1ID);
% % open obj2Groundtruth
file2ID = fopen(strcat(filePath,'obj2Groundtruth.txt'),'r');
Data2 = textscan(file2ID, '%s', 'delimiter', '\n', 'whitespace', '');
CStr2 = Data2{1};
fclose(file2ID);

unique3DPoints = [];
staticPointAdded = zeros(8,1);

for i=1:size(landmark,1)
   line = str2double(strsplit(cell2mat(landmark(i)),' '));
   timeStep = line(2);
   label = line(3);
   objID = 0;
   switch label
    case 1
      objID = 1;
      landmarkObj = landmark1Obj1;
    case 2
      objID = 1;
      landmarkObj = landmark2Obj1;
    case 3
      objID = 2;
      landmarkObj = landmark3Obj2;
    case 4
      objID = 2;
      landmarkObj = landmark4Obj2;
   case {5,6,7,8,9,10,11,12}
      objID = 0;
   end
   if objID == 1
    objLine = str2double(strsplit(cell2mat(CStr1(timeStep)),' '));
   elseif objID == 2 
    objLine = str2double(strsplit(cell2mat(CStr2(timeStep)),' '));
   elseif objID == 0
       if ~staticPointAdded(label-4)
           % add static point
           unique3DPoints = [unique3DPoints,[label;landmarksStatic(:,label-4)]];
           staticPointAdded(label-4) = 1;
           continue
       else
           continue
       end
   end
   objPose = objLine(3:end);
   point3D = RelativeToAbsolutePositionR3xso3(objPose',landmarkObj);
   unique3DPoints = [unique3DPoints,[label;point3D]];
end

save('unique3DPoints','unique3DPoints')

end