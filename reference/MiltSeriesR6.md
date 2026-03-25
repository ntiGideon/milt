# MiltSeries — core time series object

The foundational data structure for the milt package. Every model,
detector, and pipeline operates on `MiltSeries` objects. Create one with
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md).

## Methods

### Public methods

- [`MiltSeriesR6$new()`](#method-MiltSeries-new)

- [`MiltSeriesR6$n_timesteps()`](#method-MiltSeries-n_timesteps)

- [`MiltSeriesR6$n_components()`](#method-MiltSeries-n_components)

- [`MiltSeriesR6$n_series()`](#method-MiltSeries-n_series)

- [`MiltSeriesR6$start_time()`](#method-MiltSeries-start_time)

- [`MiltSeriesR6$end_time()`](#method-MiltSeries-end_time)

- [`MiltSeriesR6$freq()`](#method-MiltSeries-freq)

- [`MiltSeriesR6$is_univariate()`](#method-MiltSeries-is_univariate)

- [`MiltSeriesR6$is_multivariate()`](#method-MiltSeries-is_multivariate)

- [`MiltSeriesR6$is_multi_series()`](#method-MiltSeries-is_multi_series)

- [`MiltSeriesR6$has_gaps()`](#method-MiltSeries-has_gaps)

- [`MiltSeriesR6$gaps()`](#method-MiltSeries-gaps)

- [`MiltSeriesR6$values()`](#method-MiltSeries-values)

- [`MiltSeriesR6$times()`](#method-MiltSeries-times)

- [`MiltSeriesR6$as_tibble()`](#method-MiltSeries-as_tibble)

- [`MiltSeriesR6$as_tsibble()`](#method-MiltSeries-as_tsibble)

- [`MiltSeriesR6$as_ts()`](#method-MiltSeries-as_ts)

- [`MiltSeriesR6$clone_with()`](#method-MiltSeries-clone_with)

- [`MiltSeriesR6$clone()`](#method-MiltSeries-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new MiltSeries.

#### Usage

    MiltSeriesR6$new(
      data,
      time_col,
      value_cols,
      group_col = NULL,
      frequency = NULL,
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

- `metadata`:

  Named list of arbitrary metadata.

------------------------------------------------------------------------

### Method `n_timesteps()`

Number of time steps (rows per series).

#### Usage

    MiltSeriesR6$n_timesteps()

------------------------------------------------------------------------

### Method `n_components()`

Number of value columns (components).

#### Usage

    MiltSeriesR6$n_components()

------------------------------------------------------------------------

### Method `n_series()`

Number of individual series (groups).

#### Usage

    MiltSeriesR6$n_series()

------------------------------------------------------------------------

### Method `start_time()`

First timestamp.

#### Usage

    MiltSeriesR6$start_time()

------------------------------------------------------------------------

### Method `end_time()`

Last timestamp.

#### Usage

    MiltSeriesR6$end_time()

------------------------------------------------------------------------

### Method `freq()`

Frequency label.

#### Usage

    MiltSeriesR6$freq()

------------------------------------------------------------------------

### Method `is_univariate()`

`TRUE` if there is exactly one value column.

#### Usage

    MiltSeriesR6$is_univariate()

------------------------------------------------------------------------

### Method `is_multivariate()`

`TRUE` if there are multiple value columns.

#### Usage

    MiltSeriesR6$is_multivariate()

------------------------------------------------------------------------

### Method `is_multi_series()`

`TRUE` if a group column is set.

#### Usage

    MiltSeriesR6$is_multi_series()

------------------------------------------------------------------------

### Method `has_gaps()`

`TRUE` if the time index contains gaps.

#### Usage

    MiltSeriesR6$has_gaps()

------------------------------------------------------------------------

### Method `gaps()`

Return a tibble describing each gap.

#### Usage

    MiltSeriesR6$gaps()

------------------------------------------------------------------------

### Method `values()`

Extract values as a numeric vector (univariate) or matrix.

#### Usage

    MiltSeriesR6$values()

------------------------------------------------------------------------

### Method `times()`

Extract the time column as a vector.

#### Usage

    MiltSeriesR6$times()

------------------------------------------------------------------------

### Method `as_tibble()`

Return the underlying data as a tibble.

#### Usage

    MiltSeriesR6$as_tibble()

------------------------------------------------------------------------

### Method `as_tsibble()`

Convert to a tsibble.

#### Usage

    MiltSeriesR6$as_tsibble()

------------------------------------------------------------------------

### Method `as_ts()`

Convert to a base `ts` object (univariate only).

#### Usage

    MiltSeriesR6$as_ts()

------------------------------------------------------------------------

### Method `clone_with()`

Create a new `MiltSeries` with the same metadata but different
underlying data.

#### Usage

    MiltSeriesR6$clone_with(data)

#### Arguments

- `data`:

  A tibble with the same column structure.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MiltSeriesR6$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
