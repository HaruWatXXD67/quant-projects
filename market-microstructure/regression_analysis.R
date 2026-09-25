# Load dataset
df <- read.csv("micro.csv")
n <- nrow(df)

# Define the Variables
Spread <- abs(df$Price-df$Priceop)
SSpread <- df$Trade * Spread
SVolume <- df$Trade * df$Volume
SDepth <- df$Trade * df$Depth
dPrice <- diff(df$Price)
dTrade <- diff(df$Trade)
dSSpread <- diff(SSpread)
dSVolume <- diff(SVolume)
dSDepth <- diff(SDepth)
dTime <- diff(df$Time)
SdTime <- df$Trade[-1]*dTime
dSdTime <- diff(SdTime)
print(c(length(dPrice), length(dTrade), length(dSSpread), length(dSVolume), length(dSdTime)))

# Align the vectors by removing the first row
dPrice <- dPrice[-1]
dTrade <- dTrade[-1]
dSSpread <- dSSpread[-1]
dSVolume <- dSVolume[-1]
dSDepth <- dSDepth[-1]
dSdTime <- dSdTime
print(c(length(dPrice), length(dTrade), length(dSSpread), length(dSVolume), length(dSdTime)))
aligned_df <- data.frame(dPrice, dTrade, dSSpread, dSVolume, dSDepth, dSdTime)
head(aligned_df)

# Linear Regression: ∆Price = θ0 + θ1∆Trade + θ2∆SSpread + θ3∆(S∆Time) + θ4∆SVolume +θ5∆SDepth.
model_1 <- lm(dPrice ~ dTrade + dSSpread + dSdTime + dSVolume + dSDepth, 
            data = aligned_df)
summary(model_1)

# ∆Price = θ0 + θ1V, V ∈ {∆Trade, ∆SSpread, ∆(S∆Time), ∆SVolume, ∆SDepth}
model_2_dTrade <- lm(dPrice ~ dTrade, data = aligned_df)
summary(model_2_dTrade)
model_2_dSSpread <- lm(dPrice ~ dSSpread, data = aligned_df)
summary(model_2_dSSpread)
model_2_dSdTime <- lm(dPrice ~ dSdTime, data = aligned_df)
summary(model_2_dSdTime)
model_2_dSVolume <- lm(dPrice ~ dSVolume, data = aligned_df)
summary(model_2_dSVolume)
model_2_dSDepth <- lm(dPrice ~ dSDepth, data = aligned_df)
summary(model_2_dSDepth)

# ∆Price = θ0 + θ1∆Trade + θ2∆SSpread + θ3∆(S∆Time) + θ4∆SVolume +θ5∆SDepth + θ6Time.
Time <- df$Time
Time <- Time[-1]
length(Time)
aligned_df_2 <- data.frame(dPrice, dTrade, dSSpread, dSVolume, dSDepth, dSdTime, Time)
head(aligned_df)
model_3 <- lm(dPrice ~ dTrade + dSSpread + dSdTime + dSVolume + dSDepth + Time, aligned_df)
summary(model_3)

# Hypothesis test to compare model_1 and model_4
anova_comparison <- anova(model_1, model_3)
print(anova_comparison)

# Hypothesis test for ∆Price = θ0 + θ1∆Trade + θ2∆SSpread + θ3∆(S∆Time) + θ4∆SVolume + θ5∆SDepth + θ6(∆SSpread)^2 vs. ∆Price = θ0 + θ1∆Trade + θ2∆SSpread + θ3∆(S∆Time) + θ4∆SVolume +θ5∆SDepth + θ6(∆SSpread)^2 + θ7(∆SSpread)^3
dSSpread_2 <- dSSpread^2
dSSpread_3 <- dSSpread^3
aligned_df_3 <- data.frame(dPrice, dTrade, dSSpread, dSVolume, dSDepth, dSdTime, dSSpread_2, dSSpread_3)
model_5a <- lm(dPrice ~ dTrade + dSSpread + dSdTime + dSVolume + dSDepth + dSSpread_2, data = aligned_df_3)
summary(model_5a)
model_5b <- lm(dPrice ~ dTrade + dSSpread + dSdTime + dSVolume + dSDepth + dSSpread_2 + dSSpread_3, data = aligned_df_3)
summary(model_5b)

# Prediction of ∆Price based on model_1 when ∆Trade = 2, ∆SSpread = 0, ∆(S∆Time) = 0.1, ∆SVolume = 100, ∆SDepth = 100 + CI for "prediction of a future value" and "prediction of the mean response".
observation <- data.frame(dTrade    = 2, dSSpread  = 0, dSdTime = 0.1, dSVolume  = 100, dSDepth   = 100)
ci_mean <- predict(model_1, newdata = observation, interval = "confidence", level = 0.95)
print(ci_mean)
ci_future <- predict(model_1, newdata = observation, interval = "prediction", level=0.95)
print(ci_future)

# Test for constant variance of error
# Primary Diagnostic: Residuals vs. Fitted Values
plot(fitted(model_1), residuals(model_1), 
     xlab = "Fitted", 
     ylab = "Residuals",
     main = "Residuals vs. Fitted Plot")
abline(h = 0, col = "red", lty = 2) 

# Enhanced Diagnostic: Square Root of Absolute Residuals vs. Fitted Values
plot(fitted(model_1), sqrt(abs(residuals(model_1))), 
     xlab = "Fitted", 
     ylab = expression(sqrt(paste("|", hat(epsilon), "|"))),
     main = "Scale-Location Plot")

# Auxiliary Trend Test for Non-Constant Variance
variance_test_model <- lm(sqrt(abs(residuals(model_1))) ~ fitted(model_1))
summary(variance_test_model)

# Normality condition of error terms
# Plot A: Histogram of Residuals vs. Normal Curve
h <- hist(residuals(model_1), breaks = 60, col = "lightgray", prob = TRUE,
          main = "Histogram of Residuals",
          xlab = "Residual Value")
x_vals <- seq(min(resids), max(resids), length = 500)
y_vals <- dnorm(x_vals, mean = mean(resids), sd = sd(resids))
lines(x_vals, y_vals, col = "red", lwd = 2)

# Plot B: Normal Q-Q Plot
qqnorm(resids, main = "Normal Q-Q Plot", col = rgb(0, 0, 1, alpha = 0.2), pch = 16)
qqline(resids, col = "red", lwd = 2)

#Shapiro test
set.seed(123)
shapiro.test(sample(residuals(model_1), 5000))

# Correlation of error terms
# Residuals vs. Time Index (Sequential Line Plot)
plot(residuals(model_1), type = "l", xlab = "Time Index", ylab = "Residuals",
     main = "Residuals over Time Index")
abline(h = 0, col = "red", lty = 2)

# Successive Pairs Lag Plot
n <- length(residuals(model_1))
plot(head(residuals(model_1), n - 1), tail(residuals(model_1), n - 1),
     xlab = expression(hat(epsilon)[i]), ylab = expression(hat(epsilon)[i+1]),
     main = "Successive Pairs of Residuals")
abline(h = 0, v = 0, col = "grey")

# Auxiliary Numeric Verification: Direct Modeling of Successive Residuals
serial_model <- lm(tail(residuals(model_1), n - 1) ~ head(residuals(model_1), n - 1) - 1)
summary(serial_model)

# Durbin-Watson Test
dwtest(model_1)
