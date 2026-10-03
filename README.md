# Does Domestic Violence Law Shift Gender Attitudes and Female Labor Force Participation in Kyrgyzstan?

**Chisato Tachibana** (The University of Tokyo, Graduate School of Economics)
Master's thesis — replication code

📄 **Paper:** [paper/Tachibana_DV_Law_Kyrgyzstan.pdf](paper/Tachibana_DV_Law_Kyrgyzstan.pdf)

## Abstract

This paper examines whether legal reforms aimed at protecting women can
translate into substantive economic empowerment in contexts characterized by
strong patriarchal norms. Using Kyrgyzstan's 2017 Domestic Violence Law and an
intensity-based **triple-differences design** that exploits regional variation
in pre-reform domestic violence prevalence, I find that the law led to
significant improvements in attitudes toward women's work and increased
women's bargaining power within households, particularly in initially
conservative regions. However, I find no increase in female labor force
participation, highlighting a gap between changing norms and observable
economic behavior.

## Data

- **Life in Kyrgyzstan (LiK) Study**, individual panel, waves 2013, 2016, and 2019.
  The data are not redistributable. They can be obtained from the
  [IZA International Data Service Center](https://datasets.iza.org/dataset/124/life-in-kyrgyzstan-study-2010-2019).
  See [data/README.md](data/README.md) for where to place the files. Use the
  files as distributed; the code handles all cleaning.
- **Domestic violence statistics**: oblast-level counts of female DV victims and
  population from the National Statistical Committee of the Kyrgyz Republic.
  These are public and included in [data/dv/](data/dv/).

## How to replicate

1. Place the LiK data in `data/` as described in [data/README.md](data/README.md).
2. Install the user-written packages: `ssc install reghdfe`, `ssc install ftools`,
   `ssc install estout`, `ssc install boottest` (`wildboot` is built into Stata 18).
3. Set `global root` in `code/00_master.do` to the repository folder and run it.

Tables are written to `fig_table/` and printed in the log. The full run takes
a few minutes (wild cluster bootstrap with 9,999 replications).

Software: Stata 18 SE.

## Code

| File | Description | Paper output |
|---|---|---|
| `code/00_master.do` | Sets paths and runs all scripts in order | |
| `code/00_dv_rate.do` | Oblast-level DV incidence rate (treatment intensity) from official statistics | Figure 3 |
| `code/01_cleaning.do` | Cleans the raw LiK individual and household files for each wave | |
| `code/02_merge.do` | Builds the 2016–2019 individual panel | |
| `code/03_main_analysis.do` | Analysis variables; main DDD estimates with wild cluster bootstrap p-values; gender-specific effects; full-sample attitudes | Tables 1–5; appendix tables on gender-specific effects and full-sample attitudes |
| `code/04_heterogeneity.do` | Employment history from the 12-month activity calendar; heterogeneity; multiple hypothesis testing | Tables 6–8; Appendix Tables 10–13 |
| `code/05_pretrend.do` | Placebo test using the 2013–2016 panel | Appendix Table 9 |
