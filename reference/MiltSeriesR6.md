# MiltSeries — core time series object

The foundational data structure for the milt package. Every model,
detector, and pipeline operates on `MiltSeries` objects. Create one with
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md).

## Methods

### Public methods

- [`MiltSeries$new()`](#method-MiltSeries-initialize)

- [`MiltSeries$n_timesteps()`](#method-MiltSeries-n_timesteps)

- [`MiltSeries$n_components()`](#method-MiltSeries-n_components)

- [`MiltSeries$n_series()`](#method-MiltSeries-n_series)

- [`MiltSeries$start_time()`](#method-MiltSeries-start_time)

- [`MiltSeries$end_time()`](#method-MiltSeries-end_time)

- [`MiltSeries$freq()`](#method-MiltSeries-freq)

- [`MiltSeries$is_univariate()`](#method-MiltSeries-is_univariate)

- [`MiltSeries$is_multivariate()`](#method-MiltSeries-is_multivariate)

- [`MiltSeries$is_multi_series()`](#method-MiltSeries-is_multi_series)

- [`MiltSeries$has_gaps()`](#method-MiltSeries-has_gaps)

- [`MiltSeries$gaps()`](#method-MiltSeries-gaps)

- [`MiltSeries$values()`](#method-MiltSeries-values)

- [`MiltSeries$times()`](#method-MiltSeries-times)

- [`MiltSeries$as_tibble()`](#method-MiltSeries-as_tibble)

- [`MiltSeries$as_tsibble()`](#method-MiltSeries-as_tsibble)

- [`MiltSeries$as_ts()`](#method-MiltSeries-as_ts)

- [`MiltSeries$clone_with()`](#method-MiltSeries-clone_with)

- [`MiltSeries$clone()`](#method-MiltSeries-clone)

------------------------------------------------------------------------

### `MiltSeries$new()`

Create a new MiltSeries.

#### Usage

    MiltSeries$new(
      data,
      time_col,
      value_cols,
      group_col = NULL,
      frequency = NULL,
      static_covs = NULL,
      past_covs = NULL,
      future_covs = NULL,
      metadata = list()
    )

#### Arguments

- `data`:

  A tibble containing time + value columns.

- `time_col`:

  Name of the time column.

- `value_cols`:

  Character vector of value column names.

- `group_col`:

  Optional name of the grouping column (multi-series).

- `frequency`:

  Frequency label (e.g. `"monthly"`, `"daily"`) or numeric.
  Auto-detected when `NULL`.

- `static_covs`:

  Optional tibble of per-group static covariates (see
  [`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md)).

- `past_covs`:

  Optional tibble of past (time-varying) covariates.

- `future_covs`:

  Optional tibble of future (time-varying) covariates.

- `metadata`:

  Named list of arbitrary metadata.

------------------------------------------------------------------------

### `MiltSeries$n_timesteps()`

Number of time steps (rows per series).

#### Usage

    MiltSeries$n_timesteps()

------------------------------------------------------------------------

### `MiltSeries$n_components()`

Number of value columns (components).

#### Usage

    MiltSeries$n_components()

------------------------------------------------------------------------

### `MiltSeries$n_series()`

Number of individual series (groups).

#### Usage

    MiltSeries$n_series()

------------------------------------------------------------------------

### `MiltSeries$start_time()`

First timestamp.

#### Usage

    MiltSeries$start_time()

------------------------------------------------------------------------

### `MiltSeries$end_time()`

Last timestamp.

#### Usage

    MiltSeries$end_time()

------------------------------------------------------------------------

### `MiltSeries$freq()`

Frequency label.

#### Usage

    MiltSeries$freq()

------------------------------------------------------------------------

### `MiltSeries$is_univariate()`

`TRUE` if there is exactly one value column.

#### Usage

    MiltSeries$is_univariate()

------------------------------------------------------------------------

### `MiltSeries$is_multivariate()`

`TRUE` if there are multiple value columns.

#### Usage

    MiltSeries$is_multivariate()

------------------------------------------------------------------------

### `MiltSeries$is_multi_series()`

`TRUE` if a group column is set.

#### Usage

    MiltSeries$is_multi_series()

------------------------------------------------------------------------

### `MiltSeries$has_gaps()`

`TRUE` if the time index contains gaps.

#### Usage

    MiltSeries$has_gaps()

------------------------------------------------------------------------

### `MiltSeries$gaps()`

Return a tibble describing each gap.

#### Usage

    MiltSeries$gaps()

------------------------------------------------------------------------

### `MiltSeries$values()`

Extract values as a numeric vector (univariate) or matrix.

#### Usage

    MiltSeries$values()

------------------------------------------------------------------------

### `MiltSeries$times()`

Extract the time column as a vector.

#### Usage

    MiltSeries$times()

------------------------------------------------------------------------

### `MiltSeries$as_tibble()`

Return the underlying data as a tibble.

#### Usage

    MiltSeries$as_tibble()

------------------------------------------------------------------------

### `MiltSeries$as_tsibble()`

Convert to a tsibble.

#### Usage

    MiltSeries$as_tsibble()

------------------------------------------------------------------------

### `MiltSeries$as_ts()`

Convert to a base `ts` object (univariate only).

#### Usage

    MiltSeries$as_ts()

------------------------------------------------------------------------

### `MiltSeries$clone_with()`

Create a new `MiltSeries` with the same metadata but different
underlying data.

#### Usage

    MiltSeries$clone_with(data)

#### Arguments

- `data`:

  A tibble with the same column structure.

------------------------------------------------------------------------

### `MiltSeries$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MiltSeries$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
