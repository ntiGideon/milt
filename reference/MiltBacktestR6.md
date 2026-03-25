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

- [`MiltBacktestR6$new()`](#method-MiltBacktest-new)

- [`MiltBacktestR6$model_name()`](#method-MiltBacktest-model_name)

- [`MiltBacktestR6$method()`](#method-MiltBacktest-method)

- [`MiltBacktestR6$horizon()`](#method-MiltBacktest-horizon)

- [`MiltBacktestR6$n_folds()`](#method-MiltBacktest-n_folds)

- [`MiltBacktestR6$metrics()`](#method-MiltBacktest-metrics)

- [`MiltBacktestR6$summary_tbl()`](#method-MiltBacktest-summary_tbl)

- [`MiltBacktestR6$as_tibble()`](#method-MiltBacktest-as_tibble)

------------------------------------------------------------------------

### Method `new()`

Initialise (called internally by
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)).

#### Usage

    MiltBacktestR6$new(model_name, method, horizon, fold_results)

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

### Method `model_name()`

Model identifier string.

#### Usage

    MiltBacktestR6$model_name()

------------------------------------------------------------------------

### Method `method()`

Backtesting method: `"expanding"` or `"sliding"`.

#### Usage

    MiltBacktestR6$method()

------------------------------------------------------------------------

### Method `horizon()`

Forecast horizon used.

#### Usage

    MiltBacktestR6$horizon()

------------------------------------------------------------------------

### Method `n_folds()`

Number of folds evaluated.

#### Usage

    MiltBacktestR6$n_folds()

------------------------------------------------------------------------

### Method `metrics()`

Per-fold metric tibble. Columns: `.fold`, `.train_n`, `.test_n`, plus
one column per metric.

#### Usage

    MiltBacktestR6$metrics()

------------------------------------------------------------------------

### Method `summary_tbl()`

Aggregated summary tibble. Columns: `metric`, `mean`, `sd`, `min`,
`max`.

#### Usage

    MiltBacktestR6$summary_tbl()

------------------------------------------------------------------------

### Method `as_tibble()`

Return per-fold metric tibble (same as `metrics()`).

#### Usage

    MiltBacktestR6$as_tibble()
