library(quantreg)
library(ggplot2)
library(dplyr)
library(tidyr)
library(caret)

df <- read.csv("house0.csv")
head(df)
summary(df)

df1 <- read.csv("house1.csv")
head(df1)
summary(df1)

z_values <- c(-1, 1, 2, 3, 4)
probs <- c(1/4, 1/6, 1/12, 1/3, 1/6)
cdf <- cumsum(probs)
taus <- c(0.25, 0.5, 0.75)
quantile_function <- function(tau, z_values, cdf) {
  return(min(z_values[cdf >= tau]))
}

# Apply to each tau
quantiles <- sapply(taus, quantile_function, z_values=z_values, cdf=cdf)
names(quantiles) <- paste0("tau=", taus)

print(quantiles)
plot(z_values, cdf, type="s", col="blue", lwd=2,
     main="CDF of Z with Quantiles",
     xlab="Z", ylab="F_Z(z)", ylim=c(0,1))
points(quantiles, taus, col="red", pch=19)
text(quantiles, taus, labels=names(quantiles), pos=4, col="red")
abline(h=taus, col="gray", lty=2)
abline(v=quantiles, col="gray", lty=2)


names(df)
summary(df$GrLivArea)
summary(df$SalePrice)

# OLS Regression
ols_model <- lm(SalePrice ~ GrLivArea, data = df)
summary(ols_model)
ggplot(data = df, aes(x = GrLivArea, y = SalePrice)) +
  geom_point(alpha = 0.3) +  # actual data points
  geom_smooth(method = "lm", se = FALSE, color = "red", size = 1.2) +  # OLS line
  labs(title = "OLS Regression: House Price vs Living Area",
       x = "Living Area (sq ft)",
       y = "Log Sale Price") +
  theme_minimal()

# Keep only the columns we need
df <- df[, c("GrLivArea", "SalePrice")]
df <- na.omit(df)  # Remove any rows with missing values

# Fit quantile regression models
# Quantiles to estimate
taus <- c(0.1, 0.25, 0.5, 0.75, 0.9)

# Fit quantile regression models and store them
qr_models <- lapply(taus, function(tau) {
  rq(SalePrice ~ GrLivArea, data = df, tau = tau)
})

# Create a sequence of living area values for prediction
x_vals <- seq(min(df$GrLivArea), max(df$GrLivArea), length.out = 100)
pred_df <- data.frame(GrLivArea = x_vals)

# Predict fitted lines for each tau
predictions <- sapply(1:length(taus), function(i) {
  predict(qr_models[[i]], newdata = pred_df)
})

# Add predictions to pred_df
for (i in 1:length(taus)) {
  pred_df[[paste0("tau_", taus[i])]] <- predictions[, i]
}

# Plot all regression lines
ggplot(df, aes(x = GrLivArea, y = SalePrice)) +
  geom_point(alpha = 0.3) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = OLS), color = "green", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.1), color = "red", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.25), color = "orange", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.5), color = "yellow", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.75), color = "blue", size = 1) +
  geom_line(data = pred_df, aes(x = GrLivArea, y = tau_0.9), color = "purple", size = 1) +
  labs(title = "OLS and Quantile Regression Lines",
       x = "Above Ground Living Area (sq ft)",
       y = "Log Sale Price") +
  theme_minimal()

# slope coefficients for each model
slopes <- sapply(qr_models, function(model) {
  coef(model)["GrLivArea"]
})
results <- data.frame(Quantile = taus, Slope = round(slopes, 4))
print(results)
