# MiltBacktest — walk-forward evaluation results

Returned by
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md).
Stores per-fold forecast accuracy metrics and provides helpers for
summarising and visualising backtest results.

Users do not instantiate this class directly; use
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)
instead.

## Methods

### Public methods

- [`MiltBacktest$new()`](#method-MiltBacktest-initialize)

- [`MiltBacktest$model_name()`](#method-MiltBacktest-model_name)

- [`MiltBacktest$method()`](#method-MiltBacktest-method)

- [`MiltBacktest$horizon()`](#method-MiltBacktest-horizon)

- [`MiltBacktest$n_folds()`](#method-MiltBacktest-n_folds)

- [`MiltBacktest$metrics()`](#method-MiltBacktest-metrics)

- [`MiltBacktest$summary_tbl()`](#method-MiltBacktest-summary_tbl)

- [`MiltBacktest$as_tibble()`](#method-MiltBacktest-as_tibble)

------------------------------------------------------------------------

### `MiltBacktest$new()`

Initialise (called internally by
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)).

#### Usage

    MiltBacktest$new(model_name, method, horizon, fold_results)

#### Arguments

- `model_name`:

  Character scalar.

- `method`:

  Character scalar: `"expanding"` or `"sliding"`.

- `horizon`:

  Integer forecast horizon.

- `fold_results`:

  Tibble with per-fold metrics.

------------------------------------------------------------------------

### `MiltBacktest$model_name()`

Model identifier string.

#### Usage

    MiltBacktest$model_name()

------------------------------------------------------------------------

### `MiltBacktest$method()`

Backtesting method: `"expanding"` or `"sliding"`.

#### Usage

    MiltBacktest$method()

------------------------------------------------------------------------

### `MiltBacktest$horizon()`

Forecast horizon used.

#### Usage

    MiltBacktest$horizon()

------------------------------------------------------------------------

### `MiltBacktest$n_folds()`

Number of folds evaluated.

#### Usage

    MiltBacktest$n_folds()

------------------------------------------------------------------------

### `MiltBacktest$metrics()`

Per-fold metric tibble. Columns: `.fold`, `.train_n`, `.test_n`, plus
one column per metric.

#### Usage

    MiltBacktest$metrics()

------------------------------------------------------------------------

### `MiltBacktest$summary_tbl()`

Aggregated summary tibble. Columns: `metric`, `mean`, `sd`, `min`,
`max`.

#### Usage

    MiltBacktest$summary_tbl()

------------------------------------------------------------------------

### `MiltBacktest$as_tibble()`

Return per-fold metric tibble (same as `metrics()`).

#### Usage

    MiltBacktest$as_tibble()
