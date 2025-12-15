# Women Activities in Armed Rebellion

## Overview

This repo contains an analysis of women’s logistical participation in rebel organizations using the Women’s Activities in Armed Rebellion (WAAR) dataset (1946–2015). A logistic regression model is used to study whether rebel groups with women in leadership positions are more likely to have women participating in logistical roles, controlling for coalition membership and the presence of women’s wings.

To use this folder, click the green "Code" button, then "Download ZIP". Move the downloaded folder to where you want to work on your own computer, and then modify it to suit.

## File Structure

The repo is structured as:

data contains the data used in the project.
- data/01-raw_data contains the original WAAR dataset.
- data/02-analysis_data contains cleaned or intermediate datasets used in the analysis.
- data/03-simulated_data contains simulated data used for demonstration and reproducibility.

models contains fitted logistic regression models saved as RDS files.

paper contains the Quarto document (.qmd), bibliography file, and the PDF of the paper.

scripts contains the R scripts used to prepare data, fit models, and generate tables and figures.

other contains notes or sketches and is not required to reproduce the main analysis.

