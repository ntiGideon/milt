devtools::load_all()

# creating a series
ap = milt_series(AirPassengers)
print(ap)
help("milt")
help("AirPassengers")
ap2 = milt_series(AirPassengers, frequency = 12, start = c(1949,1))
print(ap2)
# create a series from a numeric vector
x = milt_series(
  rnorm(60, mean = 100, sd = 10),
  frequency = 12,
  start = c(2018, 1)
)
print(x)
# create a series from a dataframe or tibble
df = data.frame(
  date = seq(as.Date("2020-01-01"), by="month", length.out=36),
  sales = cumsum(rnorm(36, 5, 2)) + 100
)
s_df = milt_series(df, time_col = "date", value_cols = "sales", frequency = 12)
print(s_df)
View(df)

devtools::test(filter = "backend-tft")
# Inspecting a Series
ap = milt_series(AirPassengers)
ap$n_timesteps()# get number of observations
ap$values() # get values
ap$times() # get times
ap$start_time()
ap$n_series()
ap$n_components()
ap$is_univariate()
ap$is_multivariate()
ap$has_gaps()
ap$freq()
ap$end_time()
# convert as a tibble
tibble::as_tibble(ap) |> head()


# Subsetting and Slicing
milt_head(ap, 7)
# extract a date window
milt_window(
  ap,
  start = as.Date("1955-01-01"),
  end = as.Date("1957-03-06")
)
# Operator slicing
ap[1:12]

# Train/Test SPlit (80% train, 20%)
split = milt_split(ap, ratio = 0.8)
cat("Train::", split$train$n_timesteps(), "observations\n")
cat("Test:", split$test$n_timesteps(), "observations\n")

# Concatenation and Resampling
s1 = ap[1:60]
s2 = ap[61:144]
recombined = milt_concat(s1,s2)
recombined$n_timesteps()
# resample from monthly to quarterly
ap_q = milt_resample(ap, period = "quarterly", agg_fn = sum)
print(ap_q)

# Handling missing values
vals = ap$values()
vals[c(10,11,12)] = NA
s_na = milt_series(vals, frequency = 12, start = c(1949,1))
# fill using linear interpolation
s_filled = milt_fill_gaps(s_na, method = "linear")
print((s_filled))


# visualizing a series
plot(ap)


# Exploratory Data Analysis
milt_eda(ap)
eda_results$seasonality()

# ACF PACF plots
milt_plot_acf(ap, lag.max = 36L)
milt_plot_decomp(ap)

# diagnosis
milt_diagnose(ap)
# modelling
print(list_milt_models())

# prophet
prophet_fct <- milt_model("prophet") |>
  milt_fit(ap) |>
  milt_forecast(horizon = 24)

plot(prophet_fct)


# Theta method
theta = milt_model("theta") |>
  milt_fit(ap) |>
  milt_forecast(horizon = 25)
print(theta)
plot(theta)

# TBATS
tbats_fct <- milt_model("tbats") |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)
print(tbats_fct)
plot(tbats_fct)


# Croston (Intermittent Demand)
# Simulate intermittent demand
demand <- c(0,0,3,0,0,0,2,0,5,0,0,1,0,0,0,4,0,0,2,0,0,0,1,0,3,0,0,0,2,0,0,1,0,0,5,0)
demand_series <- milt_series(demand, frequency = 12, start = c(2020, 1))

croston_fct <- milt_model("croston") |>
  milt_fit(demand_series) |>
  milt_forecast(horizon = 12)

print(croston_fct)
plot(croston_fct)

# Naive Baseline
naive_fct <- milt_model("naive") |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

print(naive_fct)
plot(naive_fct)


# Machine Learning models
xgb_fct <- milt_model("xgboost", lags = 1:24) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

plot(xgb_fct)

lgb_fct <- milt_model("lightgbm", lags = 1:24) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

plot(lgb_fct)

# install other backends
milt_install_backends("extras")
milt_install_backends()
install.packages(c("CausalImpact"))


xgb_fct <- milt_model("xgboost", lags = 1:24) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

plot(xgb_fct)


rf_fct <- milt_model("random_forest", lags = 1:12) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

plot(rf_fct)

en_fct <- milt_model("elastic_net", lags = 1:12) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

plot(en_fct)

svm_fct <- milt_model("svm", lags = 1:12) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

plot(svm_fct)

knn_fct <- milt_model("knn", lags = 1:12) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

plot(knn_fct)


#| eval: false
# N-BEATS
nbeats_fct <- milt_model("nbeats", input_chunk_length = 24L, output_chunk_length = 12L) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)
plot(nbeats_fct)
# N-HiTS
nhits_fct <- milt_model("nhits", input_chunk_length = 24L, output_chunk_length = 12L) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

# Temporal Convolutional Network (TCN)
tcn_fct <- milt_model("tcn", input_chunk_length = 24L, output_chunk_length = 12L) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

# Temporal Fusion Transformer (TFT)
tft_fct <- milt_model("tft", input_chunk_length = 24L, output_chunk_length = 12L) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)

# PatchTST
patch_fct <- milt_model("patch_tst", input_chunk_length = 24L, output_chunk_length = 12L) |>
  milt_fit(ap) |>
  milt_forecast(horizon = 12)
plot(patch_fct)
