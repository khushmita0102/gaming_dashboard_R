# =============================================================================
# ui_components.R
# Purpose : Reusable UI-building helper functions.
#           Keeps app.R clean and readable.
# =============================================================================

# Auto-install any missing packages before loading them
.pkgs <- c("shiny", "shinydashboard")
for (.p in .pkgs) {
  if (!requireNamespace(.p, quietly = TRUE)) install.packages(.p, quiet = TRUE)
  library(.p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
}
rm(.pkgs, .p)

# -----------------------------------------------------------------------------
# kpi_card(id, title, icon_name, color)
#   Wraps shinydashboard::valueBoxOutput in a column for easy placement.
#   color: "blue" | "green" | "orange" | "purple" | "red" | "yellow"
# -----------------------------------------------------------------------------
kpi_card <- function(id, title, icon_name, color = "blue", width = 2) {
  column(
    width = width,
    valueBoxOutput(outputId = id, width = NULL)
  )
}


# -----------------------------------------------------------------------------
# make_value_box(value, subtitle, icon_name, color)
#   Returns a shinydashboard::valueBox.
#   Called inside renderValueBox() in server.R.
# -----------------------------------------------------------------------------
make_value_box <- function(value, subtitle, icon_name, color = "blue") {
  valueBox(
    value    = value,
    subtitle = subtitle,
    icon     = icon(icon_name),
    color    = color,
    width    = NULL
  )
}


# -----------------------------------------------------------------------------
# sidebar_panel_ui(choices)
#   Builds the complete sidebar filter panel.
#   choices is the list returned by get_filter_choices().
# -----------------------------------------------------------------------------
sidebar_panel_ui <- function(choices) {
  dashboardSidebar(
    width = 260,

    sidebarMenu(
      id = "main_menu",
      menuItem("Overview",          tabName = "tab_overview",    icon = icon("home")),
      menuItem("Game Trends",       tabName = "tab_trends",      icon = icon("chart-line")),
      menuItem("Genre & Platform",  tabName = "tab_genre",       icon = icon("gamepad")),
      menuItem("Ratings",           tabName = "tab_ratings",     icon = icon("star")),
      menuItem("Game Explorer",     tabName = "tab_explorer",    icon = icon("table")),
      menuItem("Key Insights",      tabName = "tab_insights",    icon = icon("lightbulb"))
    ),

    tags$hr(),

    # ── Filter heading ──────────────────────────────────────────────────────
    tags$div(
      style = "padding: 0 15px;",
      tags$p(tags$b("🔍 Filters"), style = "color: #ECF0F1; font-size: 13px; margin-bottom: 4px;"),
      tags$p("Filters apply to all tabs.", style = "color: #BDC3C7; font-size: 11px;")
    ),

    # ── Genre ───────────────────────────────────────────────────────────────
    tags$div(
      style = "padding: 0 15px;",
      checkboxGroupInput(
        inputId  = "filter_genre",
        label    = tags$span("Genre", style = "color: #ECF0F1; font-size: 12px;"),
        choices  = choices$genres,
        selected = choices$genres
      )
    ),

    # ── Platform ────────────────────────────────────────────────────────────
    tags$div(
      style = "padding: 0 15px;",
      checkboxGroupInput(
        inputId  = "filter_platform",
        label    = tags$span("Platform", style = "color: #ECF0F1; font-size: 12px;"),
        choices  = choices$platforms,
        selected = choices$platforms
      )
    ),

    # ── Year range ──────────────────────────────────────────────────────────
    tags$div(
      style = "padding: 0 15px;",
      sliderInput(
        inputId = "filter_year",
        label   = tags$span("Release Year", style = "color: #ECF0F1; font-size: 12px;"),
        min     = choices$year_min,
        max     = choices$year_max,
        value   = c(choices$year_min, choices$year_max),
        step    = 1,
        sep     = ""
      )
    ),

    # ── Rating range ────────────────────────────────────────────────────────
    tags$div(
      style = "padding: 0 15px;",
      sliderInput(
        inputId = "filter_rating",
        label   = tags$span("User Rating", style = "color: #ECF0F1; font-size: 12px;"),
        min     = 0,
        max     = 10,
        value   = c(0, 10),
        step    = 0.5
      )
    ),

    # ── Reset button ────────────────────────────────────────────────────────
    tags$div(
      style = "padding: 8px 15px 15px;",
      actionButton(
        inputId = "btn_reset",
        label   = "Reset All Filters",
        icon    = icon("undo"),
        class   = "btn btn-warning btn-sm btn-block",
        style   = "width: 100%; font-size: 12px;"
      )
    )
  )
}
