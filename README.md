# Lungs Cancer Detection

## ✨ What This Tool Does

* **Live Fine-Tuning:** Gives you immediate visual feedback via sliders to adjust lung darkness and tumor brightness cutoffs.
* **Smart Filtering:** Clears out image borders, fills internal holes, and uses morphological operations to clean up background noise.
* **Automatic Measurements:** Instantly calculates the tumor's **Area**, **Perimeter**, and **Eccentricity** (how round or elongated the mass is).
* **Crash-Resistant:** Upgraded logic to handle "Normal" (healthy) or "Benign" (very tiny nodules) scans smoothly without throwing matrix errors if no tumor is found.

---

## 📊 The Dataset

To test and validate this pipeline, I used **The IQ-OTH/NCCD Lung Cancer Dataset** from Kaggle. It's a fantastic, clean collection of clinical 2D axial CT images. 

* **Dataset Download Link:** [Kaggle - The IQ-OTH/NCCD Lung Cancer Dataset](https://www.kaggle.com/datasets/hamdallak/the-iqothnccd-lung-cancer-dataset)

If you download it to test this code, you'll find three main folders:
1. 📁 **Malignant cases:** Great for testing the limits of large tumor extraction.
2. 📁 **Normal cases:** The ultimate safety test—checks if the algorithm correctly reports "No tumor detected" on healthy tissue.
3. 📁 **Benign cases:** Perfect for tuning the sliders to catch smaller, fainter nodules.

---

## 🔍 How the Code Works 

The application processes your CT scan through a 4-step pipeline every time you load an image or move a slider:

1. **Clean & Smooth:** It applies a *Wiener Filter* (`wiener2`) to remove background grain and scanner noise without blurring the edges of the organs.
2. **Isolate the Lungs:** It creates a dark threshold mask, clears the image borders, and fills in any holes to cleanly isolate just the lung cavity, cutting out the rest of the body.
3. **Target the Tumor:** It filters for bright, dense tissue masses *inside* the isolated lungs. It then uses structural filtering to ignore tiny artifacts and pinpoint the exact tumor.
4. **Calculate Metrics:** It uses MATLAB's geometric engine (`regionprops`) to analyze the final shape and instantly spit out its physical **Area**, **Perimeter**, and **Roundness (Eccentricity)**.

---

## ⚙️ How to Run It

Getting this up and running is incredibly simple:

1. Download the `TumorDetectionGUI.m` file from this repository.
2. Download the dataset folders from the Kaggle link provided above.
3. Open MATLAB (or MATLAB Online) in the directory where you saved the code.
4. Type this into your Command Window and press Enter:
   ```matlab
   TumorDetectionGUI
