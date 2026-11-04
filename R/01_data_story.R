# =============================================================================
# Australian road fatalities: a data story
# Satish Kumar Reddy Gajjala, Master of Data Science, University of Adelaide
#
# Reads the BITRE Australian Road Deaths Database (ARDD) fatalities file and
# builds ten graphics, each answering one question and raising the next:
#   trend -> where -> who -> when -> day x time -> season -> crash type ->
#   age x gender -> age x speed -> speed zone risk
#
# Output: figures/g01_*.png ... figures/g10_*.png, two interactive HTML charts,
#         and figures/findings.md with every number quoted in the README.
#
# Run from the project root (open australian-road-fatalities.Rproj first):
#   source("R/01_data_story.R")
# =============================================================================

# ---- 0. Setup ---------------------------------------------------------------
packages <- c("readxl", "dplyr", "tidyr", "ggplot2", "forcats", "scales",
              "stringr", "plotly", "htmlwidgets")
missing <- packages[!packages %in% rownames(installed.packages())]
if (length(missing)) install.packages(missing, type = "binary")
invisible(lapply(packages, library, character.only = TRUE))

DATA_FILE  <- list.files("data", pattern = "^bitre_fatalities.*\\.xlsx$", full.names = TRUE)[1]
FIG        <- "figures"
TREND_FROM <- 2000          # first year shown on the trend chart
LAST_FULL  <- 2025          # last complete calendar year in the release
SOURCE     <- "Source: BITRE Australian Road Deaths Database (ARDD)"
dir.create(FIG, showWarnings = FALSE)
if (is.na(DATA_FILE)) stop("Put the BITRE fatalities .xlsx in data/ (see data/README.md).")

# One palette for the whole story, so the same thing is always the same colour
ACCENT <- "#b2182b"   # the group or period being called out
BASE   <- "#2c3e50"   # everything else
MUTED  <- "#bdc3c7"
ROAD_USER_COLS <- c("Driver" = "#2c3e50", "Passenger" = "#3498db",
                    "Pedestrian" = "#b2182b", "Motorcycle rider" = "#e67e22",
                    "Pedal cyclist" = "#27ae60", "Motorcycle pillion passenger" = "#f5b041")

theme_story <- function(base = 13) {
  theme_minimal(base_size = base) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(colour = "grey30"),
          plot.caption = element_text(colour = "grey50", size = 9, hjust = 0),
          plot.title.position = "plot", plot.caption.position = "plot",
          panel.grid.minor = element_blank(), legend.position = "bottom",
          legend.key.width = unit(3, "lines"))
}
save_plot <- function(name, w = 11, h = 6.5) ggsave(file.path(FIG, name), width = w, height = h, dpi = 300, bg = "white")

# ---- 1. Load and clean --------------------------------------------------------
# Header sits on row 5 of the BITRE file. -9 and "Unknown" mean missing.
raw <- read_excel(DATA_FILE, skip = 4)

ardd <- raw %>%
  mutate(across(where(is.character), ~ na_if(na_if(str_trim(.x), "Unknown"), "-9")),
         across(where(is.numeric), ~ na_if(.x, -9)),
         Month = as.integer(Month),
         Year  = as.integer(Year),
         Age   = as.numeric(Age),
         `Speed Limit` = suppressWarnings(as.numeric(`Speed Limit`)),
         Hour  = suppressWarnings(as.integer(substr(as.character(Time), 1, 2))),
         Time_Category = cut(Hour, breaks = c(-1, 5, 11, 17, 23),
                             labels = c("Night (0-6)", "Morning (6-12)", "Afternoon (12-18)", "Evening (18-24)")),
         Season = case_when(Month %in% c(12, 1, 2) ~ "Summer",
                            Month %in% 3:5 ~ "Autumn",
                            Month %in% 6:8 ~ "Winter",
                            Month %in% 9:11 ~ "Spring"),
         Season  = factor(Season, levels = c("Summer", "Autumn", "Winter", "Spring")),
         Dayweek = factor(Dayweek, levels = c("Monday", "Tuesday", "Wednesday", "Thursday",
                                              "Friday", "Saturday", "Sunday")))

