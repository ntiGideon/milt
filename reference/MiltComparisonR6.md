# MiltComparison - results of milt_compare()

Stores per-model backtest results and provides a ranked summary table.
Produced by
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md).
Use [`print()`](https://rdrr.io/r/base/print.html),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html), or
`as_tibble()` to inspect results.

## Methods

### Public methods

- [`MiltComparisonR6$new()`](#method-MiltComparison-new)

- [`MiltComparisonR6$backtests()`](#method-MiltComparison-backtests)

- [`MiltComparisonR6$rank_metric()`](#method-MiltComparison-rank_metric)

- [`MiltComparisonR6$n_models()`](#method-MiltComparison-n_models)

- [`MiltComparisonR6$summary_tbl()`](#method-MiltComparison-summary_tbl)

- [`MiltComparisonR6$as_tibble()`](#method-MiltComparison-as_tibble)

------------------------------------------------------------------------

### Method `new()`

Initialise (called by
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md)).

#### Usage

    MiltComparisonR6$new(backtests, rank_metric)

#### Arguments

- `backtests`:

  Named list of `MiltBacktest` objects.

- `rank_metric`:

  Character scalar: metric column (without leading `.`) used to rank
  models.

------------------------------------------------------------------------

### Method `backtests()`

Named list of `MiltBacktest` objects, one per model.

#### Usage

    MiltComparisonR6$backtests()

------------------------------------------------------------------------

### Method `rank_metric()`

Metric used for ranking.

#### Usage

    MiltComparisonR6$rank_metric()

------------------------------------------------------------------------

### Method `n_models()`

Number of models compared.

#### Usage

    MiltComparisonR6$n_models()

------------------------------------------------------------------------

### Method `summary_tbl()`

Ranked summary tibble. Columns: `model`, one column per metric (mean
across folds), `rank`.

#### Usage

    MiltComparisonR6$summary_tbl()

------------------------------------------------------------------------

### Method `as_tibble()`

Return the ranked summary tibble (same as `summary_tbl()`).

#### Usage

    MiltComparisonR6$as_tibble()
