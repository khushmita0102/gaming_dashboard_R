# =============================================================================
# app.R  —  Gaming Analytics Dashboard
# MCA Data Science Mini Project
#
# Dataset columns (after cleaning):
#   game_name    : character  — title of the game
#   genre        : character  — game genre  (14 unique values)
#   platform     : character  — platform    (5 unique values)
#   release_year : integer    — year of release (2000–2023)
#   user_rating  : numeric    — user rating (0–10)
#
# Run:  shiny::runApp()  inside the gaming-dashboard/ folder,
#       OR open this file in RStudio and click "Run App".
# =============================================================================

# ── 0. Auto-install and load all required packages ───────────────────────────
# Every package needed by app.R AND all sourced scripts is listed here.
# Missing packages are installed automatically on first run.
required_pkgs <- c(
  "shiny", "shinydashboard",   # dashboard framework
  "readr", "dplyr", "tidyr",   # data wrangling  (part of tidyverse)
  "stringr", "scales",         # string & scale helpers
  "ggplot2",                   # base plotting
  "plotly",                    # interactive charts
  "DT"                         # interactive tables
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste0("Installing missing package: ", pkg))
    install.packages(pkg, quiet = TRUE)
  }
  library(pkg, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
}
rm(pkg, required_pkgs)

# ── 1. Source helper scripts ─────────────────────────────────────────────────
source("R/data_processing.R")
source("R/helpers.R")
source("R/plots.R")
source("R/ui_components.R")

# ── 2. Load & clean data (once, at startup) ───────────────────────────────────
# The CSV must be in the same folder as app.R.
DATA_PATH <- "games_dataset.csv"

if (!file.exists(DATA_PATH)) {
  stop(paste0(
    "Cannot find '", DATA_PATH, "'.\n",
    "Please copy games_dataset.csv into the gaming-dashboard/ folder."
  ))
}

master_df <- load_and_clean_data(DATA_PATH)
choices   <- get_filter_choices(master_df)

