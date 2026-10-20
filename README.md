# Gaming Analytics Dashboard — R/Shiny

> **MCA Data Science Mini Project**

---

## Project Title
**Gaming Analytics Dashboard Using R**

---

## Objective

Build an interactive Shiny dashboard that performs end-to-end Exploratory
Data Analysis (EDA) on a video-games dataset, covering:

- Data loading, cleaning, and preprocessing
- KPI computation
- Genre, platform, and rating analysis
- Release-year trend analysis
- Interactive visualisation using Plotly and ggplot2
- A searchable, downloadable data table

---

## Dataset

| Property | Detail |
|---|---|
| File | `games_dataset.csv` |
| Source | Provided for the mini project |
| Rows | ~3,000+ |
| Columns | 5 |

### Column descriptions

| Column | Type | Description |
|---|---|---|
| `Game Name` | character | Title of the video game |
| `Genre` | character | Genre (Action, Adventure, Puzzle, etc.) |
| `Platform` | character | Platform (PC, PlayStation, Xbox, Nintendo Switch, Mobile) |
| `Release Year` | integer | Year the game was released (2000 – 2023) |
| `User Rating` | numeric | User rating on a 0 – 10 scale |

No publisher, developer, or sales columns are present in this dataset.

---

## Technologies Used

| Package | Purpose |
|---|---|
| `shiny` | Core reactive web framework |
| `shinydashboard` | Dashboard layout (AdminLTE) |
| `tidyverse` (dplyr, ggplot2, tidyr, readr, scales) | Data wrangling & base charts |
| `plotly` | Interactive chart wrappers |
| `DT` | Interactive data tables |

---

## Project Structure

```
gaming-dashboard/
│
├── app.R                   ← Main Shiny application (UI + Server)
├── games_dataset.csv       ← Dataset (copy here before running)
│
├── R/
│   ├── data_processing.R   ← Load, clean, filter functions
│   ├── helpers.R           ← KPI, insight, formatting utilities
│   ├── plots.R             ← All Plotly / ggplot2 chart functions
│   └── ui_components.R     ← Reusable UI building blocks
│
├── www/
│   └── styles.css          ← Custom CSS styling
│
└── README.md               ← This file
```

---

## Dashboard Features

### 1. Sidebar Filters
- Filter by **Genre** (checkbox group)
- Filter by **Platform** (checkbox group)
- Filter by **Release Year** (range slider)
- Filter by **User Rating** (range slider)
- **Reset All Filters** button

All filters apply globally across every tab and chart.

### 2. Overview Tab
- 6 KPI cards: Total Entries, Unique Games, Genres, Platforms, Avg Rating, Top Genre
- Genre bar chart (count or avg rating)
- Platform pie / donut chart
- Year trend line chart

### 3. Game Trends Tab
- Line chart: entries or avg rating over release year
- Genre × Year heatmap (which genres were popular when)

### 4. Genre & Platform Tab
- Genre bar chart
- Platform bar chart
- Genre × Platform heatmap (avg rating)

### 5. Ratings Tab
- Rating histogram with mean line
- Rating bucket (0–2, 2–4, … 8–10) stacked bar by genre
- Boxplot grouped by genre or platform
- Average rating bar grouped by genre or platform

### 6. Game Explorer Tab
- Top-N games bar chart (adjustable 5–30)
- Full filterable, sortable, paginated DT table with CSV/Excel export

### 7. Key Insights Tab
- Automatically generated plain-language insights from the filtered data
- Filter summary panel

---

## Data Preprocessing

Implemented in `R/data_processing.R`:

1. **Read CSV** using `readr::read_csv` with explicit column types.
2. **Rename columns** — spaces replaced with underscores (e.g. `game_name`).
3. **Trim whitespace** from all character columns.
4. **Standardise capitalisation** — `str_to_title` applied to `genre` and `platform`.
5. **Remove NA rows** — rows with any missing value are dropped (decision: a record is
   useless for analysis if any key field is absent).
6. **Remove exact duplicates** — `distinct()`.
7. **Validate Release Year** — keep rows where year is between 1970 and the current year.
8. **Validate User Rating** — keep rows where rating is between 0 and 10.
9. **Add derived columns**:
   - `rating_bucket` — categorical bucket (0–2, 2–4, 4–6, 6–8, 8–10)
   - `decade` — "2000s", "2010s", "2020s" etc.

---

## Visualisations

| Chart | Tab | Description |
|---|---|---|
| Genre bar chart | Overview, Genre & Platform | Entries or avg rating per genre |
| Platform pie chart | Overview | Share of records per platform |
| Release trend line | Overview, Trends | Entries or avg rating per year |
| Genre × Year heatmap | Trends | Entry count for each genre-year combo |
| Platform bar chart | Genre & Platform | Entries or avg rating per platform |
| Genre × Platform heatmap | Genre & Platform | Avg rating matrix |
| Rating histogram | Ratings | Distribution of user ratings |
| Rating bucket bar | Ratings | % of each rating range per genre |
| Rating boxplot | Ratings | Spread of ratings by genre or platform |
| Avg rating bar | Ratings | Mean rating by genre or platform |
| Top-N games bar | Game Explorer | Highest avg-rated games (min 2 entries) |
| DT data table | Game Explorer | Full interactive table with export |

