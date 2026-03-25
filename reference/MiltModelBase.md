# MiltModelBase — base class for all milt model backends

Every model backend inherits from this class and overrides `fit()`,
`forecast()`, [`predict()`](https://rdrr.io/r/stats/predict.html), and
[`residuals()`](https://rdrr.io/r/stats/residuals.html). Users interact
exclusively through the public verbs
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
and
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md).

## Methods

### Public methods

- [`MiltModelBase$new()`](#method-MiltModel-new)

- [`MiltModelBase$fit()`](#method-MiltModel-fit)

- [`MiltModelBase$forecast()`](#method-MiltModel-forecast)

- [`MiltModelBase$predict()`](#method-MiltModel-predict)

- [`MiltModelBase$residuals()`](#method-MiltModel-residuals)

- [`MiltModelBase$is_fitted()`](#method-MiltModel-is_fitted)

- [`MiltModelBase$get_params()`](#method-MiltModel-get_params)

- [`MiltModelBase$summary()`](#method-MiltModel-summary)

- [`MiltModelBase$clone()`](#method-MiltModel-clone)

------------------------------------------------------------------------

### Method `new()`

Initialise a model with hyperparameters.

#### Usage

    MiltModelBase$new(name = NULL, ...)

#### Arguments

- `name`:

  Character scalar: model identifier string.

- `...`:

  Hyperparameters stored in `private$.params`.

------------------------------------------------------------------------

### Method `fit()`

Fit the model to a `MiltSeries`. **Must be overridden.**

#### Usage

    MiltModelBase$fit(series)

#### Arguments

- `series`:

  A `MiltSeries` object.

------------------------------------------------------------------------

### Method `forecast()`

Generate a `MiltForecast`. **Must be overridden.**

#### Usage

    MiltModelBase$forecast(horizon, ...)

#### Arguments

- `horizon`:

  Integer number of steps ahead.

- `...`:

  Additional arguments.

------------------------------------------------------------------------

### Method [`predict()`](https://rdrr.io/r/stats/predict.html)

In-sample predictions. **Must be overridden.**

#### Usage

    MiltModelBase$predict(series = NULL)

#### Arguments

- `series`:

  Optional `MiltSeries`. When `NULL`, returns training fitted values.

------------------------------------------------------------------------

### Method [`residuals()`](https://rdrr.io/r/stats/residuals.html)

Training residuals. **Must be overridden.**

#### Usage

    MiltModelBase$residuals()

------------------------------------------------------------------------

### Method `is_fitted()`

`TRUE` after
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md)
has been called successfully.

#### Usage

    MiltModelBase$is_fitted()

------------------------------------------------------------------------

### Method `get_params()`

Return the hyperparameter list supplied at construction.

#### Usage

    MiltModelBase$get_params()

------------------------------------------------------------------------

### Method [`summary()`](https://rdrr.io/r/base/summary.html)

Print a summary to the console.

#### Usage

    MiltModelBase$summary()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MiltModelBase$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
