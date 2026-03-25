# MiltSeries API Reference

`MiltSeries` is the foundational data structure in milt. Every model,
detector, pipeline, and analysis function expects a `MiltSeries` as
input and returns results that reference one. This guide documents every
way to create, inspect, slice, transform, and combine `MiltSeries`
objects.

------------------------------------------------------------------------

## 1. Creating a MiltSeries

### `milt_series()`

The primary constructor. Accepts several input formats.

``` r
milt_series(
  data,
  time_col   = NULL,
  value_cols = NULL,
  group_col  = NULL,
  frequency  = NULL,
  metadata   = list()
)
```

| Argument     | Type                 | Default                                      | Description                                                                                                                                                                                                         |
|--------------|----------------------|----------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `data`       | varies               | —                                            | Input data. Accepts a `ts`, `zoo`, `xts`, `tsibble`, `tibble`, `data.frame`, or numeric vector.                                                                                                                     |
| `time_col`   | character            | auto                                         | Name of the column holding timestamps. Auto-detected when `data` is a `tibble` or `data.frame`.                                                                                                                     |
| `value_cols` | character            | auto                                         | Name(s) of the numeric value column(s). Auto-detected when not supplied.                                                                                                                                            |
| `group_col`  | character or NULL    | `NULL`                                       | Column that identifies series in a multi-series (panel) dataset.                                                                                                                                                    |
| `frequency`  | character or numeric | auto                                         | Sampling frequency. Accepts `"daily"`, `"weekly"`, `"monthly"`, `"quarterly"`, `"annual"`, `"hourly"`, `"minutely"`, or a positive integer (observations per year). Auto-detected from the time column when `NULL`. |
| `metadata`   | named list           | [`list()`](https://rdrr.io/r/base/list.html) | Arbitrary metadata attached to the series (e.g. `list(source = "sensor_A")`). Retrieved with `$metadata`.                                                                                                           |

**From a base-R `ts` object (most common):**

``` r
library(milt)

ap <- milt_series(AirPassengers)
print(ap)
```

**From a `tibble` with explicit column names:**

``` r
library(tibble)

df <- tibble(
  date  = seq(as.Date("2020-01-01"), by = "month", length.out = 36),
  sales = cumsum(rnorm(36, mean = 100))
)

s <- milt_series(df, time_col = "date", value_cols = "sales", frequency = "monthly")
print(s)
```

**Multi-series (panel) from a long-format tibble:**

``` r
panel <- tibble(
  date   = rep(seq(as.Date("2022-01-01"), by = "day", length.out = 90), 3),
  series = rep(c("A", "B", "C"), each = 90),
  value  = rnorm(270)
)

ms <- milt_series(panel,
                  time_col  = "date",
                  value_cols = "value",
                  group_col = "series")
print(ms)
```

------------------------------------------------------------------------

## 2. Inspecting a Series

Once created, `MiltSeries` objects expose accessors for all metadata.

### Print and Summary

``` r
ap <- milt_series(AirPassengers)

print(ap)       # compact overview: n obs, frequency, range, value stats
summary(ap)     # detailed statistical summary
```

### Structural accessors

These return metadata without modifying the object:

``` r
ap$n_timesteps()      # number of time steps
ap$n_series()         # 1 for univariate, >1 for multi-series
ap$is_multi_series()  # TRUE/FALSE

ap$time_col()         # name of the time column
ap$value_cols()       # character vector of value column names
ap$group_col()        # name of the group column, or NULL

ap$freq()             # frequency label, e.g. "monthly"
ap$start_time()       # first timestamp
ap$end_time()         # last timestamp

ap$metadata           # named list of user-supplied metadata
```

### Data accessors

``` r
ap$data()             # returns the underlying tibble (all columns)
ap$values()           # numeric vector of the first value column
ap$times()            # vector of timestamps
```

### Conversion helpers

Convert a `MiltSeries` back to standard R formats:

``` r
milt_to_ts(ap)        # base-R ts object
milt_to_tibble(ap)    # tibble with time + value columns
milt_to_tsibble(ap)   # tsibble (requires tsibble package)
```

------------------------------------------------------------------------

## 3. Slicing and Subsetting

### Integer indexing

`[` with integer indices returns a new `MiltSeries`:

``` r
ap[1:12]        # first 12 observations
ap[-(1:12)]     # drop first year
```

### Head and tail

``` r
milt_head(ap, n = 12)   # first 12 rows
milt_tail(ap, n = 12)   # last 12 rows
```

### Date/time window

Extract observations within a time range (both endpoints inclusive):

``` r
milt_window(ap, start = "1951-01-01", end = "1955-12-01")
```

| Argument | Type              | Default | Description                                                                                                                                                              |
|----------|-------------------|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `series` | MiltSeries        | —       | Input series.                                                                                                                                                            |
| `start`  | date-like or NULL | `NULL`  | Start of the window. Accepts `Date`, `POSIXct`, or a character string parseable by [`lubridate::as_datetime()`](https://lubridate.tidyverse.org/reference/as_date.html). |
| `end`    | date-like or NULL | `NULL`  | End of the window. Same types as `start`.                                                                                                                                |

### Train/test split

``` r
# Split into 80% training, 20% test
splits <- milt_split(ap, prop = 0.8)
train  <- splits$train
test   <- splits$test

# Or split at a specific date
splits2 <- milt_split_at(ap, date = "1958-01-01")
```

[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md)
arguments:

| Argument | Type              | Default | Description                                             |
|----------|-------------------|---------|---------------------------------------------------------|
| `series` | MiltSeries        | —       | Input series.                                           |
| `prop`   | numeric in (0, 1) | `0.8`   | Proportion of observations to keep in the training set. |

[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md)
arguments:

| Argument | Type       | Default | Description                                                                                                       |
|----------|------------|---------|-------------------------------------------------------------------------------------------------------------------|
| `series` | MiltSeries | —       | Input series.                                                                                                     |
| `date`   | date-like  | —       | Cut-off date. All observations strictly before this date go to `$train`; all from this date onward go to `$test`. |

------------------------------------------------------------------------

## 4. Combining Series

### Concatenate along the time axis

Concatenate two `MiltSeries` with the same structure end-to-end:

``` r
s1 <- milt_window(ap, end = "1954-12-01")
s2 <- milt_window(ap, start = "1955-01-01")

combined <- milt_concat(s1, s2)
```

The two series must share the same `value_cols` and `frequency`.

------------------------------------------------------------------------

## 5. Resampling and Gap Filling

### Resampling

Change the sampling frequency of a series:

``` r
# Aggregate daily → weekly (mean)
daily_s <- milt_series(
  tibble(
    date  = seq(as.Date("2023-01-01"), by = "day", length.out = 365),
    value = rnorm(365)
  ),
  time_col   = "date",
  value_cols = "value",
  frequency  = "daily"
)

weekly_s <- milt_resample(daily_s, frequency = "weekly", fun = mean)
```

[`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md)
arguments:

| Argument    | Type       | Default | Description                                                                      |
|-------------|------------|---------|----------------------------------------------------------------------------------|
| `series`    | MiltSeries | —       | Input series.                                                                    |
| `frequency` | character  | —       | Target frequency: `"daily"`, `"weekly"`, `"monthly"`, `"quarterly"`, `"annual"`. |
| `fun`       | function   | `mean`  | Aggregation function applied to each bin (e.g. `sum`, `max`, `min`).             |

### Gap filling

Detect and fill irregular or missing time steps:

``` r
# Insert NAs at missing time steps, then linearly interpolate
filled <- milt_fill_gaps(s, method = "linear")
```

[`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md)
arguments:

| Argument | Type       | Default    | Description                                                                                                                                                    |
|----------|------------|------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `series` | MiltSeries | —          | Input series.                                                                                                                                                  |
| `method` | character  | `"linear"` | Fill method: `"linear"` (linear interpolation), `"spline"` (spline interpolation), `"na"` (insert `NA` only), `"last"` (forward fill), `"mean"` (global mean). |

------------------------------------------------------------------------

## 6. Covariates

milt supports three kinds of covariates that can be attached to a
series:

- **Static covariates** — scalar features that apply to the whole series
  (e.g. store size, country code).
- **Past covariates** — time-varying features known only up to the
  forecast origin (e.g. lagged external variables).
- **Future covariates** — time-varying features known over the entire
  forecast horizon (e.g. calendar events, planned promotions).

``` r
library(tibble)

ap <- milt_series(AirPassengers)

# Static: one row per series
static <- tibble(region = "North America")

# Future: calendar flags over the forecast horizon
future_dates <- seq(
  from       = as.Date("1960-02-01"),
  by         = "month",
  length.out = 12
)
future_covs <- tibble(
  date      = future_dates,
  is_summer = lubridate::month(future_dates) %in% 6:8
)

ap <- milt_add_covariates(ap,
                          static = static,
                          future = future_covs)

# Retrieve attached covariates
milt_get_covariates(ap, type = "static")
milt_get_covariates(ap, type = "future")
```

[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md)
arguments:

| Argument | Type           | Default | Description                                                                         |
|----------|----------------|---------|-------------------------------------------------------------------------------------|
| `series` | MiltSeries     | —       | Target series to attach covariates to.                                              |
| `static` | tibble or NULL | `NULL`  | One-row tibble of scalar features.                                                  |
| `past`   | tibble or NULL | `NULL`  | Tibble with a time column matching the series’ time column plus feature columns.    |
| `future` | tibble or NULL | `NULL`  | Tibble with a time column extending into the forecast horizon plus feature columns. |

------------------------------------------------------------------------

## 7. Multi-Series Workflow

When `group_col` is set, most milt functions automatically apply
per-group.

``` r
# Build a 3-series dataset
panel <- tibble(
  month  = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 60), 3),
  region = rep(c("East", "West", "Central"), each = 60),
  sales  = c(
    cumsum(rnorm(60, 5)),
    cumsum(rnorm(60, 3)),
    cumsum(rnorm(60, 4))
  )
)

ms <- milt_series(panel,
                  time_col   = "date",
                  value_cols = "sales",
                  group_col  = "region",
                  frequency  = "monthly")

ms$n_series()        # 3
ms$is_multi_series() # TRUE

# Fit and forecast all series at once
fc <- milt_model("ets") |>
  milt_fit(ms) |>
  milt_forecast(h = 12)

print(fc)
```

------------------------------------------------------------------------

## 8. Frequency Reference

The table below lists all frequency labels milt understands:

| `frequency` string      | Observations per year | Typical [`ts()`](https://rdrr.io/r/stats/ts.html) period |
|-------------------------|-----------------------|----------------------------------------------------------|
| `"minutely"`            | 525,600               | —                                                        |
| `"hourly"`              | 8,760                 | 8760                                                     |
| `"daily"`               | 365                   | 365                                                      |
| `"weekly"`              | 52                    | 52                                                       |
| `"monthly"`             | 12                    | 12                                                       |
| `"quarterly"`           | 4                     | 4                                                        |
| `"annual"` / `"yearly"` | 1                     | 1                                                        |

You may also pass a bare positive integer (e.g. `frequency = 7` for
daily data with a weekly seasonal cycle).

------------------------------------------------------------------------

## 9. Pipe-Friendly Design

All `milt_*` functions accept the series as their **first argument**,
making them fully compatible with the native pipe `|>`:

``` r
milt_series(AirPassengers) |>
  milt_window(start = "1950-01-01") |>
  milt_resample(frequency = "quarterly", fun = sum) |>
  milt_split(prop = 0.8) |>
  (\(sp) milt_model("auto_arima") |> milt_fit(sp$train) |> milt_forecast(h = 8))()
```

------------------------------------------------------------------------

## See Also

- [`vignette("milt-forecasting")`](https://ntiGideon.github.io/milt/articles/milt-forecasting.md)
  — fitting and forecasting models
- [`vignette("milt-eda-diagnostics")`](https://ntiGideon.github.io/milt/articles/milt-eda-diagnostics.md)
  — exploratory analysis of a series
- [`vignette("milt-multi-series")`](https://ntiGideon.github.io/milt/articles/milt-multi-series.md)
  — multi-series and hierarchical workflows
- [`vignette("milt-pipelines")`](https://ntiGideon.github.io/milt/articles/milt-pipelines.md)
  — feature engineering pipelines
