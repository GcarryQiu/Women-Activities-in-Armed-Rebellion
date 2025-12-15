library(tidyverse)
library(here)
library(readr)
library(broom)

data_path <- here::here("data", "01-raw_data", "WAAR+Project+Dataset+v1.0.csv")
if (!file.exists(data_path)) stop("Missing data file: ", data_path)

waar_data <- read_csv(data_path, show_col_types = FALSE)

vars <- c("noncombat_logistics", "lead", "wwing", "coalition")

df_cc <- waar_data |>
  select(all_of(vars)) |>
  mutate(across(everything(), as.numeric)) |>
  filter(
    noncombat_logistics %in% c(0, 1),
    lead %in% c(0, 1),
    wwing %in% c(0, 1),
    coalition %in% c(0, 1)
  )

m0_path <- here::here("models", "robust_lead_only_m0.rds")
m1_path <- here::here("models", "main_logit_m1.rds")
if (!file.exists(m0_path)) stop("Missing model file: ", m0_path)
if (!file.exists(m1_path)) stop("Missing model file: ", m1_path)

m0 <- readRDS(m0_path)
m1 <- readRDS(m1_path)

out_dir <- here::here("outputs", "tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

tbl_modelresults <- tidy(m1) |>
  mutate(
    OR = exp(estimate),
    CI_low = exp(estimate - 1.96 * std.error),
    CI_high = exp(estimate + 1.96 * std.error)
  ) |>
  select(term, estimate, std.error, p.value, OR, CI_low, CI_high)

write_csv(tbl_modelresults, file.path(out_dir, "tbl-modelresults.csv"))

tbl_robustness <- bind_rows(
  tidy(m0) |> mutate(model = "Model A: lead only"),
  tidy(m1) |> mutate(model = "Model B: + wwing + coalition")
) |>
  filter(term != "(Intercept)") |>
  mutate(
    OR = exp(estimate),
    CI_low = exp(estimate - 1.96 * std.error),
    CI_high = exp(estimate + 1.96 * std.error)
  ) |>
  select(model, term, estimate, std.error, p.value, OR, CI_low, CI_high)

write_csv(tbl_robustness, file.path(out_dir, "tbl-robustness.csv"))

mean_wwing <- mean(df_cc$wwing)
mean_coal <- mean(df_cc$coalition)

profiles <- tibble(
  profile = c(
    "Baseline: wwing=0, coalition=0",
    "Women’s wing: wwing=1, coalition=0",
    "Controls at sample means"
  ),
  wwing = c(0, 1, mean_wwing),
  coalition = c(0, 0, mean_coal)
)

tbl_pred_profiles <- profiles |>
  mutate(
    p_lead0 = predict(m1, newdata = tibble(lead = 0, wwing = wwing, coalition = coalition), type = "response"),
    p_lead1 = predict(m1, newdata = tibble(lead = 1, wwing = wwing, coalition = coalition), type = "response"),
    diff = p_lead1 - p_lead0
  )

write_csv(tbl_pred_profiles, file.path(out_dir, "tbl-pred-profiles.csv"))

cat("Wrote tables to:\n", out_dir, "\n", sep = "")
cat(" - tbl-modelresults.csv\n - tbl-robustness.csv\n - tbl-pred-profiles.csv\n")
