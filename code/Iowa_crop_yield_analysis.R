# Iowa Crop Yield Analysis

# ---------------------------
# Setup
# ---------------------------
rm(list = ls())


setwd("C:/Users/MEHER/Desktop/HSE/Sem_2/Stats_final/Code")
load("C:/Users/MEHER/Desktop/HSE/Sem_2/Stats_final/Code/Iowa.RData")

# Packages
library(ggplot2)
library(dplyr)
library(leaps)
library(glmnet)

# ---------------------------
# Task (a) Data exploration
# ---------------------------


print(mean_yield <- mean(DATA$yield))
print(sd_yield <- sd(DATA$yield))
print(n_predictors <- ncol(DATA) - 3)   # excluding yield, loc, year
print(n_samples <- nrow(DATA))


# Histogram of yield
hist(DATA$yield,
     col = "#008080", border = "white", freq = FALSE,
     main = "Yield Distribution", xlab = "Yield")
lines(density(DATA$yield), col = "red", lwd = 2)
abline(v = mean_yield, col = "black", lwd = 2, lty = 2)

# ---------------------------
# Task (b) i.i.d
# ---------------------------

# correlation between loc 15 and loc 24 for temp_1
loc15 <- DATA$temp_1[DATA$loc == 15]
loc24 <- DATA$temp_1[DATA$loc == 24]
print(cor_15_24 <- cor(loc15, loc24))

# Combine into a data frame
df_temp15_24 <- data.frame(
  loc15 = loc15,
  loc24 = loc24
)

ggplot(df_temp15_24, aes(x = loc15, y = loc24)) +
  geom_point(color = "#F2B104", alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#f9f9f9", color = NA),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank()
  )+
  labs(
    title = "Scatter Plot(temp_1): Location 15 vs 24",
    x = "Loc15",
    y = "Loc24"
  )
# ---------------------------
# Task (c) Trends
# ---------------------------

alpha <- 0.05
trend_results <- data.frame(Location = 1:25, p_value = NA)

for (i in 1:25) {
  df <- DATA[DATA$loc == i, ]
  fit <- lm(yield ~ year, data = df)
  trend_results$p_value[i] <- summary(fit)$coefficients["year","Pr(>|t|)"]
}

trend_results$significant <- trend_results$p_value < alpha
cat("Number of locations with significant trends:", sum(trend_results$significant), "\n")

# Multiple testing
trend_results$bonf <- p.adjust(trend_results$p_value, "bonferroni") < alpha
trend_results$fdr <- p.adjust(trend_results$p_value, "fdr") < alpha
cat("After Bonferroni correction:", sum(trend_results$bonf), "\n")
cat("After FDR correction:", sum(trend_results$fdr), "\n")
print(trend_results)


# ---------------------------
# Task (d) PCA
# ---------------------------

Pred <- select(DATA, -yield, -loc, -year)
pred_scaled <- scale(Pred)
pca_result <- prcomp(pred_scaled, scale. = FALSE)
summary(pca_result)

explained_variance <- pca_result$sdev^2 / sum(pca_result$sdev^2)
cumulative_variance <- cumsum(explained_variance)
num_components <- which(cumulative_variance >= 0.75)[1]

scree_plot <- data.frame(Principal_Component = 1:length(explained_variance),
                         Variance_Explained = explained_variance,
                         Cumulative_Variance = cumulative_variance)
ggplot(scree_plot, aes(x = Principal_Component)) +
  geom_bar(aes(y = Variance_Explained), stat = "identity", fill = "#800000", alpha = 1) +
  geom_line(aes(y = Cumulative_Variance), color = "red", size = 1) +
  geom_point(aes(y = Cumulative_Variance), color = "red", size = 2) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#f9f9f9", color = NA),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank()
  )+
  labs( title = "Scree Plot",
    x = "Principal Component", y = "Explained Variance") 

# ---------------------------
# Task (e) Random split regression
# ---------------------------

set.seed(6)
n <- nrow(DATA)
train_idx <- sample(1:n, n/2)
train <- DATA[train_idx, ]
test <- DATA[-train_idx, ]

