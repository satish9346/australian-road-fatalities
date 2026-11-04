# Australian road fatalities: a data story

**When, where and to whom do road deaths happen in Australia, and what does that say about where prevention should focus?**

Ten linked graphics built in R from the national road deaths database. Each chart answers one question and raises the next, moving from the national trend down to the people, times and road environments most at risk.

R · tidyverse · ggplot2 · plotly · Data visualisation and storytelling

---

## The story in ten graphics

| # | Question | Chart | Leads to |
|---|---|---|---|
| G1 | Are road deaths still falling? | Line, yearly trend | Where do they happen? |
| G2 | Which states record the most deaths? | Bar | Who is dying? |
| G3 | Which road users are most affected? | Bar | When do deaths happen? |
| G4 | Which time of day is deadliest? | Bar | Which day-and-time combinations? |
| G5 | Which day and time combinations are riskiest? | Heatmap | Does this change by season? |
| G6 | Does the weekly pattern change with the season? | Faceted heatmap | How do these crashes happen? |
| G7 | Single or multiple vehicles, by time of day? | 100% stacked bar | Who, in more detail? |
| G8 | How do age and gender differ? | Notched boxplot | Does the road environment matter? |
| G9 | How do age and speed zone differ by road user? | Faceted jitter | Where do age and speed combine? |
| G10 | Which age band and speed zone hold the most deaths? | Bubble grid | Conclusion |

Every chart title and every number in the findings is calculated from the data when the script runs, so the story stays correct as BITRE releases new months.

## Findings

Generated in [`figures/findings.md`](figures/findings.md) by the script.

## Design choices

- **One colour language across all ten charts.** Red always marks the group or period being called out; dark slate is everything else.
- **Rates, not just counts, where it matters.** G7 shows shares within each time period so periods with more traffic don't dominate.
- **Clutter control.** G9 samples 4,000 of 50,000+ records and jitters them, so the distribution is visible instead of a solid block.
- **Missing data handled explicitly.** BITRE codes unknowns as `-9` or `Unknown`; both become `NA` and each chart drops only the fields it needs.
- **Interactive versions** of the trend (G1) and the day-time heatmap (G5) for the portfolio, with hover values.

## How to run

1. Download the latest ARDD fatalities file into `data/` (see [`data/README.md`](data/README.md)).
2. Open `australian-road-fatalities.Rproj` in RStudio.
3. Run `source("R/01_data_story.R")`. Missing packages install automatically.

Charts, the two interactive HTML charts and `findings.md` are written to `figures/`.

## Limitations

- **Counts, not risk.** Deaths aren't adjusted for population or distance travelled, so states and time periods with more traffic show more deaths. Exposure-adjusted rates are the planned next step.
- **Time of day is grouped into six-hour blocks**, which hides peaks inside each block.
- **Speed limit is the posted limit**, not the speed travelled.

## Next steps

- Per-capita and per-kilometre-travelled rates by state (ABS population, BITRE vehicle kilometres travelled)
- An interactive dashboard with state and year filters
- Holiday-period effects (Christmas and Easter flags are already in the data)

## About

Built by **Satish Kumar Reddy Gajjala** for Data Visualisation (MATH X314), Master of Data Science, University of Adelaide.
[LinkedIn](https://www.linkedin.com/in/satish-reddy-gajjala-450150234/) · [GitHub](https://github.com/satish9346)

Data: Bureau of Infrastructure and Transport Research Economics (BITRE), Australian Road Deaths Database, CC BY 4.0.
