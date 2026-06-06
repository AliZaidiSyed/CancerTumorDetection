function TumorDetectionGUI()
    % ---------------------------------------------------------
    % Main UI Figure Window
    % ---------------------------------------------------------
    fig = uifigure('Name', 'Interactive Lung Tumor Detection GUI', 'Position', [100 100 950 620]);

    % Struct to hold image data across callbacks
    imgData = struct('Original', [], 'Gray', []);

    % ---------------------------------------------------------
    % UI Components: Axes for Image Display
    % ---------------------------------------------------------
    ax1 = uiaxes(fig, 'Position', [25 320 275 250]);
    title(ax1, '1. Original Image');
    
    ax2 = uiaxes(fig, 'Position', [325 320 275 250]);
    title(ax2, '2. Lungs Isolated');
    
    ax3 = uiaxes(fig, 'Position', [625 320 275 250]);
    title(ax3, '3. Tumor ROI');

    % ---------------------------------------------------------
    % UI Components: Controls (Buttons & Sliders)
    % ---------------------------------------------------------
    % Load Image Button
    btnLoad = uibutton(fig, 'push', 'Text', '📂 Load CT Image', ...
        'Position', [25 230 150 40], 'FontSize', 13, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @loadImage);

    % Lung Threshold Slider (Controls the extraction of dark lung areas)
    lblLung = uilabel(fig, 'Position', [325 255 250 22], ...
        'Text', 'Lung Mask Threshold (Darkness Cutoff):', 'FontWeight', 'bold');
    sldLung = uislider(fig, 'Position', [325 240 250 3], ...
        'Limits', [0 255], 'Value', 150);
    sldLung.ValueChangedFcn = @(src, event) processImage();

    % Tumor Threshold Slider (Controls the extraction of bright tumor tissue)
    lblTumor = uilabel(fig, 'Position', [625 255 250 22], ...
        'Text', 'Tumor Threshold (Brightness Cutoff):', 'FontWeight', 'bold');
    sldTumor = uislider(fig, 'Position', [625 240 250 3], ...
        'Limits', [0 255], 'Value', 150);
    sldTumor.ValueChangedFcn = @(src, event) processImage();

    % ---------------------------------------------------------
    % UI Components: Feature Output Display
    % ---------------------------------------------------------
    lblResultsTitle = uilabel(fig, 'Position', [25 165 200 22], ...
        'Text', '📊 Extracted Features:', 'FontWeight', 'bold', 'FontSize', 13);
    
    txtResults = uitextarea(fig, 'Position', [25 25 400 130], ...
        'Value', {'System Ready.', 'Please load an image from your dataset folder to begin.'}, ...
        'Editable', 'off', 'FontSize', 14, 'FontName', 'Monospaced');

    % ---------------------------------------------------------
    % Callback: Load Image
    % ---------------------------------------------------------
    function loadImage(~, ~)
        [file, path] = uigetfile({'*.jpg;*.png;*.bmp;*.tif', 'All Image Files'});
        if isequal(file, 0)
            return; % User cancelled
        end
        
        % Read image
        I = imread(fullfile(path, file));
        imgData.Original = I;
        
        % Force grayscale conversion safely for dataset compatibility
        if size(I, 3) == 3
            imgData.Gray = rgb2gray(I);
        else
            imgData.Gray = I;
        end
        
        % Show raw image and process
        imshow(imgData.Original, 'Parent', ax1);
        processImage();
    end

    % ---------------------------------------------------------
    % Callback: Main Image Processing Pipeline
    % ---------------------------------------------------------
    function processImage()
        if isempty(imgData.Gray)
            return;
        end
        
        gray = imgData.Gray;
        lungThresh = sldLung.Value;
        tumorThresh = sldTumor.Value;
        
        % 1. Preprocessing
        grayWiener = wiener2(gray, [5 5]);   
        
        % 2. Lung Masking Sequence
        BW = grayWiener < lungThresh;              
        BW = imclearborder(BW);
        BW = imfill(BW, 'holes');
        
        % Safety check: ensure at least 2 distinct regions exist before filtering
        ccLungs = bwconncomp(BW);
        if ccLungs.NumObjects >= 2
            lungMask = bwareafilt(BW, 2);        
        else
            lungMask = BW; % Fallback if image framing isolates only one lung
        end
        
        % Isolate the anatomy
        maskedLungs = gray;
        maskedLungs(~lungMask) = 0;
        imshow(maskedLungs, 'Parent', ax2); 
        
        % 3. Tumor Extraction Sequence
        tumorMask = maskedLungs > tumorThresh;     
        tumorMask = bwareaopen(tumorMask, 50);
        
        % Safety check: Handle "Normal cases" folder gracefully if no elements pass threshold
        ccTumor = bwconncomp(tumorMask);
        if ccTumor.NumObjects >= 1
            tumorMask = bwareafilt(tumorMask, 1);
            SE = strel('disk', 8);
            tumorMask = imopen(tumorMask, SE);
            tumorDetected = true;
        else
            tumorMask = false(size(gray)); % Create blank empty mask
            tumorDetected = false;
        end
        
        % Display the segmented ROI
        imshow(tumorMask, 'Parent', ax3); 
        
        % 4. Quantification and UI Reporting
        if ~tumorDetected
            txtResults.Value = {
                'STATUS: No tumor detected!', ...
                '--------------------------------', ...
                'Area          : 0.00 pixels', ...
                'Perimeter     : 0.00 pixels', ...
                'Eccentricity  : 0.0000', ...
                '--------------------------------', ...
                'Tip: If this is a malignant scan, try lowering', ...
                'the Tumor Threshold slider.'
            };
        else
            stats = regionprops(tumorMask, 'Area', 'Perimeter', 'Eccentricity');
            if isempty(stats)
                txtResults.Value = {'STATUS: Structural cleaning cleared ROI.', 'Adjust Tumor Slider.'};
            else
                [~, idx] = max([stats.Area]);
                targetStats = stats(idx);
                
                % Update GUI text box
                txtResults.Value = {
                    'STATUS: MASS DETECTED', ...
                    '--------------------------------', ...
                    sprintf('Area          : %.2f px', targetStats.Area), ...
                    sprintf('Perimeter     : %.2f px', targetStats.Perimeter), ...
                    sprintf('Eccentricity  : %.4f', targetStats.Eccentricity), ...
                    '--------------------------------', ...
                    'Note: Eccentricity close to 0 implies round,', ...
                    'close to 1 implies elongated structures.'
                };
            end
        end
    end
end