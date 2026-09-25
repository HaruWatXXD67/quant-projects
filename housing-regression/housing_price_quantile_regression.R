library(quantreg)
library(ggplot2)
library(dplyr)
 
set.seed(42)
 
# OLS and Quantile Regression (raw features, house0.csv)
df <- read.csv("house0.csv")
 
# OLS regression: SalePrice ~ GrLivArea
ols_model <- lm(SalePrice ~ GrLivArea, data = df)
summary(ols_model)
 
ggplot(data = df, aes(x = GrLivArea, y = SalePrice)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE, color = "red", size = 1.2) +
  labs(
    title = "OLS Regression: House Price vs Living Area",
    x = "Living Area (sq ft)",
    y = "Sale Price"
  ) +
  theme_minimal()
 
# Quantile regression across multiple quantiles
df_qr <- df[, c("GrLivArea", "SalePrice")]
df_qr <- na.omit(df_qr)
 
taus <- c(0.1, 0.25, 0.5, 0.75, 0.9)
qr_models <- lapply(taus, function(tau) {
  rq(SalePrice ~ GrLivArea, data = df_qr, tau = tau)
})
 
x_vals <- seq(min(df_qr$GrLivArea), max(df_qr$GrLivArea), length.out = 100)
pred_df <- data.frame(GrLivArea = x_vals)
 
# OLS predictions, so the OLS line actually has data to plot
pred_df$OLS <- predict(ols_model, newdata = pred_df)
 
for (i in seq_along(taus)) {
  pred_df[[paste0("tau_", taus[i])]] <- predict(qr_models[[i]], newdata = pred_df)
}
 
ggplot(df_qr, aes(x = GrLivArea, y = SalePrice)) +
  geom_point(alpha = 0.3) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = OLS), color = "green", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.1), color = "red", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.25), color = "orange", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.5), color = "gold", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.75), color = "blue", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.9), color = "purple", size = 1) +
  labs(
    title = "OLS and Quantile Regression Lines",
    x = "Above Ground Living Area (sq ft)",
    y = "Sale Price"
  ) +
  theme_minimal()
 
slopes <- sapply(qr_models, function(model) coef(model)["GrLivArea"])
results <- data.frame(Quantile = taus, Slope = round(slopes, 4))
print(results)
 
# LASSO Quantile Regression (full processed features, house1.csv)
df_full <- read.csv("house1.csv")
 
n <- nrow(df_full)
train_idx <- sample(seq_len(n), size = floor(0.8 * n))
 
train_df <- df_full[train_idx, ]
test_df  <- df_full[-train_idx, ]
 
y_train <- train_df$SalePrice
x_train <- as.matrix(train_df %>% select(-SalePrice))
 
y_test <- test_df$SalePrice
x_test <- as.matrix(test_df %>% select(-SalePrice))
 
fit_lasso_quantile <- function(x, y, tau, lambda) {
  rq.fit.lasso(x, y, tau = tau, lambda = lambda)
}
 
# Coefficient paths across a range of lambda values (median quantile)
lambda_grid <- c(0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5, 10)
 
coef_path <- lapply(lambda_grid, function(lam) {
  fit <- fit_lasso_quantile(x_train, y_train, tau = 0.5, lambda = lam)
  data.frame(
    lambda      = lam,
    feature     = colnames(x_train),
    coefficient = fit$coefficients[-1]  # drop intercept
  )
})
coef_path_df <- do.call(rbind, coef_path)
 
ggplot(coef_path_df, aes(x = log10(lambda), y = coefficient, group = feature)) +
  geom_line(alpha = 0.3) +
  labs(
    title = "LASSO Quantile Regression: Coefficient Paths (tau = 0.5)",
    x = expression(log[10](lambda)),
    y = "Coefficient Value"
  ) +
  theme_minimal()
 
# Cross-validation to select lambda per quantile (pinball loss)
k_folds <- 5
folds <- sample(rep(1:k_folds, length.out = nrow(x_train)))
 
pinball_loss <- function(resid, tau) {
  mean(pmax(tau * resid, (tau - 1) * resid))
}
 
cv_error <- function(tau, lambda) {
  fold_errors <- numeric(k_folds)
  for (k in 1:k_folds) {
    tr_idx <- which(folds != k)
    val_idx <- which(folds == k)
 
    fit <- fit_lasso_quantile(x_train[tr_idx, ], y_train[tr_idx], tau = tau, lambda = lambda)
    preds <- cbind(1, x_train[val_idx, ]) %*% fit$coefficients
    resid <- y_train[val_idx] - preds
 
    fold_errors[k] <- pinball_loss(resid, tau)
  }
  mean(fold_errors)
}
 
cv_grid <- expand.grid(tau = taus, lambda = lambda_grid)
cv_grid$cv_loss <- mapply(cv_error, cv_grid$tau, cv_grid$lambda)
 
best_lambda <- cv_grid %>%
  group_by(tau) %>%
  slice_min(cv_loss, n = 1) %>%
  ungroup()
 
print(best_lambda)
 
ggplot(cv_grid, aes(x = log10(lambda), y = cv_loss, color = factor(tau))) +
  geom_line() +
  geom_point(
    data = best_lambda,
    aes(x = log10(lambda), y = cv_loss),
    color = "black", size = 3
  ) +
  labs(
    title = "Cross-Validated Pinball Loss by Lambda and Quantile",
    x = expression(log[10](lambda)),
    y = "CV Pinball Loss",
    color = "Quantile"
  ) +
  theme_minimal()
 
# Final evaluation on held-out test set, using CV-selected lambda
evaluate_test <- function(tau, lambda) {
  fit <- fit_lasso_quantile(x_train, y_train, tau = tau, lambda = lambda)
  preds <- cbind(1, x_test) %*% fit$coefficients
 
  data.frame(
    tau  = tau,
    mae  = mean(abs(y_test - preds)),
    rmse = sqrt(mean((y_test - preds)^2))
  )
}
 
test_performance <- do.call(rbind, Map(evaluate_test, best_lambda$tau, best_lambda$lambda))
print(test_performance)
