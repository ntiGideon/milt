# MiltComparison - results of milt_compare()

Stores per-model backtest results and provides a ranked summary table.
Produced by
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md).
Use [`print()`](https://rdrr.io/r/base/print.html),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html), or
`as_tibble()` to inspect results.

## Methods

### Public methods

- [`MiltComparison$new()`](#method-MiltComparison-initialize)

- [`MiltComparison$backtests()`](#method-MiltComparison-backtests)

- [`MiltComparison$rank_metric()`](#method-MiltComparison-rank_metric)

- [`MiltComparison$n_models()`](#method-MiltComparison-n_models)

- [`MiltComparison$summary_tbl()`](#method-MiltComparison-summary_tbl)

- [`MiltComparison$as_tibble()`](#method-MiltComparison-as_tibble)

------------------------------------------------------------------------

### `MiltComparison$new()`

Initialise (called by
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md)).

#### Usage

    MiltComparison$new(backtests, rank_metric)

#### Arguments

- `backtests`:

  Named list of `MiltBacktest` objects.

- `rank_metric`:

  Character scalar: metric column (without leading `.`) used to rank
  models.

------------------------------------------------------------------------

### `MiltComparison$backtests()`

Named list of `MiltBacktest` objects, one per model.

#### Usage

    MiltComparison$backtests()

------------------------------------------------------------------------

### `MiltComparison$rank_metric()`

Metric used for ranking.

#### Usage

    MiltComparison$rank_metric()

------------------------------------------------------------------------

### `MiltComparison$n_models()`

Number of models compared.

#### Usage

    MiltComparison$n_models()

------------------------------------------------------------------------

### `MiltComparison$summary_tbl()`

Ranked summary tibble. Columns: `model`, one column per metric (mean
across folds), `rank`.

#### Usage

    MiltComparison$summary_tbl()

------------------------------------------------------------------------

### `MiltComparison$as_tibble()`

Return the ranked summary tibble (same as `summary_tbl()`).

#### Usage

    MiltComparison$as_tibble()
