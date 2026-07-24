# Shared visual design system for every plot.* method in milt.
#
# One validated categorical order, one sequential ramp, one status set, one
# ink/chrome scale, and one ggplot2 theme — referenced by hex value everywhere
# a plot is built, instead of each file inventing its own ad hoc colours.

# ── Categorical palette (fixed hue order — never cycled) ─────────────────────
# Safe for bars/lines/stacks (adjacent-pair CVD gate) across all 8 slots.
# For scatter/point forms where every pair can appear on screen at once, only
# the first 3 slots are guaranteed distinguishable; beyond that, identity
# should also be carried by position or faceting, not colour alone.
.milt_categorical <- c(
  "#2a78d6", # 1 blue
  "#eb6834", # 2 orange
  "#1baf7a", # 3 aqua
  "#eda100", # 4 yellow
  "#e87ba4", # 5 magenta
  "#008300", # 6 green
  "#4a3aa7", # 7 violet
  "#e34948"  # 8 red
)

# Returns the first n categorical hues in fixed order, recycling with a
# neutral grey once the validated set (8 hues) is exhausted.
.milt_pal_cat <- function(n) {
  base <- .milt_categorical
  if (n <= length(base)) return(base[seq_len(n)])
  c(base, rep("#c3c2b7", n - length(base)))
}

# ── Sequential ramp (single hue, light -> dark) — magnitude / uncertainty ────
.milt_seq_blue <- c(
  "100" = "#cde2fb", "150" = "#b7d3f6", "200" = "#9ec5f4", "250" = "#86b6ef",
  "300" = "#6da7ec", "350" = "#5598e7", "400" = "#3987e5", "450" = "#2a78d6",
  "500" = "#256abf", "550" = "#1c5cab", "600" = "#184f95", "650" = "#104281",
  "700" = "#0d366b"
)

# Returns n evenly-spaced steps from the sequential ramp, light to dark.
# `range` indexes into the 13-step ramp (1 = lightest, 13 = darkest); the
# default trims both extremes so a single requested step is never so pale
# it disappears against a white legend swatch.
.milt_pal_seq <- function(n, range = c(3L, 10L)) {
  steps <- as.integer(names(.milt_seq_blue))
  idx   <- round(seq(range[[1L]], range[[2L]], length.out = n))
  unname(.milt_seq_blue[idx])
}

# ── Status colours (fixed — never reassigned to a series) ────────────────────
.milt_status <- c(
  good     = "#0ca30c",
  warning  = "#fab219",
  serious  = "#ec835a",
  critical = "#d03b3b"
)

# ── Chart chrome / ink ────────────────────────────────────────────────────────
.milt_ink <- c(
  primary   = "#0b0b0b",
  secondary = "#52514e",
  muted     = "#898781",
  gridline  = "#e1e0d9",
  baseline  = "#c3c2b7"
)

# Primary accent for single-series ("this is the model/estimate") lines.
.milt_primary <- .milt_categorical[[1L]]

# ── Shared ggplot2 theme ──────────────────────────────────────────────────────
.milt_plot_theme <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = .milt_ink[["gridline"]]),
      axis.line.x        = ggplot2::element_line(colour = .milt_ink[["baseline"]]),
      axis.ticks         = ggplot2::element_blank(),
      axis.text          = ggplot2::element_text(colour = .milt_ink[["secondary"]]),
      axis.title         = ggplot2::element_text(colour = .milt_ink[["secondary"]]),
      plot.title         = ggplot2::element_text(face = "bold", colour = .milt_ink[["primary"]]),
      plot.subtitle      = ggplot2::element_text(colour = .milt_ink[["secondary"]]),
      legend.position    = "bottom",
      legend.text        = ggplot2::element_text(colour = .milt_ink[["primary"]]),
      legend.title       = ggplot2::element_text(face = "bold", colour = .milt_ink[["primary"]]),
      legend.key         = ggplot2::element_rect(fill = "white", colour = NA)
    )
}