findings <- c(sprintf("# Findings (generated from %s)", basename(DATA_FILE)), "",
              sprintf("- Records: %s fatalities, %d to %d", comma(nrow(ardd)), min(ardd$Year, na.rm = TRUE), max(ardd$Year, na.rm = TRUE)))
note <- function(...) findings <<- c(findings, paste0("- ", sprintf(...)))

# ---- G1. Trend: are road deaths falling? --------------------------------------
g1 <- ardd %>% filter(between(Year, TREND_FROM, LAST_FULL)) %>% count(Year)
low  <- g1 %>% slice_min(n, n = 1, with_ties = FALSE)
last <- g1 %>% filter(Year == LAST_FULL)
note("G1: %s deaths in %d vs %s in %d; lowest year %d (%s)", comma(g1$n[1]), g1$Year[1],
     comma(last$n), LAST_FULL, low$Year, comma(low$n))

p1 <- ggplot(g1, aes(Year, n)) +
  geom_line(colour = BASE, linewidth = 1) +
  geom_point(data = low, colour = ACCENT, size = 3) +
  geom_point(data = last, colour = ACCENT, size = 3) +
  geom_text(data = last, aes(label = comma(n)), vjust = -1, colour = ACCENT, fontface = "bold") +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Are road deaths in Australia still falling?",
       subtitle = sprintf("Fatalities per year, Australia, %d-%d", TREND_FROM, LAST_FULL),
       x = NULL, y = "Fatalities", caption = SOURCE) +
  theme_story()
p1; save_plot("g01_trend.png")
saveWidget(ggplotly(p1), file.path(FIG, "g01_trend_interactive.html"), selfcontained = FALSE, libdir = "lib")

# ---- G2. Where: which states? ---------------------------------------------------
g2 <- ardd %>% filter(!is.na(State)) %>% count(State) %>% mutate(share = n / sum(n))
note("G2: %s has the most deaths (%s, %s of the total)", g2$State[which.max(g2$n)],
     comma(max(g2$n)), percent(max(g2$share), 0.1))
