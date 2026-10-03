*******************************************************************************
* 05_pretrend.do
* Pre-trend placebo test: DDD between the 2013 and 2016 waves, with the
* placebo treatment in 2015 (Appendix Table 9).
*
*   Input : cleaned 2013 and 2016 files from 01_cleaning.do and 02_merge.do
*           $temporary/dv_rate_baseline.dta (from 00_dv_rate.do)
*   Output: $temporary/analysis_pre2y_long_DDD_fin.dta
*
* Run via code/00_master.do, which sets the project root and path globals.
*******************************************************************************


*******************************************************************************
* 1. 2013 individual module 5B: decision-making items
*******************************************************************************
use "$temporary/id5b_2013", clear

* Map the 2013 items to the 17 items used in 2016 and 2019.
* Items 12 (children's education and health: 2013 items 11-13) and 17 (when
* and at what price to sell the harvest or livestock: 2013 items 33-34)
* combine several 2013 items; they are built after merging, since they
* depend on the respondent's gender.
local map13 21 22 03 04 24 06 07 29 18 19 20 . 26 27 28 31 .
forvalues k = 1/17 {
    local src : word `k' of `map13'
    if "`src'" != "." {
        rename i500_`src'13 dm`k'
    }
}

gen dm12 = .
rename i500_1113 dm12a
rename i500_1213 dm12b
rename i500_1313 dm12c

gen dm17 = .
rename i500_3313 dm17a
rename i500_3413 dm17b

save "$temporary/id5b_2013_dm", replace


*******************************************************************************
* 2. 2013 marriage (module 5D, asked to female respondents only)
*******************************************************************************
use "$ind_13/id5d", clear
gen idp13 = (hhid + pid/100)*100
foreach var of varlist hhid - i527_b {
    rename `var' `var'13
}
rename i51613 marriedyes13
save "$temporary/id5d_2013", replace


*******************************************************************************
* 3. 2013 household consumption
*******************************************************************************

* --- Food consumption (annualized) ------------------------------------------
use "$hh_13/hh4a.dta", clear
gen cons = .
* weekly
replace cons = h401c*52 if h401d==1
* monthly
replace cons = h401c*12 if h401d==2
by hhid: egen cons_food = total(cons)
foreach var of varlist hhid - cons_food {
    rename `var' `var'13
}
gen log_cons_food13 = log(cons_food13)
label var log_cons_food13 "Log of food consumption in 2013"
collapse (mean) cons13 cons_food13 log_cons_food13, by(hhid13)
save "$temporary/hh4a_2013", replace

* --- Non-food consumption (annualized) --------------------------------------
use "$hh_13/hh4b.dta", clear
gen cons_nf = .
* monthly
replace cons_nf = h403 * 12 if h404 == 2
* yearly
replace cons_nf = h403     if h404 == 3
by hhid: egen cons_nonfood = total(cons_nf)
foreach var of varlist hhid - cons_nonfood {
    rename `var' `var'13
}
gen log_cons_nonfood13 = log(cons_nonfood13)
label var log_cons_nonfood13 "Log of non-food consumption in 2013"
collapse (mean) cons_nf13 cons_nonfood13 log_cons_nonfood13, by(hhid13)
save "$temporary/hh4b_2013", replace


*******************************************************************************
* 4. Merge the 2013 individual files
*    (respondents fall from about 7,000 in id5b to about 5,000 in id5e)
*******************************************************************************
use "$temporary/id1_2013", clear
merge 1:1 idp13 using "$temporary/id3a_2013", keep(3) nogen
merge 1:1 idp13 using "$temporary/id5b_2013_dm", keep(3) nogen
merge 1:1 idp13 using "$temporary/id5e_2013", keep(3) nogen
merge 1:1 idp13 using "$temporary/hh1a_2013", keep(3) nogen
merge 1:m idp13 using "$temporary/id5d_2013", nogen
save "$temporary/merged_2013", replace


