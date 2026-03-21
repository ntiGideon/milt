# Shiny monitoring dashboard
#
# milt_dashboard() launches an interactive Shiny app for exploring a fitted
# MiltModel: diagnostics, forecast, anomaly detection, and series overview.

#' Launch a Shiny monitoring dashboard
#'
#' Opens an interactive dashboard for exploring a fitted model and its
#' training series.  Requires the `shiny` package.
#'
#' The dashboard provides four tabs:
#' * **Series** — interactive line chart of the training data.
#' * **Forecast** — adjustable horizon slider with PI fan chart.
#' * **Diagnostics** — residuals, ACF, and histogram.
#' * **Anomalies** — IQR-based anomaly overlay.
#'
#' @param model A fitted [MiltModel].
#' @param series Optional [MiltSeries] to display; defaults to the training
#'   series stored in `model`.
#' @param port Integer. Shiny port. Default `NULL` (Shiny auto-selects).
#' @param launch_browser Logical. Open in browser? Default `TRUE`.
#' @return The Shiny app object (returned invisibly; the app blocks until
#'   the user closes it).
#' @seealso [milt_serve()]
#' @family deploy
#' @examples
#' \donttest{
#' m <- milt_model("naive") |> milt_fit(milt_series(AirPassengers))
#' # milt_dashboard(m)
#' }
#' @export
milt_dashboard <- function(model,
                            series         = NULL,
                            port           = NULL,
                            launch_browser = TRUE) {
  check_installed_backend("shiny", "milt_dashboard")
  if (!inherits(model, "MiltModel")) {
    milt_abort("{.arg model} must be a fitted {.cls MiltModel}.",
               class = "milt_error_invalid_arg")
  }
  if (!model$is_fitted()) {
    milt_abort("{.arg model} must be fitted. Call {.fn milt_fit} first.",
               class = "milt_error_not_fitted")
  }

  .model  <- model
  .series <- series %||% model$.__enclos_env__$private$.training_series
  .name   <- model$.__enclos_env__$private$.name

  ui <- shiny::fluidPage(
    shiny::titlePanel(paste("milt Dashboard —", .name)),
    shiny::tabsetPanel(
      shiny::tabPanel("Series", shiny::plotOutput("plot_series")),
      shiny::tabPanel(
        "Forecast",
        shiny::sliderInput("horizon", "Horizon (steps):",
                           min = 1L, max = 48L, value = 12L, step = 1L),
        shiny::plotOutput("plot_forecast")
      ),
      shiny::tabPanel(
        "Diagnostics",
        shiny::plotOutput("plot_resid"),
        shiny::plotOutput("plot_acf")
      ),
      shiny::tabPanel(
        "Anomalies",
        shiny::sliderInput("iqr_k", "IQR multiplier k:",
                           min = 0.5, max = 5, value = 1.5, step = 0.5),
        shiny::plotOutput("plot_anom")
      )
    )
  )

  server <- function(input, output, session) {
    output$plot_series <- shiny::renderPlot({
      plot(.series)
    })

    output$plot_forecast <- shiny::renderPlot({
      tryCatch({
        fct <- milt_forecast(.model, input$horizon)
        plot(fct)
      }, error = function(e) {
        ggplot2::ggplot() +
          ggplot2::labs(title = paste("Error:", conditionMessage(e))) +
          ggplot2::theme_void()
      })
    })

    output$plot_resid <- shiny::renderPlot({
      tryCatch({
        r   <- milt_residuals(.model)
        tbl <- tibble::tibble(
          index    = seq_along(r),
          residual = r
        )
        ggplot2::ggplot(tbl, ggplot2::aes(.data$index, .data$residual)) +
          ggplot2::geom_line(colour = "#4472C4", linewidth = 0.5) +
          ggplot2::geom_hline(yintercept = 0, linetype = "dashed",
                              colour = "#888888") +
          ggplot2::labs(title = "Residuals", x = "Index", y = "Residual") +
          ggplot2::theme_minimal()
      }, error = function(e) ggplot2::ggplot() + ggplot2::theme_void())
    })

    output$plot_acf <- shiny::renderPlot({
      tryCatch({
        r <- stats::na.omit(milt_residuals(.model))
        graphics::acf(r, main = "ACF of Residuals")
      }, error = function(e) ggplot2::ggplot() + ggplot2::theme_void())
    })

    output$plot_anom <- shiny::renderPlot({
      tryCatch({
        d   <- milt_detector("iqr", k = input$iqr_k)
        anm <- milt_detect(d, .series)
        plot(anm)
      }, error = function(e) {
        ggplot2::ggplot() +
          ggplot2::labs(title = paste("Error:", conditionMessage(e))) +
          ggplot2::theme_void()
      })
    })
  }

  app <- shiny::shinyApp(ui = ui, server = server)

  opts <- list(launch.browser = launch_browser)
  if (!is.null(port)) opts$port <- as.integer(port)

  do.call(shiny::runApp, c(list(appDir = app), opts))
  invisible(app)
}
