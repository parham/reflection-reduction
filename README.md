
# Reflectivity detection and reduction of thermographic images using image stitching technique and its applications on remote inspection

The established approach of thermographic inspection usually dictates the revision of collecting data by an operator during the inspection, which is not practical for remote thermographic inspection. In such scenarios, the system must be able to collect and semi-analyze the data autonomously as the data will be post-processed after the mission. Thus, such systems must provide the required steps to make sure the reliability and accuracy of the obtained data. Unknown surface reflectivities are one of the main sources of misinterpretations in thermal images that can be problematic especially when there is no access to the site for further confirmation after the operation. In this paper, a novel algorithm is presented that uses thermal images captured consecutively with limited camera movements, to detect and reduce possible reflection effects. Furthermore, we investigate the application of the proposed schema in the drone-based inspection of pipelines and oil refinery tanks.


Version 2.0 improvements:
1. Using GPU
1.2. add detect blurness to the process flow
2. Enhance the stitching using the non-rigid registration
3. Using Pyramid level in reflection localization to make the process faster and improve the result.