*******************************************************************************
* 5. Roster: individuals observed in both 2013 and 2016
*******************************************************************************
use "$roster/mroster1019_short.dta", clear
duplicates report idp16
duplicates report idp13
drop if idp16 == .
drop if idp13 == .

gen female = (gender == 2)
label variable female "1 female; 0 male"
save "$temporary/mroster1019_short_pre.dta", replace


*******************************************************************************
* 6. Two-period (2013-2016) dataset
*******************************************************************************
use "$temporary/mroster1019_short_pre.dta", clear
merge m:1 hhid13 using "$temporary/hh0_2013", keep(3) nogen
merge m:1 hhid16 using "$temporary/hh0_2016", keep(3) nogen
merge 1:1 idp13 using "$temporary/merged_2013", keep(3) nogen
merge 1:1 idp16 using "$temporary/merged_2016", keep(3) nogen
merge m:1 hhid13 using "$temporary/hh4a_2013", keep(3) nogen
merge m:1 hhid13 using "$temporary/hh4b_2013", keep(3) nogen
merge m:1 hhid16 using "$temporary/hh4a_2016", keep(3) nogen
merge m:1 hhid16 using "$temporary/hh4b_2016", keep(3) nogen
save "$temporary/merged_roster_pre2y_all.dta", replace


*******************************************************************************
* 7. Cleaning before reshape
*******************************************************************************
use "$temporary/merged_roster_pre2y_all.dta", clear

* Keep individuals who did not move between 2013 and 2016
gen oblast_same = oblast16 == oblast13
gen oblast = oblast_same * oblast13
drop if oblast == 0

rename i50916 marriedyes16
duplicates list idpp

forvalues k = 1/17 {
    rename i500_`k'16 i500_`k'_16
}

* --- Female decision-making index -------------------------------------------
* Response codes: 1 = myself, 2 = my spouse, 3 = jointly with spouse,
* 7 = all female members, 8 = all members together.
capture program drop gen_fem_dm
program define gen_fem_dm
    * gen_fem_dm <new variable> <decision-making item>
    args newvar item
    gen `newvar' = .
    * female respondent: myself
    replace `newvar' = 1 if gender==2 & `item'==1
    * male respondent: my spouse (wife)
    replace `newvar' = 1 if gender==1 & `item'==2
    * jointly with spouse
    replace `newvar' = 1 if `item'==3
    * all female household members
    replace `newvar' = 1 if `item'==7
    * all household members together, with at least one woman in the household
    replace `newvar' = 1 if `item'==8 & female_in_hh==1
    replace `newvar' = 0 if `newvar' == .
end

* Note: computed over the whole sample (no by-group), so female_in_hh = 1 for
* every observation.
egen female_in_hh = max(female==1)

* 2013, item 12: woman takes part in any of the three 2013 sub-items
foreach s in a b c {
    gen_fem_dm fem_dm_12`s' dm12`s'
}
egen fem_dm_12 = rowmax(fem_dm_12a fem_dm_12b fem_dm_12c)
tab fem_dm_12, missing

* 2013, item 17: woman takes part in either of the two 2013 sub-items
foreach s in a b {
    gen_fem_dm fem_dm_17`s' dm17`s'
}
egen fem_dm_17 = rowmax(fem_dm_17a fem_dm_17b)
tab fem_dm_17, missing

* 2013, other items
foreach j of numlist 1/11 13/16 {
    gen_fem_dm fem_dm_`j' i500_`j'_
}

move fem_dm_17 fem_dm_16
move fem_dm_12 fem_dm_11

foreach v of varlist fem_dm_1-fem_dm_17 {
    estpost tab `v', missing
}

egen fem_dm_sum = rowtotal(fem_dm_1-fem_dm_17)
gen fem_dm_ave = fem_dm_sum/17
rename (fem_dm_*) (fem_dm_*_13)

* 2016
forvalues j = 1/17 {
    gen_fem_dm fem_dm_`j'_16 i500_`j'_16
}
egen fem_dm_sum_16 = rowtotal(fem_dm_1_16-fem_dm_17_16)
gen fem_dm_ave_16 = fem_dm_sum_16/17

