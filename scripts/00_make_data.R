# scripts/00_make_data.R

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(here)
})

set.seed(4101)

candidates <- c(
  here::here("WAAR+Project+Dataset+v1.0.csv"),
  here::here("data", "01-raw_data", "WAAR+Project+Dataset+v1.0.csv")
)

input_path <- candidates[file.exists(candidates)][1]


read_waar <- function(p) {
  tryCatch(
    readr::read_csv(p, show_col_types = FALSE),
    error = function(e) readr::read_csv(
      p,
      show_col_types = FALSE,
      locale = readr::locale(encoding = "Latin1")
    )
  )
}

waar <- read_waar(input_path)

dir.create(here::here("data", "00-simulated_data"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("data", "01-raw_data"),       recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("data", "02-analysis_data"),  recursive = TRUE, showWarnings = FALSE)

raw_min <- waar |>
  transmute(
    NSAdyad_id = NSAdyad_id,
    sidea = sidea,
    sideb = sideb,
    country_primary = country_primary,
    noncombat_logistics = noncombat_logistics,
    lead = lead,
    wwing = wwing,
    coalition = coalition
  )

readr::write_csv(raw_min, here::here("data", "01-raw_data", "raw_data.csv"))

analysis_df <- raw_min |>
  select(noncombat_logistics, lead, wwing, coalition) |>
  mutate(across(everything(), as.numeric)) |>
  filter(
    noncombat_logistics %in% c(0, 1),
    lead %in% c(0, 1),
    wwing %in% c(0, 1),
    coalition %in% c(0, 1)
  )

readr::write_csv(analysis_df, here::here("data", "02-analysis_data", "analysis_data.csv"))

m_hat <- glm(noncombat_logistics ~ lead + wwing + coalition,
             data = analysis_df, family = binomial())

b <- coef(m_hat)
b_sim <- b + rnorm(length(b), mean = 0, sd = 0.25)
names(b_sim) <- names(b)

n <- nrow(analysis_df)

sim_df <- tibble(
  lead = rbinom(n, 1, mean(analysis_df$lead)),
  wwing = rbinom(n, 1, mean(analysis_df$wwing)),
  coalition = rbinom(n, 1, mean(analysis_df$coalition))
) |>
  mutate(
    linpred = b_sim["(Intercept)"] +
      b_sim["lead"] * lead +
      b_sim["wwing"] * wwing +
      b_sim["coalition"] * coalition,
    p = plogis(linpred),
    noncombat_logistics = rbinom(n, 1, p)
  ) |>
  select(noncombat_logistics, lead, wwing, coalition)

readr::write_csv(sim_df, here::here("data", "00-simulated_data", "simulated_data.csv"))

cat("Done.\n")
cat("Input:", input_path, "\n\n")
cat("Wrote:\n")
cat("-", here::here("data", "01-raw_data", "raw_data.csv"), "\n")
cat("-", here::here("data", "02-analysis_data", "analysis_data.csv"), "\n")
cat("-", here::here("data", "00-simulated_data", "simulated_data.csv"), "\n\n")
cat("analysis_df N =", nrow(analysis_df), "\n")



