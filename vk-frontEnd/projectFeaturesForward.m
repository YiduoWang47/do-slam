function [nextFrameFeatures,globalFeatures] = projectFeaturesForward(frame,K,nextFrame,rgbISize,globalFeatures)

featuresLocation = [];
featuresObjectId = [];
featuresMoving = [];
featuresLocation3D = [];
featuresOriginFrame = [];
featuresId = [];

globalLocation3D = globalFeatures.location3D;
globalWeight = globalFeatures.weight;
%globalId = globalFeatures.id;
globalFrame = globalFeatures.frame;
globalCameraLocation = globalFeatures.cameraLocation;
globalStatic = globalFeatures.static;
globalObjectId = globalFeatures.objectId;

for i=1:size(frame.features.location,1)
    world3DPoint = frame.features.location3D(:,i);
    nextCameraPoseMatrix = poseToTransformationMatrix(nextFrame.cameraPose);
    % static point
    if ~frame.features.moving(i)
        nextCamera3DPoint = nextCameraPoseMatrix\[world3DPoint;1];
        nextCamera3DPoint = nextCamera3DPoint(1:3,1);
        % camera --> image
        nextImagePoint = K * nextCamera3DPoint;
        nextImagePoint = nextImagePoint/nextImagePoint(3);
        if isPointWithinImageSize(nextImagePoint,rgbISize)
            featuresLocation = [featuresLocation; nextImagePoint(1:2)'];
            featuresObjectId = [featuresObjectId; -1];
            featuresMoving = [featuresMoving;0];
            featuresLocation3D = [featuresLocation3D, frame.features.location3D(:,i)];
            featuresOriginFrame = [featuresOriginFrame; frame.features.originFrame(i)];
            featuresId = [featuresId; frame.features.id(i)];
            % compute distance to all 3D points
            distances = sqrt(bsxfun(@plus,bsxfun(@plus,...
                (globalLocation3D(1,:).'-world3DPoint(1,1)).^2,...
                (globalLocation3D(2,:).'-world3DPoint(2,1)).^2),...
                (globalLocation3D(3,:).'-world3DPoint(3,1)).^2))';
            % find min distant point
            [~,index] = find(distances == min(distances));
            % if closest point is within 1 mm in 3D
            if(norm(world3DPoint(1:3,1) - globalLocation3D(:,index)) < 0.001)
                globalWeight(index,1) = globalWeight(index,1) + 1;
                assert(globalStatic(index,1) == 1);
                assert(globalObjectId(index,1) == -1);
            else
                disp('error; static point detected in previous frame should already be in global features structure')
            end
        end
    else
        % dynamic point
        objectId = frame.features.objectId(i);
        if ~isempty(frame.objects)
            currentFrameObjectIds = [frame.objects.id];
        else
            currentFrameObjectIds = [];
        end
        if ~isempty(nextFrame.objects)
            nextFrameObjectIds = [nextFrame.objects.id];
        else
            nextFrameObjectIds = [];
        end
        if ismember(objectId,currentFrameObjectIds) && ismember(objectId,nextFrameObjectIds)
            indx = find(currentFrameObjectIds == objectId);
            objectPoseWorldFrame = poseToTransformationMatrix(frame.objects(indx).poseWorldFrame);
            nextIndx = find(nextFrameObjectIds == objectId);
            nextObjectPoseWorldFrame = poseToTransformationMatrix(nextFrame.objects(nextIndx).poseWorldFrame);
            objectMotionWorldFrame = nextObjectPoseWorldFrame/objectPoseWorldFrame;
            movedWorld3DPoint = objectMotionWorldFrame * [world3DPoint;1];
            % project onto next frame
            nextCamera3DPoint = nextCameraPoseMatrix \ movedWorld3DPoint;
            nextCamera3DPoint = nextCamera3DPoint(1:3,1);
            % camera --> image
            nextImagePoint = K * nextCamera3DPoint;
            nextImagePoint = nextImagePoint/nextImagePoint(3);
            if isPointWithinImageSize(nextImagePoint,rgbISize)
                featuresLocation = [featuresLocation; nextImagePoint(1:2)'];
                featuresObjectId = [featuresObjectId; objectId];
                featuresMoving = [featuresMoving;nextFrame.objects(nextIndx).moving];
                featuresLocation3D = [featuresLocation3D, movedWorld3DPoint(1:3)];
                featuresOriginFrame = [featuresOriginFrame; frame.features.originFrame(i)];
                featuresId = [featuresId; length(globalLocation3D)+1];
                globalLocation3D = [globalLocation3D, movedWorld3DPoint(1:3)];
                globalWeight(end+1,1) = 1;
                %globalId(end+1,1) = featuresId(end);
                globalFrame(end+1,1) = featuresOriginFrame(end);
                globalCameraLocation = [globalCameraLocation, nextCamera3DPoint];
                globalStatic(end+1,1) = 0;
                globalObjectId(end+1,1) = featuresObjectId(end);
            end
        end
    end
end
nextFrameFeatures.location = featuresLocation;
nextFrameFeatures.objectId = featuresObjectId;
nextFrameFeatures.moving = featuresMoving;
nextFrameFeatures.location3D = featuresLocation3D;
nextFrameFeatures.originFrame = featuresOriginFrame;
nextFrameFeatures.id = featuresId;

globalFeatures.location3D = globalLocation3D;
globalFeatures.weight = globalWeight;
%globalFeatures.id = globalId;
globalFeatures.frame = globalFrame;
globalFeatures.cameraLocation = globalCameraLocation;
globalFeatures.static = globalStatic;
globalFeatures.objectId = globalObjectId;

end