ggplot(g2, aes(fct_reorder(State, n), n, fill = State == "SA")) +
  geom_col(width = 0.7) +
  geom_text(aes(label = comma(n)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  scale_fill_manual(values = c(`TRUE` = ACCENT, `FALSE` = BASE), guide = "none") +
  scale_y_continuous(labels = comma, expand = expansion(c(0, 0.12))) +
  labs(title = "Which states record the most road deaths?",
       subtitle = "Raw counts largely follow population. South Australia highlighted.",
       x = NULL, y = "Fatalities, all years", caption = SOURCE) +
  theme_story()
save_plot("g02_state.png", h = 5.5)

# ---- G3. Who: which road users? -------------------------------------------------
g3 <- ardd %>% filter(!is.na(`Road User`), `Road User` != "Other/-9") %>% count(`Road User`) %>% mutate(share = n / sum(n))
vuln <- g3 %>% filter(`Road User` %in% c("Pedestrian", "Motorcycle rider", "Pedal cyclist", "Motorcycle pillion passenger"))
note("G3: drivers %s of deaths; pedestrians, riders and cyclists together %s",
     percent(g3$share[g3$`Road User` == "Driver"], 0.1), percent(sum(vuln$share), 0.1))
ggplot(g3, aes(fct_reorder(`Road User`, n), n, fill = `Road User`)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = percent(share, 0.1)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  scale_fill_manual(values = ROAD_USER_COLS, guide = "none") +
  scale_y_continuous(labels = comma, expand = expansion(c(0, 0.12))) +
  labs(title = sprintf("Vulnerable road users make up %s of deaths", percent(sum(vuln$share), 1)),
       x = NULL, y = "Fatalities", caption = SOURCE) +
  theme_story()
save_plot("g03_road_user.png", h = 5.5)

# ---- G4. When: time of day ------------------------------------------------------
g4 <- ardd %>% filter(!is.na(Time_Category)) %>% count(Time_Category) %>% mutate(share = n / sum(n))
note("G4: %s is the deadliest period (%s of deaths)", g4$Time_Category[which.max(g4$n)], percent(max(g4$share), 0.1))
ggplot(g4, aes(Time_Category, n, fill = n == max(n))) +
  geom_col(width = 0.65) +
  geom_text(aes(label = percent(share, 0.1)), vjust = -0.5) +
  scale_fill_manual(values = c(`TRUE` = ACCENT, `FALSE` = BASE), guide = "none") +
  scale_y_continuous(labels = comma, expand = expansion(c(0, 0.1))) +
  labs(title = sprintf("%s is the deadliest part of the day", g4$Time_Category[which.max(g4$n)]), subtitle = "Share of fatalities in each six-hour period",
       x = NULL, y = "Fatalities", caption = SOURCE) +
  theme_story()
save_plot("g04_time_of_day.png", h = 5.5)

# ---- G5. Day x time hotspots ----------------------------------------------------
g5 <- ardd %>% filter(!is.na(Dayweek), !is.na(Time_Category)) %>% count(Dayweek, Time_Category)
hot <- g5 %>% slice_max(n, n = 1, with_ties = FALSE)
note("G5: hottest day-time cell is %s %s (%s deaths)", hot$Dayweek, hot$Time_Category, comma(hot$n))
p5 <- ggplot(g5, aes(Dayweek, fct_rev(Time_Category), fill = n)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = comma(n)), size = 3.3, colour = ifelse(g5$n > median(g5$n), "white", "black")) +
  scale_fill_gradient(low = "#fde0dd", high = ACCENT, labels = comma, name = "Fatalities") +
  labs(title = sprintf("The riskiest slot is %s %s", hot$Dayweek, tolower(hot$Time_Category)),
       x = NULL, y = NULL, caption = SOURCE) +
  theme_story() + theme(panel.grid = element_blank())
p5; save_plot("g05_day_time_heatmap.png", h = 5)
saveWidget(ggplotly(p5), file.path(FIG, "g05_heatmap_interactive.html"), selfcontained = FALSE, libdir = "lib")

# ---- G6. Does it change by season? -------------------------------------------------
g6 <- ardd %>% filter(!is.na(Dayweek), !is.na(Time_Category), !is.na(Season)) %>% count(Season, Dayweek, Time_Category)
ggplot(g6, aes(Dayweek, fct_rev(Time_Category), fill = n)) +
  geom_tile(colour = "white") +
  facet_wrap(~ Season) +
  scale_fill_gradient(low = "#fde0dd", high = ACCENT, labels = comma, name = "Fatalities") +
  scale_x_discrete(labels = function(x) substr(x, 1, 3)) +
  labs(title = "Does the weekly pattern change with the season?",
       subtitle = "Same scale across panels, so colour is comparable",
       x = NULL, y = NULL, caption = SOURCE) +
  theme_story(12) + theme(panel.grid = element_blank())
save_plot("g06_season_heatmap.png", h = 7)

# ---- G7. How: single vs multiple vehicle crashes by time ----------------------------
g7 <- ardd %>% filter(!is.na(Time_Category), !is.na(`Crash Type`)) %>%
  count(Time_Category, `Crash Type`) %>% group_by(Time_Category) %>% mutate(share = n / sum(n)) %>% ungroup()
night_single <- g7 %>% filter(Time_Category == "Night (0-6)", `Crash Type` == "Single")
note("G7: single-vehicle crashes are %s of night deaths", percent(night_single$share, 0.1))
ggplot(g7, aes(Time_Category, share, fill = `Crash Type`)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = percent(share, 1)), position = position_stack(vjust = 0.5), colour = "white", fontface = "bold") +
  scale_fill_manual(values = c(Single = ACCENT, Multiple = BASE)) +
  scale_y_continuous(labels = percent) +
  labs(title = sprintf("At night, %s of deaths involve a single vehicle", percent(night_single$share, 1)),
       subtitle = "Share of fatalities by crash type within each period",
       x = NULL, y = NULL, fill = "Crash type", caption = SOURCE) +
  theme_story()
save_plot("g07_crash_type.png", h = 5.5)

# ---- G8. Who, in more detail: age and gender ---------------------------------------
g8 <- ardd %>% filter(!is.na(Age), Gender %in% c("Male", "Female"))
male_share <- mean(g8$Gender == "Male")
note("G8: %s of fatalities are male; median age male %s, female %s", percent(male_share, 0.1),
     median(g8$Age[g8$Gender == "Male"]), median(g8$Age[g8$Gender == "Female"]))
ggplot(g8, aes(Gender, Age, fill = Gender)) +
  geom_boxplot(notch = TRUE, outlier.alpha = 0.15, width = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white") +
  scale_fill_manual(values = c(Male = BASE, Female = MUTED), guide = "none") +
  labs(title = sprintf("%s of road deaths are male", percent(male_share, 1)),
       subtitle = "Diamond = mean age. Notch = 95% confidence interval around the median.",
       x = NULL, y = "Age", caption = SOURCE) +
  theme_story()
save_plot("g08_age_gender.png", w = 9, h = 6)

# ---- G9. Age x speed zone, by road user ---------------------------------------------
set.seed(42)
g9 <- ardd %>%
  filter(!is.na(Age), `Speed Limit` %in% c(40, 50, 60, 80, 100, 110),
         `Road User` %in% c("Driver", "Passenger", "Pedestrian", "Motorcycle rider")) %>%
  slice_sample(n = 4000)
ggplot(g9, aes(Age, factor(`Speed Limit`), colour = `Road User`)) +
  geom_jitter(alpha = 0.45, width = 1.5, height = 0.25, size = 1.1) +
  facet_wrap(~ `Road User`, nrow = 2) +
  scale_colour_manual(values = ROAD_USER_COLS, guide = "none") +
  labs(title = "How do age and speed zone differ by road user?",
       subtitle = "Random sample of 4,000 fatalities, jittered so overlapping points show",
       x = "Age", y = "Speed limit (km/h)", caption = SOURCE) +
  theme_story(12) + theme(strip.text = element_text(face = "bold"))
save_plot("g09_age_speed.png", h = 7)

# ---- G10. Where age and speed combine --------------------------------------------
g10 <- ardd %>%
  filter(!is.na(Age), `Speed Limit` %in% c(40, 50, 60, 80, 100, 110)) %>%
  mutate(Age_Band = cut(Age, c(-1, 16, 25, 39, 64, 120), labels = c("0-16", "17-25", "26-39", "40-64", "65+"))) %>%
  count(Age_Band, `Speed Limit`)
top10 <- g10 %>% slice_max(n, n = 1, with_ties = FALSE)
note("G10: biggest age-speed cluster is age %s at %s km/h (%s deaths)", top10$Age_Band, top10$`Speed Limit`, comma(top10$n))
ggplot(g10, aes(factor(`Speed Limit`), Age_Band, size = n, colour = n)) +
  geom_point(alpha = 0.85) +
  scale_size_area(max_size = 18, labels = comma, name = "Fatalities") +
  scale_colour_gradient(low = MUTED, high = ACCENT, guide = "none") +
  labs(title = sprintf("The largest cluster: age %s on %s km/h roads", top10$Age_Band, top10$`Speed Limit`),
       subtitle = "Bubble area = number of fatalities",
       x = "Speed limit (km/h)", y = "Age band", caption = SOURCE) +
  theme_story()
save_plot("g10_age_speed_bubble.png", h = 6)

# ---- Write findings ----------------------------------------------------------------
writeLines(findings, file.path(FIG, "findings.md"))
cat(findings, sep = "\n")
message("Done. Charts and findings.md are in ", FIG, "/")
