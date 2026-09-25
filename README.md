# Quantitaive Projects
Selected coursework and independent projects in applied statistics and quantitative modelling in Bayesian inference, regression analysis, etc.


## Bayesian Statistics
- bayesian_beta_binomial_conjugate_analysis.ipynb — Beta-Binomial conjugate analysis: likelihood and log-likelihood visualization, Beta
  prior specification, and closed-form posterior mean, variance, median, and mode, derived both analytically and via numerical optimization.
- bayesian_disease_mortality_estimation.ipynb — Bayesian estimation of district-level disease mortality rates using a Beta
  Binomial model, with 95% credible intervals constructed for each district from real epidemiological count data.
- bayesian_probit_logit_mortgage_denial.ipynb — Bayesian probit and logit regression implemented from first principles via Gibbs sampling, using latent truncated-normal and Pólya-Gamma data augmentation respectively, applied to real mortgage-denial data with custom functions for posterior summary statistics and MCMC convergence diagnostics.
- bayesian_mc_convergence.ipynb — Empirical verification of the Law of Large Numbers: simulating up to one million draws from a standard normal distribution to demonstrate convergence of the sample mean, sample median, and an empirical probability estimate to their theoretical values.
- bayesian_gibbs_truncated_multivariate_normal.ipynb — Gibbs sampling from a five-dimensional truncated multivariate normal distribution with AR(1)-structured correlation between components, comparing the resulting marginal distributions under two different mean vectors.


## Causal Inference
- causal-methods-comparison.ipynb - A comparative implementation of core causal inference techniques, covering treatment effect estimation, panel/time-series methods, and instrumental variables identification. Methods covered include: 
Methods
- **ATE identification** — derivation under randomisation; conditions for selection bias in observational data
- **CATE** — T-learner vs. Causal Forest, with calibration and monotonicity checks
- **SCM vs. CausalImpact** — synthetic control vs. Bayesian structural time-series, applied to policy evaluation
- **DID** — derived from first principles; equivalence to two-period fixed-effects regression
- **IV / LATE** — identification under exclusion restriction and monotonicity
- **ASCM** — bias-corrected SCM via ridge-regression outcome model

## Regression Analysis
- housing-regression/housing_price_quantile_regression.R — OLS and quantile regression on housing sale prices, comparing how the relationship between living area and price varies across the price distribution, with results interpreted as evidence of divergent pricing behaviour between higher- and lower-income buyers. Employed regularisation techniques to extend the model to the full feature set, using LASSO to select the most predictive variables and cross-validation with pinball loss to tune the penalty strength across quantiles.
- market-microstructure/regression_analysis.R — Regression analysis of price changes against trade volume, bid-ask spread, and market depth using high-frequency trading data, with nested model comparison via ANOVA to assess the joint significance of order-book variables.


## Numerical methods and Algorithms (used throughout my computational courses)
- optimization/gradient_descent_and_newtons_method.ipynb — minimizing non-convex functions via gradient descent and Newton's method, with convergence visualized against the function surface.
- simulation/monte_carlo_and_fft.ipynb — Monte Carlo estimation of π and a definite integral via random sampling, and frequency-domain decomposition of a multi-component signal via FFT.
- graph-algorithms/dijkstra_and_tree_traversal.ipynb — Dijkstra's shortest-path algorithm implemented from scratch with full path reconstruction, alongside recursive depth-first and iterative breadth-first tree traversal.