---

## How to Run

### Step 1 — Install required packages

Open RStudio and run:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "readr",
  "dplyr",
  "tidyr",
  "stringr",
  "scales",
  "ggplot2",
  "plotly",
  "DT"
))
```

> **Note:** These packages are also auto-installed when `app.R` first runs,
> so this step is optional. If you have `tidyverse` already installed, all
> `readr`, `dplyr`, `tidyr`, `stringr`, `ggplot2`, and `scales` packages
> are already present.

### Step 2 — Place the dataset

Copy `games_dataset.csv` into the `gaming-dashboard/` folder
(the same folder that contains `app.R`).

### Step 3 — Launch the app

Option A — from RStudio:

```
Open gaming-dashboard/app.R → click "Run App"
```

Option B — from the R console:

```r
setwd("path/to/gaming-dashboard")
shiny::runApp()
```

Option C — from anywhere:

```r
shiny::runApp("path/to/gaming-dashboard")
```

---

## Error Handling

- If the filtered dataset is empty, all charts display a friendly
  *"No data matches the selected filters."* message instead of crashing.
- If the CSV is missing, `app.R` stops with a clear path error message.
- All KPI cards gracefully show `"—"` when there is no data to compute.
- The DT table shows a descriptive row when empty.

---

## Key Code Concepts for Understanding

### Reactivity
`filtered_df <- reactive({...})` creates a reactive expression.
Every output that calls `filtered_df()` automatically re-runs when any
sidebar input changes.

### `observeEvent`
Used for the Reset button to programmatically update all filter inputs.

### Modular structure
Logic is separated into four R scripts loaded via `source()`:
- Data concerns → `data_processing.R`
- UI helpers → `ui_components.R`
- Charts → `plots.R`
- Utilities → `helpers.R`

### Plotly interactivity
`plotly::ggplotly(p, tooltip = "text")` converts a static ggplot into an
interactive chart. The `text` aesthetic in `aes()` controls the tooltip.

---

## Suggested Viva Questions

1. **What are the columns in your dataset, and what are their data types?**
   *Answer: game_name (chr), genre (chr), platform (chr), release_year (int), user_rating (num).*

2. **How did you handle missing values in the dataset?**
   *Answer: Used `complete.cases()` to detect and drop rows with any NA.*

3. **What is a Shiny reactive expression and why is it used here?**
   *Answer: `reactive({})` caches a computed value that automatically re-evaluates when its inputs change, avoiding redundant recalculations.*

4. **What is the difference between `renderPlot` and `renderPlotly`?**
   *Answer: `renderPlot` renders a static ggplot image; `renderPlotly` renders an interactive HTML widget.*

5. **How do the sidebar filters affect every chart simultaneously?**
   *Answer: All outputs consume `filtered_df()`, which is a single reactive expression driven by all filter inputs.*

6. **What does `observeEvent(input$btn_reset, {...})` do?**
   *Answer: It watches the reset button click and calls `updateXInput()` functions to restore all filter defaults.*

7. **Why did you use `plotly::ggplotly()` instead of `plotly::plot_ly()` for most charts?**
   *Answer: ggplot2 offers more concise grammar for complex charts; `ggplotly()` converts them to interactive widgets with minimal extra code.*

8. **What is the purpose of `shinydashboard::valueBox`?**
   *Answer: Displays a KPI metric with an icon and colour in a compact card widget.*

9. **How did you add a custom tooltip to Plotly charts?**
   *Answer: By adding a `text` aesthetic in `aes()` and passing `tooltip = "text"` to `ggplotly()`.*

10. **What is the role of `www/styles.css` in a Shiny app?**
    *Answer: Shiny serves all files in `www/` as static assets; CSS loaded via `tags$link()` in the UI overrides default AdminLTE styles.*

11. **Explain the `cut()` function used for `rating_bucket`.**
    *Answer: `cut()` divides a numeric vector into intervals and labels each value with its interval name, creating an ordered factor.*

12. **What would happen if a user selects 0 genres in the sidebar?**
    *Answer: `filtered_df()` returns 0 rows. Every chart calls `no_data_plot()` and the DT table shows an explanatory message — the app does not crash.*

13. **What does `DT::formatStyle(...styleColorBar...)` do in the table?**
    *Answer: It adds a proportional blue bar inside each cell of the "User Rating" column to give a visual magnitude cue.*

14. **Why was `str_to_title()` applied to genre and platform?**
    *Answer: To normalise inconsistent casing (e.g. "action" vs "Action") so that filter comparisons and chart labels are consistent.*

15. **What is the difference between `n_distinct()` and `length(unique())`?**
    *Answer: Both return the count of unique values; `n_distinct()` is the tidyverse/dplyr version, handles NA consistently, and works inside `summarise()`.*
