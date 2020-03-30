
%% Project Description
% @author Parham Nooralishahi
% @email parham.nooralishahi@gmail.com
% @email parham.nooralishahi.1@ulaval.ca
% @organization Laval University - TORNGATS
% @date 2020 March
% @version 1.0
%
% @description The established approach of thermographic inspection usually 
% dictates the revision of collecting data by an operator during the 
% inspection, which is not practical for remote thermographic inspection. 
% In such scenarios, the system must be able to collect and semi-analyze 
% the data autonomously as the data will be post-processed after the mission. 
% Thus, such systems must provide the required steps to make sure the 
% reliability and accuracy of the obtained data. Unknown surface 
% reflectivities are one of the main sources of misinterpretations in 
% thermal images that can be problematic especially when there is no access 
% to the site for further confirmation after the operation. In this paper, 
% a novel algorithm is presented that uses thermal images captured consecutively 
% with limited camera movements, to detect and reduce possible reflection 
% effects. Furthermore, we investigate the application of the proposed 
% schema in the drone-based inspection of pipelines and oil refinery tanks.

clear;
clc;

showFootage = true;

%% Load configuration
progressbar.textprogressbar('Load Configuration: ');
configPath = sprintf('image_stitching_%s_v2.json', ...
     phm.utils.phmSystemUtils.getOSUser);
% configPath = sprintf('image_stitching_%s_v2_exp2.json', ...
%     phm.utils.phmSystemUtils.getOSUser);
configPath = sprintf('image_stitching_%s_v2_exp3.json', ...
    phm.utils.phmSystemUtils.getOSUser);
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
