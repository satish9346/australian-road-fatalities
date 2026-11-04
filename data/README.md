# Data

This project uses the **Australian Road Deaths Database (ARDD)**, fatalities file, published monthly by the Bureau of Infrastructure and Transport Research Economics (BITRE).

1. Download the latest *fatalities* file (`bitre_fatalities_<month><year>.xlsx`) from
   https://www.bitre.gov.au/statistics/safety/fatal_road_crash_database
2. Save it in this folder.
3. Name it `bitre_fatalities_feb2026.xlsx`, or change the `read_excel()` line near the top of `R/road_fatalities_story.qmd`.

The analysis in this repo used the **February 2026** release. The raw file isn't committed because BITRE updates it monthly; the script always reads whichever release you download.

Licence: BITRE data is published under Creative Commons Attribution 4.0.