rename (cons16 cons13) (consp16 consp13)
save "$temporary/merged_roster_pre2y_cleaning.dta", replace


*******************************************************************************
* 8. Reshape to long format
*******************************************************************************
local dm_items
forvalues k = 1/17 {
    local dm_items `dm_items' i500_`k'_
}
reshape long risk i301 i302 i303 i304 work7 `dm_items' Imp_deci_hus Man_earn_W_home W_ff_if_mom W_work_good Huscareer_imp_wife Unieduc_imp_boy Both_contri_inc Wife_ff_eq_pay No_WWOH_reli h108 num_child marriedyes consp cons_food log_cons_food cons_nf cons_nonfood log_cons_nonfood fem_dm_sum_ fem_dm_ave_, i(idpp) j(year)
* Note: highest completed education is not included yet
save "$temporary/merged_roster_pre2y_reshaped.dta", replace

xtset idpp year


*******************************************************************************
* 9. Variables
*******************************************************************************

* --- Risk attitude, standardized to the 2013 distribution ---------------------
summarize risk if year==13
local m  = r(mean)
local sd = r(sd)
assert `sd' > 0
gen risk_std = (risk - `m')/`sd'
label var risk_std "Risk (std. to 2013 mean & SD)"
summarize risk_std if year==13

* --- Treatment intensity: DV rate by oblast in 2013 (percent) ------------------
merge m:1 oblast using "$temporary/dv_rate_baseline.dta", keepusing(DV_rate_13) keep(1 3) nogen

* --- Age at baseline (2013), cohorts ------------------------------------------
gen year_abs = 2000 + year
gen age = year_abs - byear
drop if age < 18

bysort idpp (year): gen age_13 = age if year_abs==2013
bysort idpp: egen age_13b = max(age_13)
by idpp: assert age_13b==age if year_abs==2013
count if missing(age_13b)

gen age2_13b = age_13b^2
label var age_13b  "Age at 2013"
label var age2_13b "Age^2 at 2013"
label var work7    "take 1 if worked past 7 days"

* Birth year must be constant within individual
by idpp: assert byear == byear[1]

* Birth cohorts by decade: 1 = before 1940, 2 = 1940s, ..., 7 = 1990s
gen age_cohort = 0
replace age_cohort = 1 if byear < 1940
forvalues k = 2/7 {
    replace age_cohort = `k' if byear >= 1920 + 10*`k' & byear < 1930 + 10*`k'
}
gen age2040 = inlist(age_cohort, 5, 6, 7)
label var age2040 "Cohorts 1970-1999"

gen agecat = .
replace agecat = 1 if inrange(age, 20, 29)
replace agecat = 2 if inrange(age, 30, 39)
replace agecat = 3 if inrange(age, 40, 49)
replace agecat = 4 if inrange(age, 50, 59)
replace agecat = 5 if age >= 60
label define agecat 1 "20s" 2 "30s" 3 "40s" 4 "50s" 5 "60+"
label values agecat agecat

* Placebo post period: 2016
gen post_year = year == 16

* --- Marriage -----------------------------------------------------------------
* Only female respondents were asked in 2013, so marriage is not usable as a
* control in this placebo test.
tab marriedyes year, missing
drop if marriedyes == 9
replace marriedyes = 0 if marriedyes == 2

save "$temporary/analysis_pre2y_long.dta", replace


*******************************************************************************
* 10. Baseline (2013) covariates and analysis variables
*******************************************************************************
bysort idpp (year): gen married2013  = marriedyes       if year==13
bysort idpp (year): gen num_child_13 = num_child        if year==13
bysort idpp (year): gen lcf_13       = log_cons_food    if year==13
bysort idpp (year): gen lcnf_13      = log_cons_nonfood if year==13

bysort idpp: egen married2013b         = max(married2013)
bysort idpp: egen num_child_13b        = max(num_child_13)
bysort idpp: egen log_cons_food_13b    = max(lcf_13)
bysort idpp: egen log_cons_nonfood_13b = max(lcnf_13)

label var married2013b         "Married (2013 baseline)"
label var num_child_13b        "# children (2013 baseline)"
label var log_cons_food_13b    "Log food cons. (2013 baseline)"
label var log_cons_nonfood_13b "Log non-food cons. (2013 baseline)"

* Mean-center the DV rate
summarize DV_rate_13
gen double DV_rate_13_c = DV_rate_13 - r(mean)

gen flfp = work7 if female==1
label var flfp "Female Labor Force Participation (female sample only)"
gen work7_male = work7 if female==0
label var work7_male "Male Labor Force Participation (male sample only)"

save "$temporary/analysis_pre2y_long_DDD.dta", replace

* Balanced panel: individuals observed in both 2013 and 2016
bysort idpp: keep if _N == 2

* Interaction terms (control version)
gen post_numchild = post_year * num_child_13b
gen post_age      = post_year * age_13b
gen post_age2     = post_year * age2_13b
gen post_lfood    = post_year * log_cons_food_13b
gen post_nonlfood = post_year * log_cons_nonfood_13b
gen post_married  = post_year * married2013b

gen dv_female   = DV_rate_13_c * female
gen dv_post     = DV_rate_13_c * post_year
gen female_post = female * post_year
gen DDD         = DV_rate_13_c * female * post_year


*******************************************************************************
* 11. Placebo DDD with wild cluster bootstrap (wildboot, rseed 1234)
*******************************************************************************
estimates clear

capture program drop wb_bootp
program define wb_bootp
    * After "eststo name: wildboot ...", attach the wild bootstrap p-values in
    * r(table) to the stored estimates as e(bootp). r(table) has no columns for
    * omitted (zero) coefficients, so the column names are rebuilt from the
    * non-zero entries of e(b).
    args name
    mat list r(table)
    mat bootp = r(table)["pvalue", 1...]
    local names : colnames e(b)
    local nonzero_b
    foreach v of local names {
        if "`v'" == "_cons" continue
        if e(b)[1, "`v'"] != 0 {
            local nonzero_b `nonzero_b' `v'
        }
    }
    mat colnames bootp = `nonzero_b'
    estadd mat bootp = bootp : `name'
    mat list bootp
    estadd scalar clusters = e(N_clust) : `name'
    estadd scalar reps = e(N_wbreps) : `name'
end

local m1 No_WWOH_reli i.post_year##c.DV_rate_13_c##i.female i.year if nowwoh413==1
local m2 Huscareer_imp_wife i.post_year##c.DV_rate_13_c##i.female i.year if hus413==1
local m3 risk_std i.post_year##c.DV_rate_13_c##i.female i.year
local m4 fem_dm_ave post_year i.post_year##c.DV_rate_13_c##i.female i.year
local m5 work7 i.post_year##c.DV_rate_13_c##i.female i.year

forvalues k = 1/5 {
    eststo m`k': wildboot xtreg `m`k'', fe cluster(oblast) reps(9999) rseed(1234)
    wb_bootp m`k'
}

esttab m1 m2 m3 m4 m5, keep(1.post_year 1.post_year#c.DV_rate_13_c 1.post_year#1.female 1.post_year#1.female#c.DV_rate_13_c) scalars(clusters reps) cells(b(fmt(3) star pvalue(bootp)) bootp(par)) starlevels(* 0.10 ** 0.05 *** 0.01) addnotes("Wild cluster boot p-values in parentheses. Stars based on p-values." "Individual FE absorbed (idpp, year); SEs clustered at oblast.") varwidth(30)

save "$temporary/analysis_pre2y_long_DDD_fin.dta", replace
