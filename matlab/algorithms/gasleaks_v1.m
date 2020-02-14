
clear;
clc;

configFile = './algorithms/gasleak_v1_configs.yaml';
showFootage = true;

%%%%%%%%%% PRINT CONFIG INFO %%%%%%%%%%%%%
lemanchot.configuration.print_info( ...
    lemanchot.configuration.load_yaml_config(configFile));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Configure the image dataset using a folder
imgds = lemanchot.dsource.ImageFolderDataSource(...diso
    'ConfigFilePath', configFile);
% Preprocessing steps
preps = lemanchot.stitching_v1.PreprocessingSteps();
% Fernando's video stablizer
vstab = lemanchot.gasleak_v1.FernandoVideoStablizer(...
    'ConfigFilePath', configFile);
roicp = lemanchot.imgproc.ROICropper('ConfigFilePath', configFile);
% Frame Differentiate 
fdiffp = lemanchot.imgstream.GroundTruthDifferentiate('ConfigFilePath', configFile);
% Initiate the video player
videoPlayer = vision.VideoPlayer('Name', ...
    'Enhancement of aerial gas leak using image flow analysis', ...
    'Position', [50 50 800 600]);

of = opticalFlowFarneback;

magnitude = [];
orientation = [];
ARES = [];
while ~isDone(imgds)
%% Read a frame from image dataset
    [frame, index] = step(imgds);
    disp(['Frame (', num2str(index), ') is being processed.']);
%% Preprocess the frames
    [result, exeTime] = step(preps,frame);
    disp(['>>> Preprocessing executed : ', num2str(exeTime), ' seconds']);
%% Video stabilization
%     [transImg, tform, exeTime] = step(vstab,result);
%     disp(['>>> V executed : ', num2str(exeTime), ' seconds']);
%% Extract Region of Interest
    [roi, exeTime] = step(roicp,result);
    disp(['>>> ROI Extraction executed : ', num2str(exeTime), ' seconds']);
%% Calculate frame difference
    [diffimg, exeTime] = step(fdiffp, roi);
    
    diffimg = adaptthresh(diffimg, 0.9, 'ForegroundPolarity', 'bright');
    diffimg = mat2gray(diffimg);
    level = graythresh(diffimg);
    bw = imbinarize(diffimg,level);
    diffimg(bw == 0) = 0;
    
    %diffimg(diffimg <= std(diffimg(:))) = 0;
    flow = estimateFlow(of,diffimg);
%     if isempty(mask)
%         mask = zeros(size(flow.Magnitude), 'like', flow.Magnitude);
%     end
    a = flow.Magnitude;
    a(a < mean(a(:))) = 0;
    ARES = cat(3, ARES, a);
    
    magnitude = cat(3, magnitude, flow.Magnitude);
    orientation = cat(3, orientation, flow.Orientation);
    
    disp(['>>> Frame Difference executed : ', num2str(exeTime), ' seconds']);
    if showFootage
       % Show the consecutive frames
       pos = roicp.position;
       sz = roicp.size;
       out = zeros(size(result), 'like', result);
       out(pos(2):pos(2)+sz(2),pos(1):pos(1)+sz(1)) = diffimg;
       resimg = imfuse(result, out, 'blend','Scaling','joint');
       %step(videoPlayer,resimg);
       pause(10^-3);
    end
end

release(imgds);
release(preps);
release(vstab);
release(roicp);
release(videoPlayer);