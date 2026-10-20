# =============================================================================
# helpers.R
# Purpose : Small utility / formatting functions used across the app.
# =============================================================================

# Auto-install any missing packages before loading them
.pkgs <- c("dplyr", "ggplot2")
for (.p in .pkgs) {
  if (!requireNamespace(.p, quietly = TRUE)) install.packages(.p, quiet = TRUE)
  library(.p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
}
rm(.pkgs, .p)

# -----------------------------------------------------------------------------
# fmt_num(x, digits)
#   Format a number with comma separators and optional decimal places.
#   Used in KPI value boxes so they display nicely.
# -----------------------------------------------------------------------------
fmt_num <- function(x, digits = 0) {
  formatC(round(x, digits), format = "f", digits = digits, big.mark = ",")
}


# -----------------------------------------------------------------------------
# fmt_rating(x)
#   Format a rating to exactly 2 decimal places.
# -----------------------------------------------------------------------------
fmt_rating <- function(x) {
  sprintf("%.2f", x)
}


# -----------------------------------------------------------------------------
# safe_mean(x)
#   Returns the mean of x, or NA if x is empty / all-NA.
# -----------------------------------------------------------------------------
safe_mean <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  mean(x)
}


# -----------------------------------------------------------------------------
# no_data_plot()
#   Returns a minimal ggplot with a "No data" message.
#   Used whenever a filtered dataset has 0 rows so plots don't crash.
# -----------------------------------------------------------------------------
no_data_plot <- function(msg = "No data matches the selected filters.") {
  ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0.5, y = 0.5,
                      label = msg,
                      size = 5, colour = "#888888",
                      hjust = 0.5, vjust = 0.5) +
    ggplot2::theme_void() +
    ggplot2::xlim(0, 1) + ggplot2::ylim(0, 1)
}


# -----------------------------------------------------------------------------
# compute_kpis(df)
#   Returns a named list of KPI values calculated from the (filtered) data frame.
# -----------------------------------------------------------------------------
compute_kpis <- function(df) {
  if (nrow(df) == 0) {
    return(list(
      total_records   = 0,
      unique_games    = 0,
      total_genres    = 0,
      total_platforms = 0,
      avg_rating      = NA_real_,
      top_genre       = "—",
      top_platform    = "—"
    ))
  }

  list(
    total_records   = nrow(df),
    unique_games    = n_distinct(df$game_name),
    total_genres    = n_distinct(df$genre),
    total_platforms = n_distinct(df$platform),
    avg_rating      = safe_mean(df$user_rating),
    top_genre       = df %>%
                        count(genre, sort = TRUE) %>%
                        slice(1) %>%
                        pull(genre),
    top_platform    = df %>%
                        count(platform, sort = TRUE) %>%
                        slice(1) %>%
                        pull(platform)
  )
}


# -----------------------------------------------------------------------------
# compute_insights(df)
#   Returns a character vector of plain-language insight strings.
#   Each element is one bullet point shown in the Insights tab.
# -----------------------------------------------------------------------------
compute_insights <- function(df) {

  if (nrow(df) == 0) {
    return("No records match the current filters. Try broadening your selection.")
  }

  insights <- character(0)

  # Most common genre
  top_genre_row <- df %>% count(genre, sort = TRUE) %>% slice(1)
  insights <- c(insights,
    sprintf("🎮 <b>%s</b> is the most represented genre with <b>%s</b> entries.",
            top_genre_row$genre, fmt_num(top_genre_row$n)))

  # Most common platform
  top_platform_row <- df %>% count(platform, sort = TRUE) %>% slice(1)
  insights <- c(insights,
    sprintf("🖥️ <b>%s</b> has the most game entries with <b>%s</b> records.",
            top_platform_row$platform, fmt_num(top_platform_row$n)))

  # Highest-rated genre (avg)
  genre_rating <- df %>%
    group_by(genre) %>%
    summarise(avg = safe_mean(user_rating), n = n(), .groups = "drop") %>%
    filter(n >= 5) %>%
    arrange(desc(avg)) %>%
    slice(1)

  if (nrow(genre_rating) > 0) {
    insights <- c(insights,
      sprintf("⭐ Games in the <b>%s</b> genre have the highest average user rating of <b>%s / 10</b>.",
              genre_rating$genre, fmt_rating(genre_rating$avg)))
  }

  # Lowest-rated genre
  genre_rating_low <- df %>%
    group_by(genre) %>%
    summarise(avg = safe_mean(user_rating), n = n(), .groups = "drop") %>%
    filter(n >= 5) %>%
    arrange(avg) %>%
    slice(1)

  if (nrow(genre_rating_low) > 0) {
    insights <- c(insights,
      sprintf("📉 The <b>%s</b> genre has the lowest average user rating of <b>%s / 10</b>.",
              genre_rating_low$genre, fmt_rating(genre_rating_low$avg)))
  }

  # Highest-rated platform
  platform_rating <- df %>%
    group_by(platform) %>%
    summarise(avg = safe_mean(user_rating), n = n(), .groups = "drop") %>%
    filter(n >= 5) %>%
    arrange(desc(avg)) %>%
    slice(1)

  if (nrow(platform_rating) > 0) {
    insights <- c(insights,
      sprintf("🏆 <b>%s</b> has the highest average user rating among platforms at <b>%s / 10</b>.",
              platform_rating$platform, fmt_rating(platform_rating$avg)))
  }

  # Peak release year
  peak_year_row <- df %>% count(release_year, sort = TRUE) %>% slice(1)
  insights <- c(insights,
    sprintf("📅 <b>%s</b> was the busiest release year with <b>%s</b> game entries.",
            peak_year_row$release_year, fmt_num(peak_year_row$n)))

  # Top-rated individual game (mean across platforms/genres)
  top_game <- df %>%
    group_by(game_name) %>%
    summarise(avg = safe_mean(user_rating), n = n(), .groups = "drop") %>%
    filter(n >= 2) %>%
    arrange(desc(avg)) %>%
    slice(1)

  if (nrow(top_game) > 0) {
    insights <- c(insights,
      sprintf("🥇 <b>%s</b> is the highest-rated game (avg <b>%s / 10</b> across %d entries).",
              top_game$game_name, fmt_rating(top_game$avg), top_game$n))
  }

  # Year range
  yr_min <- min(df$release_year)
  yr_max <- max(df$release_year)
  insights <- c(insights,
    sprintf("📆 The dataset currently spans from <b>%d</b> to <b>%d</b> (%d years).",
            yr_min, yr_max, yr_max - yr_min + 1L))

  return(insights)
}
