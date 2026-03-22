devtools::load_all()
library(milt)
list_milt_models()

data = AirPassengers
tseries = milt_series(data, frequency = 12, start = c(1949, 1))

# inspect the series
print(tseries)
# diagnose the time series with recommendation
milt_diagnose(tseries)
# fit a model and forecast
fct = milt_model("stl") |>
    milt_fit(tseries) |>
    milt_forecast(horizon=24)

print(fct)
plot(fct)

# Evaluate accuracy
spl = milt_split(tseries, ratio = 0.8)
fct_cv = milt_model("ets") |>
    milt_fit(spl$train) |>
    milt_forecast(spl$test$n_timesteps())

milt_accuracy(spl$test$values(), fct_cv$as_tibble()$.mean)


# try with UKDeaths
data = UKDriverDeaths
tseries = milt_series(data, frequency = 12, start=c(1969, 1))
print(tseries)
milt_diagnose(tseries)

fit = milt_model("ets") |>
  milt_fit(tseries) |>
  milt_forecast(horizon = 12)
print(fit)
plot(fit)
fit