# Best subset
best_subset <- regsubsets(yield ~ . -loc -year, data = train, nvmax = 23)
best_sum <- summary(best_subset)
best_model <- which.min(best_sum$bic)
best_variables <- names(best_sum$which[best_model, ])[best_sum$which[best_model, ]]
print(best_variables <- best_variables[best_variables != "(Intercept)"])

fmla <- as.formula(paste("yield ~", paste(best_variables, collapse = "+")))
best_lm <- lm(fmla, data = train)
best_pred <- predict(best_lm, newdata = test)

# Lasso
x_train <- model.matrix(yield ~ . -loc -year, train)[, -1]
y_train <- train$yield
x_test <- model.matrix(yield ~ . -loc -year, test)[, -1]
y_test <- test$yield

cv_lasso <- cv.glmnet(x_train, y_train, alpha = 1, nfolds = 7)
best_lambda <- cv_lasso$lambda.min
lasso_fit <- glmnet(x_train, y_train, alpha = 1, lambda = best_lambda)
lasso_pred <- predict(lasso_fit, newx = x_test)

mse_best <- mean((y_test - best_pred)^2)
r2_best <- cor(y_test, best_pred)^2
mse_lasso <- mean((y_test - lasso_pred)^2)
r2_lasso <- cor(y_test, lasso_pred)^2


df_best <- data.frame(Observed = y_test, Predicted = best_pred)
df_lasso <- data.frame(
  Observed = test$yield,
  Predicted = as.numeric(lasso_pred)
)

# Best Subset Plot
ggplot(df_best, aes(x = Observed, y = Predicted)) +
  geom_point(color = "#0079c1", alpha = 0.7, size = 1.5) +
  geom_abline(intercept = 0, slope = 1, color = "black", linetype = "dashed")+
  geom_smooth(method = "lm", se = FALSE, color = "red", size = 1)+
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#f9f9f9", color = NA),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank()
  ) +
  labs(
    title = "Random Split Regression- Best Subset",
    x = "Observed",
    y = "Predicted"
  )+
  annotate("text",
           x = min(df_best$Observed) + 0.5,
           y = max(df_best$Predicted) - 0.5,
           label = paste("MSE =", round(mse_best, 3), "\nR² =", round(r2_best, 3)),
           hjust = 0, size = 4, color = "brown")

# Lasso Plot
ggplot(df_lasso, aes(x = Observed, y = Predicted)) +
  geom_point(color = "#1e8449", alpha = 0.7, size = 1.5) +
  geom_abline(slope = 1, intercept = 0, color = "red", linewidth = 1) +
  geom_abline(intercept = 0, slope = 1, color = "black", linetype = "dashed")+
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#f9f9f9", color = NA),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank()
  ) +
  labs(
    title = "Random Split Regression- Lasso",
    x = "Observed",
    y = "Predicted") + 
  annotate("text",
           x = min(df_lasso$Observed) + 0.5,
           y = max(df_lasso$Predicted) - 0.5,
           label = paste("MSE =", round(mse_lasso, 3), "\nR² =", round(r2_lasso, 3)),
           hjust = 0, size = 4, color = "brown")



# ---------------------------
# Task (f) Year-based split
# ---------------------------

train_year <- DATA[DATA$year <= 56, ]
test_year <- DATA[DATA$year > 56, ]

# Best subset
best_sub_year <- regsubsets(yield ~ . -loc -year, data = train_year, nvmax = 23)
best_sum_year <- summary(best_sub_year)
best_model_year <- which.min(best_sum_year$bic)
best_vars_year <- names(best_sum_year$which[best_model_year, ])[best_sum_year$which[best_model_year, ]]
print(best_vars_year <- best_vars_year[best_vars_year != "(Intercept)"])

fmla_year <- as.formula(paste("yield ~", paste(best_vars_year, collapse = "+")))
lm_best_year <- lm(fmla_year, data = train_year)
pred_best_subset_year <- predict(lm_best_year, newdata = test_year)

# Lasso
x_train_y <- model.matrix(yield ~ . -loc -year, train_year)[, -1]
y_train_y <- train_year$yield
x_test_y <- model.matrix(yield ~ . -loc -year, test_year)[, -1]
y_test_y <- test_year$yield

