# =============================================================================
# data_processing.R
# Purpose : Load, inspect, clean, and preprocess games_dataset.csv
# Dataset : 5 columns — Game Name, Genre, Platform, Release Year, User Rating
# =============================================================================

# Auto-install any missing packages before loading them
.pkgs <- c("readr", "dplyr", "stringr")
for (.p in .pkgs) {
  if (!requireNamespace(.p, quietly = TRUE)) install.packages(.p, quiet = TRUE)
  library(.p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
}
rm(.pkgs, .p)

# -----------------------------------------------------------------------------
# load_and_clean_data()
#   Reads the CSV, applies all cleaning steps, and returns a tidy data frame.
#   Called once at app start-up.
# -----------------------------------------------------------------------------
load_and_clean_data <- function(path = "games_dataset.csv") {

  # ── 1. Read CSV ─────────────────────────────────────────────────────────────
  raw <- readr::read_csv(
    path,
    col_types = cols(
      `Game Name`    = col_character(),
      Genre          = col_character(),
      Platform       = col_character(),
      `Release Year` = col_double(),   # read as double first for safety
      `User Rating`  = col_double()
    ),
    show_col_types = FALSE
  )

  # ── 2. Rename columns to safe R names ────────────────────────────────────────
  # Spaces and special characters in column names cause bugs in Shiny reactives.
  df <- raw %>%
    rename(
      game_name    = `Game Name`,
      genre        = Genre,
      platform     = Platform,
      release_year = `Release Year`,
      user_rating  = `User Rating`
    )

  # ── 3. Trim whitespace from all character columns ────────────────────────────
  df <- df %>%
    mutate(across(where(is.character), str_trim))

  # ── 4. Standardise capitalisation of categorical columns ─────────────────────
  # Use str_to_title to avoid mismatches like "action" vs "Action".
  df <- df %>%
    mutate(
      genre    = str_to_title(genre),
      platform = str_to_title(platform)
    )

  # ── 5. Remove rows with NA in any column ─────────────────────────────────────
  # Decision: a record with no game name, genre, platform, year, or rating
  # cannot contribute meaningfully to any chart, so it is dropped.
  rows_before <- nrow(df)
  df <- df %>% filter(complete.cases(.))
  rows_after  <- nrow(df)
  message(sprintf("[data_processing] Dropped %d rows with missing values (%d → %d).",
                  rows_before - rows_after, rows_before, rows_after))

  # ── 6. Remove exact duplicate rows ───────────────────────────────────────────
  dupes <- nrow(df) - nrow(distinct(df))
  df    <- distinct(df)
  message(sprintf("[data_processing] Removed %d exact duplicate rows.", dupes))

  # ── 7. Validate Release Year ─────────────────────────────────────────────────
  # Keep only years that are plausible for modern video games (1970–current year).
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  df <- df %>%
    filter(release_year >= 1970, release_year <= current_year) %>%
    mutate(release_year = as.integer(release_year))

  # ── 8. Validate User Rating ───────────────────────────────────────────────────
  # Ratings outside [0, 10] are considered data entry errors and removed.
  df <- df %>%
    filter(user_rating >= 0, user_rating <= 10)

  # ── 9. Add derived / helper columns ──────────────────────────────────────────
  df <- df %>%
    mutate(
      # Rating bucket — used in histogram & filter
      rating_bucket = cut(
        user_rating,
        breaks = c(0, 2, 4, 6, 8, 10),
        labels = c("0–2", "2–4", "4–6", "6–8", "8–10"),
        include.lowest = TRUE,
        right = TRUE
      ),
      # Decade column — useful for coarser trend analysis
      decade = paste0(floor(release_year / 10) * 10, "s")
    )

  message(sprintf("[data_processing] Final clean dataset: %d rows, %d columns.",
                  nrow(df), ncol(df)))

  return(df)
}


# -----------------------------------------------------------------------------
# get_filter_choices(df)
#   Returns a named list of unique values for every sidebar filter widget.
#   Called once after load_and_clean_data().
# -----------------------------------------------------------------------------
get_filter_choices <- function(df) {
  list(
    genres       = sort(unique(df$genre)),
    platforms    = sort(unique(df$platform)),
    years        = sort(unique(df$release_year)),
    year_min     = min(df$release_year, na.rm = TRUE),
    year_max     = max(df$release_year, na.rm = TRUE),
    rating_min   = floor(min(df$user_rating, na.rm = TRUE)),
    rating_max   = ceiling(max(df$user_rating, na.rm = TRUE))
  )
}


# -----------------------------------------------------------------------------
# apply_filters(df, genres, platforms, year_range, rating_range)
#   Subsets the master data frame according to sidebar selections.
#   Returns the filtered data frame (possibly 0 rows — handled in server).
# -----------------------------------------------------------------------------
apply_filters <- function(df,
                          genres       = NULL,
                          platforms    = NULL,
                          year_range   = NULL,
                          rating_range = NULL) {

  out <- df

  # NULL means the input widget returned nothing (all unchecked).
  # Treat as "show nothing" for genre and platform filters.
  if (is.null(genres) || length(genres) == 0) return(out[0, ])
  out <- out %>% filter(genre %in% genres)

  if (is.null(platforms) || length(platforms) == 0) return(out[0, ])
  out <- out %>% filter(platform %in% platforms)

  if (!is.null(year_range) && length(year_range) == 2) {
    out <- out %>%
      filter(release_year >= year_range[1],
             release_year <= year_range[2])
  }

  if (!is.null(rating_range) && length(rating_range) == 2) {
    out <- out %>%
      filter(user_rating >= rating_range[1],
             user_rating <= rating_range[2])
  }

  return(out)
}
