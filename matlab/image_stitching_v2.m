
%% Project Description
% @author Parham Nooralishahi
% @email parham.nooralishahi@gmail.com
% @email parham.nooralishahi.1@ulaval.ca
% @organization Laval University - TORNGATS
% @date 2020 March
% @version 1.0
%
% @description The conventional methods for inspection of industrial sites 
% involves the revision of data by an experienced inspector during the 
% acquisition process to avoid possible data missing and misinterpretation. 
% Despite all the advantages of drone-based inspection, inspectors does not 
% have physical-access to the side to check for any data ambiguity. Therefore, 
% it is essential for autonomous or semi-autonomous systems to check for 
% missing data or to highlight possible data ambiguity. Reflection in thermal 
% imagery data is one of the main sources of misinterpretation and it can be 
% problematic when there is no physical-access to the site for secondary 
% inspection. In this paper, we present a novel algorithm based on the analysis
% and stitching of consecutive aerial thermal images to detect areas with 
% reflection effect and possibly reduce these effects. The experiment on real 
% aerial image data captured from UAV platform shows that the introduced 
% approach is effective for detection and reduction of reflection effects on 
% thermal images.

clear;
clc;

showFootage = true;

%% Load configuration
progressbar.textprogressbar('Load Configuration: ');
configPath = sprintf('image_stitching_%s_v2.json', ...
    phm.utils.phmSystemUtils.getOSUser);
% configPath = sprintf('image_stitching_%s_v2_exp2.json', ...
%     phm.utils.phmSystemUtils.getOSUser);
% configPath = sprintf('image_stitching_%s_v2_exp3.json', ...
%    phm.utils.phmSystemUtils.getOSUser);
disp(['Config file: ', configPath]);
if ~isfile(configPath)
    progressbar.textprogressbar(100);
    progressbar.textprogressbar(' failed');
    error('Config File does not exist!')
end
phmConfig = phm.core.phmJsonConfigBucket(configPath);
progressbar.textprogressbar(100);
progressbar.textprogressbar(' done');

%% System configuration check
if parallel.gpu.GPUDevice.isAvailable()
    disp('The installed GPU on this station can be used for data processing.');
end
progressbar.textprogressbar('Check System Configuration: ');
progressbar.textprogressbar(100);
progressbar.textprogressbar(' done');

%% Data Source initialization
progressbar.textprogressbar('Data Source initialization: ');
dsConfig = phmConfig.getConfig('data_source');
imgds = imageDatastore(dsConfig.datasetPath, ...
    'FileExtensions', dsConfig.fileExtension);
progressbar.textprogressbar(100);
progressbar.textprogressbar(' done');

%% Steps initialization
progressbar.textprogressbar('Pipeline steps initialization: ');
% Pre-Processing steps
flattenStep = phm.imgproc.FlattenImage();
normStepFunc = @phm.imgproc.ImageProcessingUtils.normalizeAndMakingDouble;
resizeStep = phm.imgproc.ImageResizer(phmConfig.getConfig('resizing'));
histStep = phm.imgproc.HistogramBasedStreamNormalizer();
% Image stitching algorithm
matStep = phm.stitching.SIFTTransformEstimator(phmConfig.getConfig('matching'));
regStep = phm.stitching.ImageRegistrator(phmConfig.getConfig('register'));
% Image Blending and reflection detection and reduction
blendMaskStep = phm.stitching.LogicMaskPreparator(phmConfig.getConfig('blend_mask'));
blendStep = phm.stitching.ImageBlender(phmConfig.getConfig('blending'));
refStep = ReflectionLR_v2(phmConfig.getConfig('reflection'));
refBlender = ReflectionBasedBlender(phmConfig.getConfig('ref_blend'));
progressbar.textprogressbar(100);
progressbar.textprogressbar(' done');

%% Frame processing and matching
progressbar.textprogressbar('Frame matching step: ');
figure('Name','Stitching result viewer'); 
matches = cell(1, length(imgds.Files));

index = 1;
while hasdata(imgds)
    frame = read(imgds);
    % Visual cell initialization
    viscell = {};
    viscell{end + 1} = frame;
    %%%%
    prp = flattenStep.process(frame);
    prp = normStepFunc(prp);
    prp = resizeStep.process(prp);
    prp = histStep.process(prp);
    viscell{end + 1} = prp;
    [match, status] = matStep.process(prp);
    if status == 1
        warning(['features of frame (', str2double(index), ') do not contain enough points']);
        continue;
    elseif status == 2
        warning(['For frame (', str2double(index), '), Not enough inliers have been found.']);
        continue;
    end
    matches{index} = match;
    index = index + 1;
    viscell{end + 1} = match.WarppedFrame;
    
    if showFootage
        % Display the current frame and its processing steps
        montage(viscell,'BorderSize', [3 3]);
        pause(10^-3);
    end
    progressbar.textprogressbar((index / length(imgds.Files)) * 100.0);
end
progressbar.textprogressbar(' done');

%% Frame registration and blend preparation
disp('Perform pre-processing steps for the registration to measure the environment configurations');
[regConfig] = regStep.initialize(matches);

figure;
progressbar.textprogressbar('Frame registration and blending: ');
res = [];
reflectMap = [];
for index = 1:length(matches)
    matches{index} = regStep.process(matches{index}, regConfig);
    matches{index} = blendMaskStep.process(matches{index});
    reflectMap = refStep.process(matches{index});
    %res = blendStep.process(matches{index});
    if showFootage
        montage({matches{index}.WarppedFrame, ... 
            matches{index}.WarppedMask, ...
            matches{index}.BlendMask, ...
            reflectMap});
        pause(10^-3);
    end
    progressbar.textprogressbar((index / length(matches)) * 100.0);
end
progressbar.textprogressbar(' done');

%% Final Blend
[result, resMask] = refBlender.process(matches, reflectMap);
figure;
montage({result, resMask});