cv_lasso_y <- cv.glmnet(x_train_y, y_train_y, alpha = 1, nfolds = 7)
lambda_y <- cv_lasso_y$lambda.min
lasso_fit_y <- glmnet(x_train_y, y_train_y, alpha = 1, lambda = lambda_y)
pred_lasso_y <- predict(lasso_fit_y, newx = x_test_y)

mse_best_y <- mean((y_test_y - pred_best_subset_year)^2)
r2_best_y <- cor(y_test_y, pred_best_subset_year)^2
mse_lasso_y <- mean((y_test_y - pred_lasso_y)^2)
r2_lasso_y <- cor(y_test_y, pred_lasso_y)^2

df_best_y <- data.frame(
  observed = y_test_y,
  predicted = pred_best_subset_year
)

df_lasso_y <- data.frame(
  observed = y_test_y,
  predicted = as.numeric(pred_lasso_y)
)
# Best Subset plot
ggplot(df_best_y, aes(x = observed, y = predicted)) +
  geom_point(color = "#0079c1", alpha = 0.6, size = 2) +
  geom_abline(intercept = 0, slope = 1, color = "black", linetype = "dashed") +
  geom_smooth(method = "lm", color = "red", se = FALSE, linewidth=1) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#f9f9f9", color = NA),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank()
  )+
  labs(title = "Year based Split- Best Subset",
       x = "Observed",
       y = "Predicted") +
  annotate("text",
           x = min(df_best_y$observed) + 0.5,
           y = max(df_best_y$predicted) - 0.5,
           label = paste("MSE =", round(mse_best_y, 3), "\nR² =", round(r2_best_y, 3)),
           hjust = 0, size = 4, color = "brown")

#Lasso Plot
ggplot(df_lasso_y, aes(x = observed, y = predicted)) +
  geom_point(color = "#1e8449", alpha = 0.6, size = 2) +
  geom_abline(intercept = 0, slope = 1, color = "black", linetype = "dashed") +
  geom_smooth(method = "lm", color = "red", se = FALSE, linewidth=1) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#f9f9f9", color = NA),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank()
  )+
  labs(title = "Year Based Split - Lasso ",
       x = "Observed",
       y = "Predicted") +
  annotate("text",
           x = min(df_lasso_y$observed) + 0.5,
           y = max(df_lasso_y$predicted) - 0.5,
           label = paste("MSE =", round(mse_lasso_y, 3), "\nR² =", round(r2_lasso_y, 3)),
           hjust = 0, size = 4, color = "brown")

# ---------------------------
# Task (g) Lasso with folds by year groups
# ---------------------------

foldid <- rep(1:7, each = 8, length.out = nrow(train_year))
cv_lasso_folds <- cv.glmnet(x_train_y, y_train_y, alpha = 1, foldid = foldid)
lambda_folds <- cv_lasso_folds$lambda.min
lasso_fit_folds <- glmnet(x_train_y, y_train_y, alpha = 1, lambda = lambda_folds)
pred_lasso_folds <- predict(lasso_fit_folds, newx = x_test_y)

print(mse_lasso_folds <- mean((y_test_y - pred_lasso_folds)^2))
print(r2_lasso_folds <- cor(y_test_y, pred_lasso_folds)^2)

df_lasso_folds <- data.frame(
  Observed = y_test_y,
  Predicted = as.numeric(pred_lasso_folds)
)

ggplot(df_lasso_folds, aes(x = Observed, y = Predicted)) +
  geom_point(color = "#1e8449", alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", color = "red", se = FALSE, linewidth=1) +
  geom_abline(intercept = 0, slope = 1, color = "black", linetype = "dashed")+
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#f9f9f9", color = NA),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank()
  ) +
  labs(
    title = "Prescribed Folds - Lasso",
    x = "Observed Yields",
    y = "Predicted Yields"
  ) +
  annotate("text",
           x = min(df_lasso_folds$Observed),
           y = max(df_lasso_folds$Predicted) * 0.95,
           label = paste("MSE:", round(mse_lasso_folds, 2),
                         "\nR²:", round(r2_lasso_folds, 2)),
           hjust = 0, color = "brown", size = 4)