# ── 3. UI ─────────────────────────────────────────────────────────────────────
ui <- dashboardPage(
  skin = "blue",

  # ── Header ──────────────────────────────────────────────────────────────────
  dashboardHeader(
    title = tags$span(
      icon("gamepad"), " Gaming Analytics Dashboard",
      style = "font-size: 16px; font-weight: bold;"
    ),
    titleWidth = 310
  ),

  # ── Sidebar (filters + navigation) ──────────────────────────────────────────
  sidebar_panel_ui(choices),

  # ── Body ────────────────────────────────────────────────────────────────────
  dashboardBody(

    # Link custom CSS
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ),

    tabItems(

      # ════════════════════════════════════════════════════════════════════════
      # TAB 1 — Overview
      # ════════════════════════════════════════════════════════════════════════
      tabItem(
        tabName = "tab_overview",

        # Description banner
        fluidRow(
          tags$div(
            class = "col-sm-12",
            tags$div(
              class = "banner-box",
              tags$h3(icon("gamepad"), " Gaming Analytics Dashboard",
                      style = "margin-top:0; color:#2C3E50;"),
              tags$p(
                "This dashboard analyses a dataset of popular video games across ",
                tags$b("platforms"), ", ", tags$b("genres"), ", and ", tags$b("release years"),
                ". Use the sidebar filters to narrow down the data.",
                " Explore charts, trends, and key insights — all driven by real user ratings.",
                style = "color:#555; font-size:14px;"
              ),
              tags$p(
                tags$b("Columns available: "),
                "Game Name · Genre · Platform · Release Year · User Rating",
                style = "color:#888; font-size:12px;"
              )
            )
          )
        ),

        # KPI row
        fluidRow(
          valueBoxOutput("kpi_records",  width = 2),
          valueBoxOutput("kpi_games",    width = 2),
          valueBoxOutput("kpi_genres",   width = 2),
          valueBoxOutput("kpi_platforms",width = 2),
          valueBoxOutput("kpi_avg_rating",width = 2),
          valueBoxOutput("kpi_top_genre", width = 2)
        ),

        # Overview charts
        fluidRow(
          box(
            title = "Game Entries by Genre", width = 6, solidHeader = TRUE, status = "primary",
            radioButtons("ov_genre_metric", NULL,
                         choices  = c("Count" = "count", "Avg Rating" = "avg_rating"),
                         selected = "count", inline = TRUE),
            plotlyOutput("ov_genre_bar", height = "320px")
          ),
          box(
            title = "Platform Share", width = 6, solidHeader = TRUE, status = "primary",
            plotlyOutput("ov_platform_pie", height = "360px")
          )
        ),

        fluidRow(
          box(
            title = "Game Entries Per Year", width = 12, solidHeader = TRUE, status = "info",
            plotlyOutput("ov_trend_line", height = "280px")
          )
        )
      ),


      # ════════════════════════════════════════════════════════════════════════
      # TAB 2 — Game Trends
      # ════════════════════════════════════════════════════════════════════════
      tabItem(
        tabName = "tab_trends",

        fluidRow(
          box(
            title = "Trend Options", width = 12, solidHeader = FALSE,
            collapsible = TRUE, collapsed = FALSE,
            column(4,
              radioButtons("trend_metric", "Metric to display:",
                           choices  = c("Entry Count" = "count",
                                        "Avg User Rating" = "avg_rating"),
                           selected = "count", inline = TRUE)
            )
          )
        ),

        fluidRow(
          box(
            title = "Release Trend Over Time", width = 12,
            solidHeader = TRUE, status = "primary",
            plotlyOutput("trend_line", height = "320px")
          )
        ),

        fluidRow(
          box(
            title = "Genre Entries Heatmap (Genre × Year)", width = 12,
            solidHeader = TRUE, status = "info",
            plotlyOutput("trend_heatmap", height = "420px")
          )
        )
      ),


      # ════════════════════════════════════════════════════════════════════════
      # TAB 3 — Genre & Platform
      # ════════════════════════════════════════════════════════════════════════
      tabItem(
        tabName = "tab_genre",

        fluidRow(
          box(
            title = "Chart Options", width = 12,
            collapsible = TRUE, collapsed = FALSE,
            column(4,
              radioButtons("gp_metric", "Metric:",
                           choices  = c("Entry Count" = "count",
                                        "Avg User Rating" = "avg_rating"),
                           selected = "count", inline = TRUE)
            )
          )
        ),

        fluidRow(
          box(
            title = "Genre Analysis", width = 6,
            solidHeader = TRUE, status = "primary",
            plotlyOutput("gp_genre_bar", height = "380px")
          ),
          box(
            title = "Platform Analysis", width = 6,
            solidHeader = TRUE, status = "primary",
            plotlyOutput("gp_platform_bar", height = "380px")
          )
        ),

        fluidRow(
          box(
            title = "Average Rating: Genre × Platform Heatmap", width = 12,
            solidHeader = TRUE, status = "info",
            plotlyOutput("gp_cross_heatmap", height = "420px")
          )
        )
      ),


      # ════════════════════════════════════════════════════════════════════════
      # TAB 4 — Ratings
      # ════════════════════════════════════════════════════════════════════════
      tabItem(
        tabName = "tab_ratings",

        fluidRow(
          box(
            title = "Rating Distribution", width = 6,
            solidHeader = TRUE, status = "primary",
            plotlyOutput("rat_histogram", height = "320px")
          ),
          box(
            title = "Rating Bucket Share by Genre (%)", width = 6,
            solidHeader = TRUE, status = "primary",
            plotlyOutput("rat_bucket_bar", height = "320px")
          )
        ),

        fluidRow(
          box(
            title = "Ratings Boxplot — Group By:",
            solidHeader = TRUE, status = "info", width = 12,
            column(3,
              radioButtons("rat_group", NULL,
                           choices  = c("Genre" = "genre", "Platform" = "platform"),
                           selected = "genre", inline = TRUE)
            ),
            column(9, plotlyOutput("rat_boxplot", height = "360px"))
          )
        ),

        fluidRow(
          box(
            title = "Average Rating Bar — Group By:",
            solidHeader = TRUE, status = "warning", width = 12,
            column(3,
              radioButtons("rat_avg_group", NULL,
                           choices  = c("Genre" = "genre", "Platform" = "platform"),
                           selected = "genre", inline = TRUE)
            ),
            column(9, plotlyOutput("rat_avg_bar", height = "320px"))
          )
        )
      ),


      # ════════════════════════════════════════════════════════════════════════
      # TAB 5 — Game Explorer
      # ════════════════════════════════════════════════════════════════════════
      tabItem(
        tabName = "tab_explorer",

        fluidRow(
          box(
            title = "Top Rated Games", width = 12,
            solidHeader = TRUE, status = "primary",
            column(3,
              sliderInput("top_n_games", "Show top N games:",
                          min = 5, max = 30, value = 15, step = 5)
            ),
            column(9, plotlyOutput("explorer_top_games", height = "420px"))
          )
        ),

        fluidRow(
          box(
            title = "Full Data Table", width = 12,
            solidHeader = TRUE, status = "info",
            tags$p("Search, sort, and paginate the filtered dataset.",
                   style = "color:#888; font-size:12px; margin-bottom:8px;"),
            DT::dataTableOutput("explorer_table")
          )
        )
      ),


      # ════════════════════════════════════════════════════════════════════════
      # TAB 6 — Key Insights
      # ════════════════════════════════════════════════════════════════════════
      tabItem(
        tabName = "tab_insights",

        fluidRow(
          box(
            title = "Automatically Generated Insights",
            width = 12, solidHeader = TRUE, status = "success",
            tags$p(
              "These insights are calculated live from the currently filtered dataset.",
              style = "color:#666; font-size:12px; margin-bottom: 12px;"
            ),
            uiOutput("insights_list")
          )
        ),

        fluidRow(
          box(
            title = "Filter Summary", width = 12,
            solidHeader = FALSE, status = "info",
            collapsible = TRUE, collapsed = FALSE,
            uiOutput("filter_summary")
          )
        )
      )

    ) # end tabItems
  ) # end dashboardBody
) # end dashboardPage


