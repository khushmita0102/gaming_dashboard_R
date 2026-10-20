# create_dataset.R
# Run this script ONCE to recreate games_dataset.csv from scratch.
# It generates synthetic data matching the exact structure of the original
# attachment (Game Name, Genre, Platform, Release Year, User Rating).
# This is only needed if you do not have the original CSV file.

set.seed(42)

game_names <- c(
  "Sekiro: Shadows Die Twice","Control","Among Us","Call of Duty: Modern Warfare",
  "League of Legends","Counter-Strike: Global Offensive","Red Dead Redemption 2",
  "Halo Infinite","The Legend of Zelda: Breath of the Wild","Valorant",
  "Super Mario Odyssey","Apex Legends","Grand Theft Auto IV","Overwatch",
  "FIFA 21","Tetris","God of War","Genshin Impact","Hades","Ghost of Tsushima",
  "Hitman 3","Cyberpunk 2077","The Witcher 3: Wild Hunt","Resident Evil Village",
  "Death Stranding","Mass Effect Legendary Edition","The Division 2","PUBG Mobile",
  "The Sims 4","Grand Theft Auto V","Sea of Thieves","The Elder Scrolls V: Skyrim",
  "Rocket League","PUBG","The Witcher 3: Wild Hunt","Dota 2","Dark Souls III",
  "Minecraft","Minecraft Dungeons","Horizon Zero Dawn","Fortnite","NBA 2K21",
  "Monster Hunter: World","Borderlands 3","Dying Light","Watch Dogs: Legion",
  "Elden Ring","Assassin's Creed Valhalla","Far Cry 5","Destiny 2",
  "Forza Horizon 4","Madden NFL 21","GTA San Andreas","World of Warcraft",
  "Fall Guys: Ultimate Knockout","PUBG: Battlegrounds","Halo Master Chief Collection",
  "League of Legends: Wild Rift","Cyberpunk 2077"
)

genres <- c("Action","Adventure","Puzzle","Racing","Horror","Shooter","Sports",
            "Stealth","Strategy","Simulation","Role-playing","Platformer",
            "Fighting","Survival")

platforms <- c("PC","PlayStation","Xbox","Nintendo Switch","Mobile")

years <- 2000:2023

n <- 3000

df <- data.frame(
  `Game Name`    = sample(game_names, n, replace = TRUE),
  Genre          = sample(genres,     n, replace = TRUE),
  Platform       = sample(platforms,  n, replace = TRUE),
  `Release Year` = sample(years,      n, replace = TRUE),
  `User Rating`  = round(runif(n, 1.0, 9.99), 2),
  check.names    = FALSE
)

write.csv(df, "games_dataset.csv", row.names = FALSE)
cat("games_dataset.csv created with", nrow(df), "rows.\n")
