# =============================================================================
# plots.R
# Purpose : All chart-generating functions.
#           Every function returns a plotly object (converted from ggplot2
#           where appropriate) so charts are interactive in the browser.
#           Each function accepts a (possibly filtered) data frame and
#           additional configuration arguments.
# =============================================================================

# Auto-install any missing packages before loading them
.pkgs <- c("ggplot2", "plotly", "dplyr", "tidyr", "scales")
for (.p in .pkgs) {
  if (!requireNamespace(.p, quietly = TRUE)) install.packages(.p, quiet = TRUE)
  library(.p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
}
rm(.pkgs, .p)

# Shared colour palette — consistent across all charts
PALETTE <- c(
  "#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F",
  "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC",
  "#D4E157", "#26C6DA", "#EF9A9A", "#A5D6A7", "#CE93D8"
)

# Theme used for all ggplot charts
theme_gaming <- function() {
  theme_minimal(base_size = 13) +
    theme(
      plot.title       = element_text(face = "bold", size = 14, colour = "#2C3E50"),
      plot.subtitle    = element_text(size = 11, colour = "#7F8C8D"),
      axis.title       = element_text(size = 11, colour = "#2C3E50"),
      axis.text        = element_text(size = 10, colour = "#555555"),
      panel.grid.major = element_line(colour = "#ECEFF1"),
      panel.grid.minor = element_blank(),
      legend.position  = "bottom",
      legend.title     = element_text(size = 10),
      legend.text      = element_text(size = 9),
      plot.background  = element_rect(fill = "#FAFAFA", colour = NA),
      panel.background = element_rect(fill = "#FAFAFA", colour = NA)
    )
}


# =============================================================================
# 1. GENRE ANALYSIS
# =============================================================================

# -----------------------------------------------------------------------------
# plot_games_by_genre(df, metric)
#   Bar chart: count of records OR avg rating per genre, sorted descending.
#   metric: "count" | "avg_rating"
# -----------------------------------------------------------------------------
plot_games_by_genre <- function(df, metric = "count") {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  if (metric == "avg_rating") {
    agg <- df %>%
      group_by(genre) %>%
      summarise(value = round(safe_mean(user_rating), 2),
                n     = n(),
                .groups = "drop") %>%
      arrange(desc(value))
    y_label <- "Average User Rating"
    bar_title <- "Average User Rating by Genre"
  } else {
    agg <- df %>%
      count(genre, name = "value") %>%
      arrange(desc(value))
    y_label <- "Number of Entries"
    bar_title <- "Game Entries by Genre"
  }

  agg$genre <- factor(agg$genre, levels = rev(agg$genre))

  p <- ggplot(agg, aes(x = genre, y = value,
                        fill = genre,
                        text = paste0("<b>", genre, "</b><br>",
                                      y_label, ": ", value))) +
    geom_col(show.legend = FALSE, width = 0.7) +
    scale_fill_manual(values = rep(PALETTE, length.out = nrow(agg))) +
    coord_flip() +
    labs(title = bar_title, x = NULL, y = y_label) +
    theme_gaming()

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# =============================================================================
# 2. PLATFORM ANALYSIS
# =============================================================================

# -----------------------------------------------------------------------------
# plot_platform_distribution(df, metric)
#   Horizontal bar chart: record count OR avg rating per platform.
# -----------------------------------------------------------------------------
plot_platform_distribution <- function(df, metric = "count") {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  if (metric == "avg_rating") {
    agg <- df %>%
      group_by(platform) %>%
      summarise(value = round(safe_mean(user_rating), 2),
                .groups = "drop") %>%
      arrange(desc(value))
    y_label <- "Average User Rating"
    chart_title <- "Average User Rating by Platform"
  } else {
    agg <- df %>%
      count(platform, name = "value") %>%
      arrange(desc(value))
    y_label <- "Number of Entries"
    chart_title <- "Game Entries by Platform"
  }

  agg$platform <- factor(agg$platform, levels = rev(agg$platform))

  p <- ggplot(agg, aes(x = platform, y = value,
                        fill = platform,
                        text = paste0("<b>", platform, "</b><br>",
                                      y_label, ": ", value))) +
    geom_col(show.legend = FALSE, width = 0.65) +
    scale_fill_manual(values = PALETTE[seq_len(nrow(agg))]) +
    coord_flip() +
    labs(title = chart_title, x = NULL, y = y_label) +
    theme_gaming()

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# -----------------------------------------------------------------------------
# plot_platform_pie(df)
#   Donut / pie chart showing platform share.
# -----------------------------------------------------------------------------
plot_platform_pie <- function(df) {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  agg <- df %>% count(platform, name = "count") %>% arrange(desc(count))

  plotly::plot_ly(
    agg,
    labels  = ~platform,
    values  = ~count,
    type    = "pie",
    hole    = 0.4,
    marker  = list(colors = PALETTE[seq_len(nrow(agg))],
                   line   = list(color = "#FFFFFF", width = 2)),
    textinfo      = "label+percent",
    hovertemplate = "<b>%{label}</b><br>Entries: %{value}<br>Share: %{percent}<extra></extra>"
  ) %>%
    plotly::layout(
      title       = list(text = "Platform Share of Game Entries", font = list(size = 14)),
      showlegend  = TRUE,
      paper_bgcolor = "#FAFAFA",
      plot_bgcolor  = "#FAFAFA",
      legend = list(orientation = "h", y = -0.1)
    )
}


# =============================================================================
# 3. RELEASE YEAR TRENDS
# =============================================================================

# -----------------------------------------------------------------------------
# plot_release_trend(df, metric)
#   Line chart over release year.
#   metric: "count" | "avg_rating"
# -----------------------------------------------------------------------------
plot_release_trend <- function(df, metric = "count") {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  if (metric == "avg_rating") {
    agg <- df %>%
      group_by(release_year) %>%
      summarise(value = round(safe_mean(user_rating), 2),
                .groups = "drop") %>%
      arrange(release_year)
    y_label   <- "Average User Rating"
    line_title <- "Average User Rating Over Time"
  } else {
    agg <- df %>%
      count(release_year, name = "value") %>%
      arrange(release_year)
    y_label   <- "Number of Entries"
    line_title <- "Game Entries Released Per Year"
  }

  p <- ggplot(agg, aes(x = release_year, y = value,
                        group = 1,
                        text = paste0("<b>Year: ", release_year, "</b><br>",
                                      y_label, ": ", value))) +
    geom_area(fill = "#4E79A7", alpha = 0.2) +
    geom_line(colour = "#4E79A7", linewidth = 1.1) +
    geom_point(colour = "#4E79A7", size = 2.5) +
    labs(title = line_title, x = "Release Year", y = y_label) +
    scale_x_continuous(breaks = scales::pretty_breaks(n = 8)) +
    theme_gaming()

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# -----------------------------------------------------------------------------
# plot_genre_year_heatmap(df)
#   Heatmap: genre × release year — count of entries.
#   Good for spotting which genres were popular in which eras.
# -----------------------------------------------------------------------------
plot_genre_year_heatmap <- function(df) {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  agg <- df %>%
    count(genre, release_year) %>%
    tidyr::complete(genre, release_year, fill = list(n = 0))

  p <- ggplot(agg, aes(x = release_year, y = genre, fill = n,
                        text = paste0("<b>", genre, " (", release_year, ")</b><br>",
                                      "Entries: ", n))) +
    geom_tile(colour = "white", linewidth = 0.4) +
    scale_fill_gradient(low = "#EFF3FF", high = "#2171B5",
                        name = "Entries") +
    labs(title = "Genre Entries Heatmap by Year",
         x = "Release Year", y = NULL) +
    theme_gaming() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# =============================================================================
# 4. RATING ANALYSIS
# =============================================================================

# -----------------------------------------------------------------------------
# plot_rating_distribution(df)
#   Histogram of user ratings.
# -----------------------------------------------------------------------------
plot_rating_distribution <- function(df) {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  p <- ggplot(df, aes(x = user_rating)) +
    geom_histogram(binwidth = 0.5, fill = "#4E79A7", colour = "white",
                   alpha = 0.85) +
    geom_vline(xintercept = mean(df$user_rating, na.rm = TRUE),
               colour = "#E15759", linetype = "dashed", linewidth = 1) +
    annotate("text",
             x     = mean(df$user_rating, na.rm = TRUE) + 0.15,
             y     = Inf, vjust = 1.5,
             label = paste0("Mean: ", round(mean(df$user_rating, na.rm = TRUE), 2)),
             colour = "#E15759", size = 3.5, hjust = 0) +
    labs(title    = "Distribution of User Ratings",
         subtitle = "Dashed line = mean rating",
         x = "User Rating", y = "Count") +
    theme_gaming()

  plotly::ggplotly(p) %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# -----------------------------------------------------------------------------
# plot_rating_boxplot(df, group_by_col)
#   Boxplot of user ratings grouped by genre or platform.
# -----------------------------------------------------------------------------
plot_rating_boxplot <- function(df, group_by_col = "genre") {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  # Reorder groups by median rating
  df_ordered <- df %>%
    mutate(group_var = .data[[group_by_col]]) %>%
    group_by(group_var) %>%
    mutate(med = median(user_rating, na.rm = TRUE)) %>%
    ungroup() %>%
    mutate(group_var = reorder(group_var, med))

  x_label <- ifelse(group_by_col == "genre", "Genre", "Platform")
  title    <- paste0("User Rating Distribution by ", x_label)

  p <- ggplot(df_ordered, aes(x = group_var, y = user_rating,
                               fill = group_var)) +
    geom_boxplot(alpha = 0.75, outlier.size = 1,
                 outlier.colour = "#E15759", show.legend = FALSE) +
    scale_fill_manual(values = rep(PALETTE, length.out = n_distinct(df_ordered$group_var))) +
    coord_flip() +
    labs(title = title, x = NULL, y = "User Rating") +
    theme_gaming()

  plotly::ggplotly(p) %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# -----------------------------------------------------------------------------
# plot_avg_rating_bar(df, group_by_col)
#   Sorted bar chart of average rating per genre or platform.
# -----------------------------------------------------------------------------
plot_avg_rating_bar <- function(df, group_by_col = "genre") {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  agg <- df %>%
    group_by(across(all_of(group_by_col))) %>%
    summarise(avg_rating = round(safe_mean(user_rating), 2),
              n = n(),
              .groups = "drop") %>%
    arrange(desc(avg_rating))

  colnames(agg)[1] <- "group_var"
  agg$group_var <- factor(agg$group_var, levels = rev(agg$group_var))

  x_label <- ifelse(group_by_col == "genre", "Genre", "Platform")
  title    <- paste0("Average User Rating by ", x_label)

  p <- ggplot(agg, aes(x = group_var, y = avg_rating,
                        fill = group_var,
                        text = paste0("<b>", group_var, "</b><br>",
                                      "Avg Rating: ", avg_rating,
                                      "<br>Entries: ", n))) +
    geom_col(show.legend = FALSE, width = 0.7) +
    scale_fill_manual(values = rep(PALETTE, length.out = nrow(agg))) +
    coord_flip() +
    labs(title = title, x = NULL, y = "Average User Rating") +
    ylim(0, 10) +
    theme_gaming()

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# =============================================================================
# 5. TOP GAMES TABLE (for the Game Explorer chart area)
# =============================================================================

# -----------------------------------------------------------------------------
# plot_top_games(df, top_n)
#   Horizontal bar chart of top-N games by average user rating.
#   Only includes games with >= 2 entries for statistical reliability.
# -----------------------------------------------------------------------------
plot_top_games <- function(df, top_n = 15) {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  agg <- df %>%
    group_by(game_name) %>%
    summarise(avg_rating = round(safe_mean(user_rating), 2),
              entries    = n(),
              .groups    = "drop") %>%
    filter(entries >= 2) %>%
    arrange(desc(avg_rating)) %>%
    slice_head(n = top_n)

  if (nrow(agg) == 0) return(plotly::ggplotly(no_data_plot("Not enough data for top games chart.")))

  agg$game_name <- factor(agg$game_name, levels = rev(agg$game_name))

  p <- ggplot(agg, aes(x = game_name, y = avg_rating,
                        fill = avg_rating,
                        text = paste0("<b>", game_name, "</b><br>",
                                      "Avg Rating: ", avg_rating,
                                      "<br>Entries: ", entries))) +
    geom_col(show.legend = FALSE, width = 0.7) +
    scale_fill_gradient(low = "#AED6F1", high = "#1A5276") +
    coord_flip() +
    labs(title = paste0("Top ", top_n, " Games by Average User Rating"),
         subtitle = "Minimum 2 entries required",
         x = NULL, y = "Average User Rating") +
    ylim(0, 10) +
    theme_gaming()

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# =============================================================================
# 6. CROSS-PLATFORM GENRE COMPARISON
# =============================================================================

# -----------------------------------------------------------------------------
# plot_genre_platform_heatmap(df)
#   Heatmap: genre × platform — avg user rating.
# -----------------------------------------------------------------------------
plot_genre_platform_heatmap <- function(df) {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  agg <- df %>%
    group_by(genre, platform) %>%
    summarise(avg_rating = round(safe_mean(user_rating), 2),
              n          = n(),
              .groups    = "drop")

  p <- ggplot(agg, aes(x = platform, y = genre, fill = avg_rating,
                        text = paste0("<b>", genre, " on ", platform, "</b><br>",
                                      "Avg Rating: ", avg_rating,
                                      "<br>Entries: ", n))) +
    geom_tile(colour = "white", linewidth = 0.5) +
    scale_fill_gradient2(low = "#D6EAF8", mid = "#5DADE2",
                         high = "#1A5276", midpoint = 5,
                         name = "Avg\nRating") +
    labs(title = "Average User Rating: Genre × Platform",
         x = "Platform", y = "Genre") +
    theme_gaming() +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}


# =============================================================================
# 7. RATING BUCKET (stacked bar — % of ratings in each bucket per genre)
# =============================================================================

plot_rating_bucket_bar <- function(df) {

  if (nrow(df) == 0) return(plotly::ggplotly(no_data_plot()))

  agg <- df %>%
    group_by(genre, rating_bucket) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(genre) %>%
    mutate(pct = round(100 * n / sum(n), 1)) %>%
    ungroup()

  bucket_colors <- c("0–2"  = "#E74C3C",
                     "2–4"  = "#E67E22",
                     "4–6"  = "#F1C40F",
                     "6–8"  = "#2ECC71",
                     "8–10" = "#27AE60")

  p <- ggplot(agg, aes(x = genre, y = pct, fill = rating_bucket,
                        text = paste0("<b>", genre, "</b><br>",
                                      "Bucket: ", rating_bucket,
                                      "<br>Share: ", pct, "%"))) +
    geom_col(position = "stack", width = 0.75) +
    scale_fill_manual(values = bucket_colors, name = "Rating Bucket") +
    coord_flip() +
    labs(title = "Rating Distribution (%) by Genre",
         x = NULL, y = "Percentage (%)") +
    theme_gaming()

  plotly::ggplotly(p, tooltip = "text") %>%
    plotly::layout(hoverlabel = list(bgcolor = "white"))
}
