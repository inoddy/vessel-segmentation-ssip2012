% add all needed function paths
try
    functionname='test1.m';
    functiondir=which(functionname);
    functiondir=functiondir(1:end-length(functionname));
    addpath([functiondir '/../lib'])
catch me
    disp(me.message);
end


%rgbImage = imread('.\..\img\gold\retinopathy\diabetic_retinopathy\04_dr.jpg');
%groundTruth = imread('.\..\img\gold\retinopathy\diabetic_retinopathy_manualsegm\04_dr.tif');
rgbImage = imread('.\..\img\gold\healthy\healthy\01_h.jpg');
groundTruth = imread('.\..\img\gold\healthy\healthy_manualsegm\01_h.tif');
%rgbImage = imread('.\..\img\gold\glaucoma\glaucoma\01_g.jpg');
%groundTruth = imread('.\..\img\gold\glaucoma\glaucoma_manualsegm\01_g.tif');

%figure('name', 'RGB'), imshow(rgbImage);
%figure('name', 'GT'), imshow(groundTruth);

% Set the parameters [benevolent (mask), strict (marker)]
OPENING_SIZE       = [ 7 11] % useful values:  7 11,  3 11
CLOSING_SIZE       = [11 35] % useful values: 11 35, 31 35
PRE_THRESHOLD_CLOSING_SIZE = [ 0  0] % useful values:  0  0
DIFFUSION_T        = [4 0] 
DIFFUSION_SIGMA    = [1 0] 
DIFFUSION_RHO      = [4 0]  % useful values:  4  0, 8  0
THRESHOLD          = [16 36] % useful values: 16 32
DILATION_SIZE_AFTER_THRESHOLDING = 0; % useful values: 0, 1, 2
MEDIAN_SIZE        = [ 0  7] % useful values:  0  7, 0  9
PRE_RECONSTRUCTION_OPENING_SIZE = [ 0  0] % useful values:  0  0, 3  3
PRE_RECONSTRUCTION_CLOSING_SIZE = [ 0  0] % useful values:  0  0
FINAL_OPENING_SIZE = 0 % useful values:  2

DISPLAY_INTERMEDIATE = 0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare the mask and marker for reconstruction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

greenChannels       = cell(1,2);
greenChannelsOpened = cell(1,2);
greenChannelsClosed = cell(1,2);
topHats             = cell(1,2);
topHatsNormalized                = cell(1,2);
topHatsNormalizedClosed          = cell(1,2);
topHatsDiffused                  = cell(1,2);
topHatNormalizedThresholds       = cell(1,2);
topHatNormalizedThresholdMedians = cell(1,2);
topHatNormalizedThresholdOpenedMedians = cell(1,2);
topHatNormalizedThresholdOpenedClosedMedians = cell(1,2);
for i=1:2
    greenChannels{i} = rgbImage(:, :, 2);
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green'), imshow(greenChannels{i});
    end
    
    se=strel('disk', OPENING_SIZE(i));
    greenChannelsOpened{i} = imopen(greenChannels{i}, se);
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Opened'), imshow(greenChannelsOpened{i});
    end
    
    se=strel('disk', CLOSING_SIZE(i));
    greenChannelsClosed{i} = imclose(greenChannelsOpened{i}, se);
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Opened+Closed'), imshow(greenChannelsClosed{i});
    end
    
    topHats{i} = greenChannelsClosed{i} - greenChannels{i};
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Black Top Hat'), imshow(topHats{i});
    end
    
    topHatsNormalized{i}=adapthisteq(topHats{i});
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Black Top Hat Normalized'), imshow(topHatsNormalized{i});
    end

    se=strel('disk', PRE_THRESHOLD_CLOSING_SIZE(i));
    topHatsNormalizedClosed{i} = imclose(topHatsNormalized{i}, se);
%    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Black Top Hat Normalized Closed'), imshow(topHatsNormalizedClosed{i});
%    end    
    
    if DIFFUSION_T(i) > 0
        topHatsDiffused{i} = CoherenceFilter(topHatsNormalizedClosed{i},struct('T',DIFFUSION_T(i),'eigenmode',3, 'sigma', DIFFUSION_SIGMA(i), 'rho', DIFFUSION_RHO(i)));
    else
        topHatsDiffused{i} = topHatsNormalizedClosed{i};
    end
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Black Top Hat Normalized Closed Diffused'), imshow(topHatsDiffused{i});
    end     
    
    
    
    if i == 1
%        topHatNormalizedThresholds{i} = adaptivethreshold(topHatsDiffused{i}, 75, 0.0001, 0);
        topHatNormalizedThresholds{i} = adaptivethreshold(topHatsDiffused{i}, 200, 0.0005, 0);
        se=strel('disk', DILATION_SIZE_AFTER_THRESHOLDING);
        topHatNormalizedThresholds{i} = imdilate(topHatNormalizedThresholds{i}, se);
    else
        topHatNormalizedThresholds{i} = topHatsDiffused{i} > THRESHOLD(i);
    end
