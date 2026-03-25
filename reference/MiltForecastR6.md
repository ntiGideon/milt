# MiltForecast — results of milt_forecast()

Stores point forecasts, prediction intervals, and optional sample paths.
Produced by every model's `forecast()` method. Use
[`print()`](https://rdrr.io/r/base/print.html),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html), or
`as_tibble()` to inspect results.

## Methods

### Public methods

- [`MiltForecastR6$new()`](#method-MiltForecast-new)

- [`MiltForecastR6$point_forecast()`](#method-MiltForecast-point_forecast)

- [`MiltForecastR6$has_intervals()`](#method-MiltForecast-has_intervals)

- [`MiltForecastR6$has_samples()`](#method-MiltForecast-has_samples)

- [`MiltForecastR6$levels()`](#method-MiltForecast-levels)

- [`MiltForecastR6$horizon()`](#method-MiltForecast-horizon)

- [`MiltForecastR6$model_name()`](#method-MiltForecast-model_name)

- [`MiltForecastR6$as_tibble()`](#method-MiltForecast-as_tibble)

------------------------------------------------------------------------

### Method `new()`

Create a MiltForecast. Called by model backends.

#### Usage

    MiltForecastR6$new(
      point_forecast,
      lower = list(),
      upper = list(),
      samples = NULL,
      model_name = "unknown",
      horizon = nrow(point_forecast),
      training_end = NULL,
      training_series = NULL
    )

#### Arguments

- `point_forecast`:

  Tibble: must contain `time` and at least one value column.

- `lower`:

  Named list of tibbles (one per CI level, e.g. `"80"`, `"95"`). Each
  tibble must have `time` and `value` columns.

- `upper`:

  Same structure as `lower`.

- `samples`:

  Numeric matrix (`horizon` rows × `n_samples` cols) or `NULL`.

- `model_name`:

  Character scalar.

- `horizon`:

  Positive integer.

- `training_end`:

  Start of the forecast horizon (end of training).

- `training_series`:

  The `MiltSeries` used for training (for plotting history alongside
  forecasts). Optional.

------------------------------------------------------------------------

### Method `point_forecast()`

Return point forecasts as a tibble.

#### Usage

    MiltForecastR6$point_forecast()

------------------------------------------------------------------------

### Method `has_intervals()`

`TRUE` if prediction intervals are stored.

#### Usage

    MiltForecastR6$has_intervals()

------------------------------------------------------------------------

### Method `has_samples()`

`TRUE` if sample paths are stored.

#### Usage

    MiltForecastR6$has_samples()

------------------------------------------------------------------------

### Method [`levels()`](https://rdrr.io/r/base/levels.html)

Return confidence levels stored in the forecast.

#### Usage

    MiltForecastR6$levels()

------------------------------------------------------------------------

### Method `horizon()`

Return the forecast horizon.

#### Usage

    MiltForecastR6$horizon()

------------------------------------------------------------------------

### Method `model_name()`

Return the model name.

#### Usage

    MiltForecastR6$model_name()

------------------------------------------------------------------------

### Method `as_tibble()`

Convert to a wide tibble with all intervals.

#### Usage

    MiltForecastR6$as_tibble()
