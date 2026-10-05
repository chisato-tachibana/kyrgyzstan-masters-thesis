*******************************************************************************
* 00_master.do
* Replication code for:
*   "Does Domestic Violence Law Shift Gender Attitudes and Female Labor
*    Force Participation in Kyrgyzstan?"  (Chisato Tachibana)
*
* Usage: set the global `root` below to the folder that contains this
* repository, place the LiK data as described in data/README.md, and run.
*******************************************************************************

clear all
set more off

* ---- Set the project root (EDIT THIS LINE) ----------------------------------
global root "/path/to/kyrgyzstan-masters-thesis"
cd "$root"

* ---- Paths ------------------------------------------------------------------
* Intermediate datasets and output (figures and tables)
global temporary "$root/temporary"
global fig       "$root/fig_table"

global ind_19 "$root/data/Version 2022/Individual"
global hh_19  "$root/data/Version 2022/Household"
global roster "$root/data/Version 2022/Panelroster"

global ind_16 "$root/data/LiK16_IDSC-IZA/LiK16_data_stata/Individual"
global hh_16  "$root/data/LiK16_IDSC-IZA/LiK16_data_stata/Household"

global ind_13 "$root/data/stata/data2013/individual"
global hh_13  "$root/data/stata/data2013/household"

capture mkdir "$temporary"
capture mkdir "$fig"

* ---- Required packages (uncomment on first run) -----------------------------
* wildboot is built into Stata 18; the others are user-written.
* ssc install reghdfe
* ssc install ftools
* ssc install estout
* ssc install boottest

* ---- Run --------------------------------------------------------------------
do "$root/code/00_dv_rate.do"
do "$root/code/01_cleaning.do"
do "$root/code/02_merge.do"
do "$root/code/03_main_analysis.do"
do "$root/code/04_heterogeneity.do"
do "$root/code/05_pretrend.do"
