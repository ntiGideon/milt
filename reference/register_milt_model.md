# Register a model backend with the milt model registry

Called once per backend file, typically from a `.onLoad_<name>()`
function invoked in `zzz.R`'s `.milt_register_builtins()`.

## Usage

``` r
register_milt_model(name, class, description = "", supports = list())
```

## Arguments

- name:

  Character scalar. The model identifier passed to
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md).

- class:

  An R6 class generator that inherits from `MiltModelBase`.

- description:

  One-sentence description shown in
  [`list_milt_models()`](https://ntiGideon.github.io/milt/reference/list_milt_models.md).

- supports:

  Named list of logical flags. Recognised keys: `multivariate`,
  `probabilistic`, `covariates`, `multi_series`.

## Value

Invisibly returns `name`.
