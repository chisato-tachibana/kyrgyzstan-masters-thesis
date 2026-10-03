# Domestic Violence Law, Gender Attitudes, and Female Labor Force Participation in Kyrgyzstan?

Code for my master's thesis at the Graduate School of Public Policy, University of Tokyo.

Paper: [paper/Tachibana_DV_Law_Kyrgyzstan.pdf](paper/Tachibana_DV_Law_Kyrgyzstan.pdf)

The thesis looks at whether Kyrgyzstan's 2017 Domestic Violence Law changed gender attitudes, women's decision-making in the household, and female labor force participation. I use a triple-difference design that compares women and men across oblasts with different levels of reported domestic violence before the reform, using the Life in Kyrgyzstan panel (2013, 2016, 2019).

## Data

The Life in Kyrgyzstan (LiK) data cannot be shared here. They are available from the IZA International Data Service Center:
https://datasets.iza.org/dataset/124/life-in-kyrgyzstan-study-2010-2019

See `data/README.md` for where to put the files.

The oblast-level domestic violence and population figures (National Statistical Committee of the Kyrgyz Republic) are public and are in `data/dv/`.

## Running the code

The code is written in Stata 18. It needs `reghdfe`, `ftools`, `estout`, and `boottest` from SSC.

Set `global root` at the top of `code/00_master.do` and run that file. It runs everything below in order and writes the tables to `fig_table/`. The whole thing takes a few minutes.

- `00_dv_rate.do`: DV incidence rate by oblast (Figure 3)
- `01_cleaning.do`: cleans the raw LiK files
- `02_merge.do`: builds the 2016–2019 panel
- `03_main_analysis.do`: Tables 1–5 and the appendix tables on gender-specific effects and the full sample
- `04_heterogeneity.do`: Tables 6–8 and Appendix Tables 10–13
- `05_pretrend.do`: pre-trend test (Appendix Table 9)
