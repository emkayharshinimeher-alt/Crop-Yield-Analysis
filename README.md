# Iowa Crop Yield Analysis - Statistical Learning

![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-success)

## Project Overview

Statistical analysis of crop yield variability in Iowa using 115 years of meteorological data (1900-2015) across 25 locations, resulting in 2,875 observations. This project applies dimensionality reduction, regression modeling, and temporal validation techniques to understand climate-yield relationships.

**Academic Project:** Statistical Learning of Earth System Sciences (MHYWI05)  
**Institution:** TU Dresden, Department of Hydrosciences  
**Instructor:** Dr. Jakob Zscheischler  

---

## Research Questions

1. How do meteorological variables influence crop yields across Iowa?
2. Can we reduce the dimensionality of climate predictors while retaining predictive power?
3. How well do statistical models trained on historical data predict future yields?
4. What is the impact of temporal autocorrelation on model validation?

---

##  Dataset

### Characteristics
- **Spatial coverage:** 25 locations across Iowa
- **Temporal coverage:** 115 years (1900-2015)
- **Total observations:** 2,875 data points
- **Target variable:** Crop yield (mean: 9.55, SD: 2.84)

### Predictors (23 meteorological variables)
- **Precipitation variables** (pr_1 – pr_6): Monthly and seasonal rainfall
- **Radiation variables** (rad_1 – rad_3): Solar radiation metrics
- **Temperature variables** (temp_1 – temp_4): Mean, min, max temperatures
- **Extreme indices:** warm_days, max_temp, max_5day_pr, and others

**Data distribution:** Approximately normal with slight left skew, likely reflecting extreme weather events.

---

##  Methodology

### 1. Data Exploration
- Descriptive statistics and distribution analysis
- Spatial correlation assessment (test for i.i.d. assumption)
- Visualization of yield variability

### 2. Trend Analysis
- Linear trend detection across 25 locations (α = 0.05)
- Multiple testing corrections (Bonferroni, FDR)
- **Results:** 23/25 locations showed apparent trends; 21 remained significant after FDR correction

### 3. Principal Component Analysis (PCA)
- Dimensionality reduction of 23 meteorological predictors
- **Key finding:** First 10 PCs explain **76.6%** of total variance
- Interpretation of dominant climate drivers

### 4. Regression Modeling

#### Best Subset Selection
- Selected 13 predictors: pr_1–pr_6, rad_2, rad_3, temp_2–temp_4, warm_days, max_temp, max_5day_pr
- Parsimonious, interpretable model

#### Lasso Regression
- L1 regularization with cross-validation
- Automatic variable selection
- Compared against Best Subset

### 5. Model Validation Strategies

#### Random Split (50/50)
- **Best Subset:** MSE = 3.58, R² = 0.56
- **Lasso:** MSE = 3.54, R² = 0.57
- Good predictive performance with random sampling

#### Temporal Split (Years 1–56 train, 57–115 test)
- **Best Subset:** MSE = 4.61, R² = 0.30
- **Lasso:** MSE = 4.61, R² = 0.30
- **Significant performance drop** due to temporal extrapolation

#### Prescribed Folds (7 folds, 8 consecutive years each)
- **Lasso:** MSE = 4.32, R² = 0.34
- Improved stability in λ selection
- More realistic validation for time series data

---

## 📈 Key Results

### 1. Spatial Autocorrelation
Strong positive correlation (r ≈ 0.94) in temperature between distant locations confirms that **meteorological predictors are NOT spatially independent**.

### 2. Temporal Trends
- Widespread yield trends detected across locations
- Only 6 locations significant under strict Bonferroni correction
- Trends likely reflect technological progress AND climate change

### 3. Predictive Performance
| Validation Strategy | Method | MSE | R² | Key Insight |
|---------------------|--------|-----|-----|-------------|
| Random Split | Lasso | 3.54 | 0.57 | Best performance |
| Temporal Split | Lasso | 4.61 | 0.30 | Poor extrapolation |
| Prescribed Folds | Lasso | 4.32 | 0.34 | Balanced approach |

### 4. Important Predictors
Most influential variables (from Best Subset):
- Precipitation during growing season (pr_1 – pr_6)
- Solar radiation (rad_2, rad_3)
- Temperature variability (temp_2, temp_3, temp_4)
- Extreme heat days (warm_days, max_temp)
- Extreme precipitation (max_5day_pr)

---

##  Technologies

**Language:** R (4.x)

**Key Libraries:**
```r
library(tidyverse)      # Data manipulation and visualization
library(leaps)          # Best subset selection
library(glmnet)         # Lasso regression
library(caret)          # Cross-validation
library(FactoMineR)     # PCA analysis
library(factoextra)     # PCA visualization
library(ggplot2)        # Advanced plotting
```

---

## 🚀 How to Run

### Prerequisites
```r
# Install required packages
install.packages(c("tidyverse", "leaps", "glmnet", "caret", 
                   "FactoMineR", "factoextra", "ggplot2"))
```


**Note:** Original dataset required (not included in repository). 
---

## Key Insights

### 1. Temporal Validation is Critical
Random splits overestimate predictive performance. Year-based validation reveals that models struggle with **temporal extrapolation** (R² drops from 0.57 → 0.30).

### 2. Climate-Yield Relationships Evolve
The performance gap between random and temporal validation suggests that **relationships between weather and yields change over time**, potentially due to:
- Technological advancements (irrigation, crop varieties)
- Changing climate patterns
- Agricultural management practices

### 3. Dimensionality Reduction Works
Despite 23 predictors, only ~10 principal components capture most variance, indicating **redundancy among meteorological variables**.

### 4. Non-stationarity Challenge
Models trained on historical data may not accurately predict future yields under novel climate conditions—a key challenge for **climate impact assessments**.

---

## Learning Outcomes

This project demonstrated:
- ✅ Practical application of PCA for dimensionality reduction
- ✅ Comparison of regression methods (Best Subset vs. Lasso)
- ✅ Importance of validation strategy in time series contexts
- ✅ Challenges of temporal autocorrelation and non-stationarity
- ✅ Integration of statistical learning with domain knowledge (agro-meteorology)

---

## References

**Course Materials:**
- MHYWI05 Statistical Learning of Earth System Sciences, TU Dresden
- Dr. Jakob Zscheischler, Department of Hydrosciences

**Methods:**
- James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021). *An Introduction to Statistical Learning*
- Zscheischler, J. et al. (2020). *A typology of compound weather and climate events*

---

## 👤 Author

**Harshini Meher Emkay**  
MSc Hydroscience & Engineering | TU Dresden  
📧 harshini_meher.emkay@mailbox.tu-dresden.de  

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

##  Acknowledgments

- Dr. Jakob Zscheischler for course instruction and dataset provision
- TU Dresden Department of Hydrosciences
---

*Project completed as part of MHYWI05 Statistical Learning of Earth System Sciences, TU Dresden*

**Dataset:** Iowa crop yields (115 years × 25 locations)  
**Focus:** Climate-yield relationships using statistical learning methods
```
