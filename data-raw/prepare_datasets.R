## data-raw/prepare_datasets.R
## Run this script ONCE from the package root to generate data/*.rda files.
##
##   source("data-raw/prepare_datasets.R")
##
## No external packages required (base R only).

if (!dir.exists("data")) dir.create("data")

# ── milt_air ─────────────────────────────────────────────────────────────────
milt_air <- tibble::tibble(
  date  = seq(as.Date("1949-01-01"), by = "month", length.out = 144L),
  value = as.numeric(AirPassengers)
)
save(milt_air, file = "data/milt_air.rda", compress = "bzip2", version = 2)
message("Saved data/milt_air.rda")

# ── milt_retail ───────────────────────────────────────────────────────────────
set.seed(42L)

.make_series <- function(base, trend, amp, noise_sd) {
  n    <- 156L
  t    <- seq_len(n)
  seas <- amp * sin(2 * pi * t / 12) + (amp / 2) * cos(2 * pi * t / 12)
  pmax(base + trend * t + seas + stats::rnorm(n, sd = noise_sd), 0)
}

categories <- c("Electronics", "Clothing", "Food", "Furniture", "Toys")
params <- list(
  Electronics = list(base = 1000, trend = 3,   amp = 80,  noise = 40),
  Clothing    = list(base = 600,  trend = 1.5, amp = 120, noise = 30),
  Food        = list(base = 2000, trend = 0.5, amp = 40,  noise = 20),
  Furniture   = list(base = 400,  trend = 2,   amp = 30,  noise = 25),
  Toys        = list(base = 300,  trend = 1,   amp = 200, noise = 35)
)
dates <- seq(as.Date("2010-01-01"), by = "month", length.out = 156L)

milt_retail <- do.call(rbind, lapply(categories, function(cat) {
  p <- params[[cat]]
  tibble::tibble(
    date     = dates,
    category = cat,
    sales    = .make_series(p$base, p$trend, p$amp, p$noise)
  )
}))
save(milt_retail, file = "data/milt_retail.rda", compress = "bzip2", version = 2)
message("Saved data/milt_retail.rda")

# ── milt_energy ───────────────────────────────────────────────────────────────
set.seed(7L)
n_hours     <- 60L * 24L
hour_of_day <- rep(0:23, times = 60L)
day_of_week <- rep(rep(0:6, each = 24L), length.out = n_hours)
is_weekend  <- as.integer(day_of_week %in% c(0L, 6L))

temp <- 15 +
  8 * sin(2 * pi * hour_of_day / 24 - pi / 2) +
  5 * sin(2 * pi * seq_len(n_hours) / n_hours) +
  stats::rnorm(n_hours, sd = 1.5)

consumption <- pmax(
  50 +
    20 * (sin(2 * pi * (hour_of_day - 8) / 24) + 1) +
    (-5 * is_weekend) +
    (-0.3 * (temp - 15)) +
    stats::rnorm(n_hours, sd = 2),
  0
)

milt_energy <- tibble::tibble(
  datetime    = seq(as.POSIXct("2023-01-01 00:00:00", tz = "UTC"),
                    by = "hour", length.out = n_hours),
  consumption = consumption,
  temperature = temp,
  is_weekend  = is_weekend
)
save(milt_energy, file = "data/milt_energy.rda", compress = "bzip2", version = 2)
message("Saved data/milt_energy.rda")

message("Done. Rebuild the package (devtools::load_all()) to make datasets available.")
