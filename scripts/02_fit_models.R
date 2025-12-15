# scripts/02_fit_models.R

suppressPackageStartupMessages({
  library(here)
  library(readr)
  library(dplyr)
})


raw_path <- here::here("data", "01-raw_data", "WAAR+Project+Dataset+v1.0.csv")
sim_path <- here::here("data", "00-simulated_data", "waar_simulated.csv")

data_path <- if (file.exists(raw_path)) raw_path else sim_path

if (!file.exists(data_path)) {
  stop(
    paste0(
      "Cannot find data file.\n",
      "Tried:\n  - ", raw_path, "\n  - ", sim_path, "\n\n",
      "Fix: put the CSV in data/01-raw_data/ (real) or data/00-simulated_data/ (simulated)."
    )
  )
}

message("Reading data from: ", data_path)
waar_data <- read_csv(data_path, show_col_types = FALSE)

# --- build analysis sample (match your paper) ---
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

message("N complete cases used = ", nrow(df_cc))
if (nrow(df_cc) == 0) stop("df_cc has 0 rows after filtering. Check variable names / coding.")

# --- fit models ---
m0 <- glm(noncombat_logistics ~ lead,
          data = df_cc,
          family = binomial(link = "logit"))

m1 <- glm(noncombat_logistics ~ lead + wwing + coalition,
          data = df_cc,
          family = binomial(link = "logit"))

models_dir <- here::here("models")
if (!dir.exists(models_dir)) dir.create(models_dir, recursive = TRUE)

saveRDS(m0, file = file.path(models_dir, "robust_lead_only_m0.rds"))
saveRDS(m1, file = file.path(models_dir, "main_logit_m1.rds"))

message("Saved models to: ", models_dir)
message(" - robust_lead_only_m0.rds")
message(" - main_logit_m1.rds")
