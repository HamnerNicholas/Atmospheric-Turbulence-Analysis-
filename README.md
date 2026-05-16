# Atmospheric Turbulence Statistical Analysis

## Overview
This project analyzes atmospheric turbulence effects in astrophotography by tracking Moon centroid displacement across video frames. The centroid motion is modeled as a stochastic process and analyzed using probability and random signal techniques.

The workflow combines:
- **Python/OpenCV** for centroid extraction from telescope video data
- **MATLAB** for statistical modeling, preprocessing, and visualization

The project investigates:
- Gaussian vs non-Gaussian turbulence behavior
- Distribution modeling using PDFs, CDFs, and Q-Q plots
- Higher-order statistics such as skewness and kurtosis
- Lucky imaging frame selection and probabilistic frame-yield estimation

---

## Motivation
Atmospheric turbulence introduces random distortions in astronomical imaging due to fluctuations in the refractive index of the atmosphere. These distortions cause apparent image motion and blur in telescope observations.

This project explores:
- How centroid displacement behaves as a stochastic process
- How imaging resolution affects turbulence statistics
- Whether Gaussian models adequately describe turbulence-induced motion
- How probability theory can be applied to estimate lucky imaging performance

---

## Features

### Python Processing Pipeline
- Video frame extraction using OpenCV
- ROI selection for target tracking
- Gaussian blur and Otsu thresholding
- Morphological filtering
- Centroid extraction using image moments
- Export of centroid displacement datasets

### MATLAB Statistical Analysis
- MAD-based outlier removal
- Moving-average detrending
- Gaussian PDF fitting
- Empirical CDF analysis
- Q-Q plot generation
- Dataset comparison across multiple resolutions
- Lucky imaging frame estimation using probability models

---

## Datasets
The project analyzes telescope recordings of the Moon captured under different imaging conditions:

| Dataset | Resolution | Duration |
|---|---|---|
| Dataset 1 | 480p | 5 min |
| Dataset 2 | 240p | 2 min |
| Dataset 3 | 1080p | 2 min |

---

## Data Availability

Raw telescope video files are not included due to GitHub file size limits. The processed centroid displacement datasets used for analysis are included in the `datasets/` directory.

## Statistical Methods
The detrended centroid displacement signal is treated as a stochastic process.

Computed statistics include:
- Mean
- Variance
- Standard deviation
- Skewness
- Kurtosis
- Threshold exceedance probabilities
- Normalized Z-score probabilities

The empirical distributions are compared against Gaussian models using:
- Histograms + Gaussian PDFs
- Empirical CDFs
- Q-Q plots

---

## Lucky Imaging Analysis
A practical extension estimates how many total frames are required to obtain a desired number of high-quality frames for lucky imaging.

A frame is considered "good" if:

|dx| < threshold

Using the empirical probability of obtaining a good frame, the expected frame count is estimated using a binomial probability model.

---

## Results Summary
Key findings:
- Higher-resolution datasets exhibit lower variance and more Gaussian-like behavior
- Lower-resolution datasets show increased intermittency and stronger non-Gaussian characteristics
- Atmospheric turbulence is approximately Gaussian in the central region, with deviations in the tails
- Thousands of frames may be required for effective lucky imaging under strict quality thresholds

---

## Technologies Used
- Python
- OpenCV
- NumPy
- MATLAB
- IEEE LaTeX (Overleaf)

---

## References
1. C. W. Therrien and M. Tummala, *Probability and Random Processes for Electrical and Computer Engineers*, 2nd ed.
2. P. M. Reeves et al., “A non-Gaussian model of continuous atmospheric turbulence for use in aircraft design,” NASA-CR-2639, 1976.

---

## Author
**Nicholas Hamner**  
California State University, Sacramento
