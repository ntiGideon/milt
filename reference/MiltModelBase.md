# MiltModelBase — base class for all milt model backends

Every model backend inherits from this class and overrides `fit()`,
`forecast()`, [`predict()`](https://rdrr.io/r/stats/predict.html), and
[`residuals()`](https://rdrr.io/r/stats/residuals.html). Users interact
exclusively through the public verbs
[`milt_model()`](https://ntigideon.github.io/milt/reference/milt_model.md),
[`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntigideon.github.io/milt/reference/milt_forecast.md),
[`milt_predict()`](https://ntigideon.github.io/milt/reference/milt_predict.md),
and
[`milt_residuals()`](https://ntigideon.github.io/milt/reference/milt_residuals.md).

## Methods

### Public methods

- [`MiltModel$new()`](#method-MiltModel-initialize)

- [`MiltModel$fit()`](#method-MiltModel-fit)

- [`MiltModel$forecast()`](#method-MiltModel-forecast)

- [`MiltModel$predict()`](#method-MiltModel-predict)

- [`MiltModel$residuals()`](#method-MiltModel-residuals)

- [`MiltModel$is_fitted()`](#method-MiltModel-is_fitted)

- [`MiltModel$get_params()`](#method-MiltModel-get_params)

- [`MiltModel$summary()`](#method-MiltModel-summary)

- [`MiltModel$clone()`](#method-MiltModel-clone)

------------------------------------------------------------------------

### `MiltModel$new()`

Initialise a model with hyperparameters.

#### Usage

    MiltModel$new(name = NULL, ...)

#### Arguments

- `name`:

  Character scalar: model identifier string.

- `...`:

  Hyperparameters stored in `private$.params`.

------------------------------------------------------------------------

### `MiltModel$fit()`

Fit the model to a `MiltSeries`. **Must be overridden.**

#### Usage

    MiltModel$fit(series)

#### Arguments

- `series`:

  A `MiltSeries` object.

------------------------------------------------------------------------

### `MiltModel$forecast()`

Generate a `MiltForecast`. **Must be overridden.**

#### Usage

    MiltModel$forecast(horizon, ...)

#### Arguments

- `horizon`:

  Integer number of steps ahead.

- `...`:

  Additional arguments.

------------------------------------------------------------------------

### `MiltModel$predict()`

In-sample predictions. **Must be overridden.**

#### Usage

    MiltModel$predict(series = NULL)

#### Arguments

- `series`:

  Optional `MiltSeries`. When `NULL`, returns training fitted values.

------------------------------------------------------------------------

### `MiltModel$residuals()`

Training residuals. **Must be overridden.**

#### Usage

    MiltModel$residuals()

------------------------------------------------------------------------

### `MiltModel$is_fitted()`

`TRUE` after
[`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md)
has been called successfully.

#### Usage

    MiltModel$is_fitted()

------------------------------------------------------------------------

### `MiltModel$get_params()`

Return the hyperparameter list supplied at construction.

#### Usage

    MiltModel$get_params()

------------------------------------------------------------------------

### `MiltModel$summary()`

Print a summary to the console.

#### Usage

    MiltModel$summary()

------------------------------------------------------------------------

### `MiltModel$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MiltModel$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
