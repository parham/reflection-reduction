

configPath = sprintf('image_stitching_%s_v2.json', ...
     phm.utils.phmSystemUtils.getOSUser);

refMask = imread('/home/phm/Pictures/ThermoSense20/reflection_map_expA.bmp');
refResultMax = imread('/home/phm/Pictures/ThermoSense20/reflection_result_expA.png');

refMask(refMask ~= 0) = 1;