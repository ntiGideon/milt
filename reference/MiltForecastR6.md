# MiltForecast — results of milt_forecast()

Stores point forecasts, prediction intervals, and optional sample paths.
Produced by every model's `forecast()` method. Use
[`print()`](https://rdrr.io/r/base/print.html),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html), or
`as_tibble()` to inspect results.

## Methods

### Public methods

- [`MiltForecast$new()`](#method-MiltForecast-initialize)

- [`MiltForecast$point_forecast()`](#method-MiltForecast-point_forecast)

- [`MiltForecast$has_intervals()`](#method-MiltForecast-has_intervals)

- [`MiltForecast$has_samples()`](#method-MiltForecast-has_samples)

- [`MiltForecast$levels()`](#method-MiltForecast-levels)

- [`MiltForecast$horizon()`](#method-MiltForecast-horizon)

- [`MiltForecast$model_name()`](#method-MiltForecast-model_name)

- [`MiltForecast$as_tibble()`](#method-MiltForecast-as_tibble)

------------------------------------------------------------------------

### `MiltForecast$new()`

Create a MiltForecast. Called by model backends.

#### Usage

    MiltForecast$new(
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

### `MiltForecast$point_forecast()`

Return point forecasts as a tibble.

#### Usage

    MiltForecast$point_forecast()

------------------------------------------------------------------------

### `MiltForecast$has_intervals()`

`TRUE` if prediction intervals are stored.

#### Usage

    MiltForecast$has_intervals()

------------------------------------------------------------------------

### `MiltForecast$has_samples()`

`TRUE` if sample paths are stored.

#### Usage

    MiltForecast$has_samples()

------------------------------------------------------------------------

### `MiltForecast$levels()`

Return confidence levels stored in the forecast.

#### Usage

    MiltForecast$levels()

------------------------------------------------------------------------

### `MiltForecast$horizon()`

Return the forecast horizon.

#### Usage

    MiltForecast$horizon()

------------------------------------------------------------------------

### `MiltForecast$model_name()`

Return the model name.

#### Usage

    MiltForecast$model_name()

------------------------------------------------------------------------

### `MiltForecast$as_tibble()`

Convert to a wide tibble with all intervals.

#### Usage

    MiltForecast$as_tibble()
