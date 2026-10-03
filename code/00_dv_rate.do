*******************************************************************************
* 00_dv_rate.do
* Construct the oblast-level DV incidence rate (treatment intensity) and
* draw Figure 3 (annual DV incidence rates among women by oblast).
*
*   Input : data/dv/dv_female_victims.csv     number of female DV victims
*           data/dv/population_thousands.csv  resident population (thousands)
*           Source: National Statistical Committee of the Kyrgyz Republic
*   Output: $temporary/dv_rate_oblast_year.dta  (oblast x year, 2012-2022)
*           $temporary/dv_rate_baseline.dta     (oblast, DV_rate_13, DV_rate_16)
*           $fig/figure3_dv_rate_trend.png
*
* oblast codes follow LiK (SOATO 417xx -> xx); 0 = Kyrgyz Republic total.
* DV rate = female DV victims / female population x 100, i.e. in percent.
* Female population is approximated as half of the total population.
*
* Run via code/00_master.do, which sets the project root and path globals.
*******************************************************************************


*******************************************************************************
* 1. Load and reshape the raw data
*******************************************************************************
import delimited "$root/data/dv/population_thousands.csv", clear
reshape long pop, i(oblast) j(year)
tempfile pop
save `pop'

import delimited "$root/data/dv/dv_female_victims.csv", clear
reshape long dv, i(oblast) j(year)
merge 1:1 oblast year using `pop', keep(3) nogen


*******************************************************************************
* 2. DV incidence rate among women (percent)
*******************************************************************************
gen year_women_pop = pop * 1000 / 2
gen DV_rate_ = dv / year_women_pop * 100
label var DV_rate_ "DV victims per female population (%)"

* 2023 figures are incomplete in the source tables
drop if year == 2023

sort oblast year
save "$temporary/dv_rate_oblast_year.dta", replace


*******************************************************************************
* 3. Figure 3: annual trend by oblast
*******************************************************************************
twoway (line DV_rate_ year if oblast == 5, lcolor(blue) lpattern(solid)) (line DV_rate_ year if oblast == 3, lcolor(blue%80) lpattern(dash)) (line DV_rate_ year if oblast == 2, lcolor(blue%60) lpattern(dot)) (line DV_rate_ year if oblast == 4, lcolor(blue%40) lpattern(longdash)) (line DV_rate_ year if oblast == 6, lcolor(blue%20) lpattern(dashdot)) (line DV_rate_ year if oblast == 7, lcolor(green) lpattern(dashdotdot)) (line DV_rate_ year if oblast == 8, lcolor(navy) lpattern(solid)) (line DV_rate_ year if oblast == 11, lcolor(midblue) lpattern(dash)) (line DV_rate_ year if oblast == 21, lcolor(orange) lpattern(dash)), title("DV Incidence Rate by Year") xlabel(2012(1)2022) ylabel(0(0.05)0.7) xtitle("Year") ytitle("DV Incidence Rate (%)") legend(order(1 "Batken" 2 "Jalal-Abad" 3 "Issyk-Kul" 4 "Naryn" 5 "Osh" 6 "Talas" 7 "Chui" 8 "Bishkek City" 9 "Osh City")) xline(2017, lcolor(black) lwidth(thick))
graph export "$fig/figure3_dv_rate_trend.png", replace width(2000)


*******************************************************************************
* 4. Baseline DV rates by oblast: 2016 (main analysis, 03) and 2013 (pre-trend
*    placebo, 05)
*******************************************************************************
keep if inlist(year, 2013, 2016) & oblast != 0
* Rounded to the displayed precision (%9.0g), which is what the analysis in
* the paper used; the difference from full precision is below 1e-7.
gen float DV_rate_r = real(string(DV_rate_, "%9.0g"))
drop DV_rate_
rename DV_rate_r DV_rate_
replace year = year - 2000
keep oblast year DV_rate_
reshape wide DV_rate_, i(oblast) j(year)
save "$temporary/dv_rate_baseline.dta", replace