# ── 4. Server ─────────────────────────────────────────────────────────────────
server <- function(input, output, session) {

  # ── 4a. Reactive filtered dataset ─────────────────────────────────────────
  filtered_df <- reactive({
    apply_filters(
      df           = master_df,
      genres       = input$filter_genre,
      platforms    = input$filter_platform,
      year_range   = input$filter_year,
      rating_range = input$filter_rating
    )
  })

  # ── 4b. Reset button ──────────────────────────────────────────────────────
  observeEvent(input$btn_reset, {
    updateCheckboxGroupInput(session, "filter_genre",
                             selected = choices$genres)
    updateCheckboxGroupInput(session, "filter_platform",
                             selected = choices$platforms)
    updateSliderInput(session, "filter_year",
                      value = c(choices$year_min, choices$year_max))
    updateSliderInput(session, "filter_rating",
                      value = c(0, 10))
  })

  # ── 4c. Helper: guard against empty filtered data ─────────────────────────
  # Returns TRUE when the filtered df has 0 rows.
  is_empty <- reactive({ nrow(filtered_df()) == 0 })

  # ── 4d. KPI cards ─────────────────────────────────────────────────────────
  kpis <- reactive({ compute_kpis(filtered_df()) })

  output$kpi_records <- renderValueBox({
    make_value_box(fmt_num(kpis()$total_records), "Total Entries",
                   "database", "blue")
  })
  output$kpi_games <- renderValueBox({
    make_value_box(fmt_num(kpis()$unique_games), "Unique Games",
                   "gamepad", "purple")
  })
  output$kpi_genres <- renderValueBox({
    make_value_box(kpis()$total_genres, "Genres",
                   "tags", "green")
  })
  output$kpi_platforms <- renderValueBox({
    make_value_box(kpis()$total_platforms, "Platforms",
                   "desktop", "orange")
  })
  output$kpi_avg_rating <- renderValueBox({
    val <- if (is.na(kpis()$avg_rating)) "—" else fmt_rating(kpis()$avg_rating)
    make_value_box(val, "Avg User Rating", "star", "yellow")
  })
  output$kpi_top_genre <- renderValueBox({
    make_value_box(kpis()$top_genre, "Top Genre", "trophy", "red")
  })

  # ── 4e. Overview tab ──────────────────────────────────────────────────────
  output$ov_genre_bar <- renderPlotly({
    plot_games_by_genre(filtered_df(), metric = input$ov_genre_metric)
  })
  output$ov_platform_pie <- renderPlotly({
    plot_platform_pie(filtered_df())
  })
  output$ov_trend_line <- renderPlotly({
    plot_release_trend(filtered_df(), metric = "count")
  })

  # ── 4f. Trends tab ────────────────────────────────────────────────────────
  output$trend_line <- renderPlotly({
    plot_release_trend(filtered_df(), metric = input$trend_metric)
  })
  output$trend_heatmap <- renderPlotly({
    plot_genre_year_heatmap(filtered_df())
  })

  # ── 4g. Genre & Platform tab ─────────────────────────────────────────────
  output$gp_genre_bar <- renderPlotly({
    plot_games_by_genre(filtered_df(), metric = input$gp_metric)
  })
  output$gp_platform_bar <- renderPlotly({
    plot_platform_distribution(filtered_df(), metric = input$gp_metric)
  })
  output$gp_cross_heatmap <- renderPlotly({
    plot_genre_platform_heatmap(filtered_df())
  })

  # ── 4h. Ratings tab ───────────────────────────────────────────────────────
  output$rat_histogram <- renderPlotly({
    plot_rating_distribution(filtered_df())
  })
  output$rat_bucket_bar <- renderPlotly({
    plot_rating_bucket_bar(filtered_df())
  })
  output$rat_boxplot <- renderPlotly({
    plot_rating_boxplot(filtered_df(), group_by_col = input$rat_group)
  })
  output$rat_avg_bar <- renderPlotly({
    plot_avg_rating_bar(filtered_df(), group_by_col = input$rat_avg_group)
  })

  # ── 4i. Game Explorer tab ─────────────────────────────────────────────────
  output$explorer_top_games <- renderPlotly({
    plot_top_games(filtered_df(), top_n = input$top_n_games)
  })

  output$explorer_table <- DT::renderDataTable({
    df <- filtered_df()

    if (nrow(df) == 0) {
      return(DT::datatable(
        data.frame(Message = "No records match the selected filters."),
        options = list(dom = "t"), rownames = FALSE
      ))
    }

    display_df <- df %>%
      select(
        `Game Name`    = game_name,
        Genre          = genre,
        Platform       = platform,
        `Release Year` = release_year,
        `User Rating`  = user_rating
      ) %>%
      arrange(desc(`User Rating`))

    DT::datatable(
      display_df,
      filter    = "top",
      rownames  = FALSE,
      options   = list(
        pageLength = 15,
        scrollX    = TRUE,
        autoWidth  = TRUE,
        dom        = "lfrtip",
        columnDefs = list(
          list(className = "dt-center",
               targets   = c(2, 3, 4))
        )
      )
    ) %>%
      DT::formatRound("User Rating", digits = 2) %>%
      DT::formatStyle(
        "User Rating",
        background = DT::styleColorBar(c(0, 10), "#AED6F1"),
        backgroundSize   = "100% 90%",
        backgroundRepeat = "no-repeat",
        backgroundPosition = "center"
      )
  })

  # ── 4j. Key Insights tab ──────────────────────────────────────────────────
  output$insights_list <- renderUI({
    insights <- compute_insights(filtered_df())

    if (length(insights) == 1 && !grepl("<b>", insights[1])) {
      # Plain-text "no data" message
      return(tags$p(insights, style = "color: #E74C3C; font-size: 14px;"))
    }

    insight_items <- lapply(insights, function(txt) {
      tags$div(
        class = "insight-item",
        tags$p(HTML(txt))
      )
    })

    tagList(insight_items)
  })

  output$filter_summary <- renderUI({
    df <- filtered_df()
    tags$div(
      tags$ul(
        tags$li(paste("Genres selected:  ",
                      paste(sort(unique(df$genre)),    collapse = ", "))),
        tags$li(paste("Platforms selected:", 
                      paste(sort(unique(df$platform)), collapse = ", "))),
        tags$li(paste("Year range: ", input$filter_year[1], "–", input$filter_year[2])),
        tags$li(paste("Rating range:", input$filter_rating[1], "–", input$filter_rating[2])),
        tags$li(paste("Total matching records:", nrow(df)))
      ),
      style = "font-size: 13px; color: #555;"
    )
  })

} # end server


# ── 5. Launch ─────────────────────────────────────────────────────────────────
shinyApp(ui = ui, server = server)