%    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Black Top Hat Normalized Threshold'), imshow(topHatNormalizedThresholds{i});
%    end
    
    if MEDIAN_SIZE(i) > 0
        topHatNormalizedThresholdMedians{i} = medfilt2(topHatNormalizedThresholds{i}, [MEDIAN_SIZE(i) MEDIAN_SIZE(i)]);
    else
        topHatNormalizedThresholdMedians{i} = topHatNormalizedThresholds{i};
    end
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Black Top Hat Normalized Threshold Median'), imshow(topHatNormalizedThresholdMedians{i});        
    end
    
    se=strel('disk', PRE_RECONSTRUCTION_OPENING_SIZE(i));
    topHatNormalizedThresholdOpenedMedians{i} = imopen(topHatNormalizedThresholdMedians{i}, se);
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Black Top Hat Normalized Threshold Opened Median'), imshow(topHatNormalizedThresholdOpenedMedians{i});
    end    
    
    se=strel('disk', PRE_RECONSTRUCTION_CLOSING_SIZE(i));
    topHatNormalizedThresholdOpenedClosedMedians{i} = imclose(topHatNormalizedThresholdOpenedMedians{i}, se);
    if DISPLAY_INTERMEDIATE
        figure('name', 'Green Black Top Hat Normalized Threshold Opened Closed Median'), imshow(topHatNormalizedThresholdOpenedClosedMedians{i});
    end    
    
    
end

if DISPLAY_INTERMEDIATE == 0
    figure('name', 'mask Green Black Top Hat Normalized Threshold Opened Median'), imshow(topHatNormalizedThresholdOpenedClosedMedians{1});
    figure('name', 'marker Black Top Hat Normalized Threshold Opened Median'), imshow(topHatNormalizedThresholdOpenedClosedMedians{2});
end

% Reconstruct the mask from the marker
reconstructionResult = reconstruction(topHatNormalizedThresholdOpenedClosedMedians{1}, topHatNormalizedThresholdOpenedClosedMedians{2});
if DISPLAY_INTERMEDIATE
    figure('name', 'Reconstruction Result'), imshow(reconstructionResult);        
end

% Smooth the vessel edges by opening
se=strel('disk', FINAL_OPENING_SIZE);
reconstructionResultOpened = imopen(reconstructionResult, se);
figure('name', 'Reconstruction Result Opened'), imshow(reconstructionResultOpened);        

% Remove small components by area opening
areaOpenedResult = bwareaopen(reconstructionResultOpened, 1000);
figure('name', 'Area Opened Result'), imshow(areaOpenedResult);        


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% summedRows = zeros(size(areaOpenedResult));
% summedColumns = zeros(size(areaOpenedResult));
% for i=1:size(areaOpenedResult, 1)
%     for j=1:size(areaOpenedResult, 2)        
%         if j > 1
%             summedRows(i, j) = summedRows(i, j-1) + areaOpenedResult(i, j);
%         else
%             summedRows(i, j) = areaOpenedResult(i, j);
%         end
%         if i > 1
%             summedColumns(i, j) = summedColumns(i-1, j) + areaOpenedResult(i, j);
%         else
%             summedColumns(i, j) = areaOpenedResult(i, j);
%         end
%     end
% end
% 
% areaOpenedResultFiltered = areaOpenedResult;
% WINDOW_HALF_SIZE = 50;
% for i=1+WINDOW_HALF_SIZE:size(areaOpenedResult, 1)-WINDOW_HALF_SIZE
%     for j=1+WINDOW_HALF_SIZE:size(areaOpenedResult, 2)-WINDOW_HALF_SIZE
%         topEdgeSum = summedRows(i-WINDOW_HALF_SIZE, j+WINDOW_HALF_SIZE) - summedRows(i-WINDOW_HALF_SIZE, j-WINDOW_HALF_SIZE);
%         bottomEdgeSum = summedRows(i+WINDOW_HALF_SIZE, j+WINDOW_HALF_SIZE) - summedRows(i+WINDOW_HALF_SIZE, j-WINDOW_HALF_SIZE);
%         leftEdgeSum = summedColumns(i+WINDOW_HALF_SIZE, j-WINDOW_HALF_SIZE) - summedColumns(i-WINDOW_HALF_SIZE, j-WINDOW_HALF_SIZE);
%         rightEdgeSum = summedColumns(i+WINDOW_HALF_SIZE, j+WINDOW_HALF_SIZE) - summedColumns(i-WINDOW_HALF_SIZE, j+WINDOW_HALF_SIZE);
%         if (topEdgeSum == 0) && (bottomEdgeSum == 0) && (leftEdgeSum == 0) && (rightEdgeSum == 0)
%           areaOpenedResultFiltered(i, j) = 0;  
%         end
%     end
% end
% figure('name', 'Area Opened Result Filtered'), imshow(areaOpenedResultFiltered);        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    


%adaptivelyThresholded = adaptivethreshold(topHatsNormalizedClosed{1}, 75, 0.0007, 0);
%figure('name', 'Adaptively Thresholded'), imshow(adaptivelyThresholded);

%adaptivelyThresholdedGreen = 1-adaptivethreshold(greenChannels{1}, 75, 0.007, 0);
%figure('name', 'Adaptively Thresholded Green'), imshow(adaptivelyThresholdedGreen);
