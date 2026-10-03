*******************************************************************************
* 02_merge.do
* Merge the cleaned 2016 and 2019 files into the individual panel used in the
* main analysis: individuals who answered the individual questionnaire in
* both 2016 and 2019 and did not move between oblasts.
*
*   Input : cleaned files from 01_cleaning.do; LiK panel roster
*   Output: $temporary/merged_2016.dta, merged_2019.dta (also used by 05)
*           $temporary/hh4a_2016.dta, hh4b_2016.dta     (also used by 05)
*           $temporary/merged_roster_2y_additional.dta  (used by 03)
*
* Run via code/00_master.do, which sets the project root and path globals.
*******************************************************************************


*******************************************************************************
* 1. Merge the individual modules within each year
*******************************************************************************

* 2019: modules 2, 3, 5 and household roster (keep respondents to module 5)
use "$temporary/id2_2019.dta", clear
merge 1:1 idp19 using "$temporary/id3_2019.dta", nogen
merge 1:1 idp19 using "$temporary/id5_2019", keep(3) nogen
merge 1:1 idp19 using "$temporary/hh1a_2019.dta", keep(3) nogen
save "$temporary/merged_2019", replace

* 2016: modules 1, 3, 5 and household roster
use "$temporary/id1_2016", clear
merge 1:1 idp16 using "$temporary/id3_2016", keep(3) nogen
merge 1:1 idp16 using "$temporary/id5_2016", keep(3) nogen
merge 1:1 idp16 using "$temporary/hh1a_2016", keep(3) nogen
save "$temporary/merged_2016", replace


*******************************************************************************
* 2. Panel roster: individuals present in both 2016 and 2019
*******************************************************************************
use "$roster/mroster1019_short.dta", clear
drop if idp19 == .
drop if idp16 == .

* Drop duplicated 2019 identifiers
duplicates tag idp19, gen(dupflag)
drop if dupflag > 0
rename dupflag dupflag19

gen female = (gender == 2)
save "$temporary/mroster1019_short_2y.dta", replace


*******************************************************************************
* 3. Two-period (2016-2019) dataset
*******************************************************************************
use "$temporary/mroster1019_short_2y.dta", clear
merge m:1 hhid16 using "$temporary/hh0_2016", keep(3) nogen
merge m:1 hhid19 using "$temporary/hh0_2019", keep(3) nogen
merge 1:1 idp16 using "$temporary/merged_2016", keep(3) nogen
merge 1:1 idp19 using "$temporary/merged_2019"

* Balanced panel: keep individuals who answered in both 2016 and 2019
keep if _merge == 3
drop _merge

label variable num_child16 "Number of children under age 18 in 2016"
label variable num_child19 "Number of children under age 18 in 2019"

* Keep individuals who did not move between 2016 and 2019. Movers are
* identified from the oblast in the roster, since the migration question in
* the individual questionnaire has too few answers (1,234 in 2019).
gen oblast_same = oblast16 == oblast19
gen oblast = oblast_same * oblast16
drop if oblast == 0

rename i50916 marriedyes16
rename i51119 marriedyes19

drop if idpp == .

* Decision-making items: i500_<k><yy> -> i500_<k>_<yy>
foreach yy in 16 19 {
    forvalues k = 1/17 {
        rename i500_`k'`yy' i500_`k'_`yy'
    }
}

save "$temporary/merged_roster_2y.dta", replace


*******************************************************************************
* 4. Household consumption (annualized), 2016 and 2019
*******************************************************************************

* --- Food consumption -----------------------------------------------------------
* h401d: 1 = per week, 2 = per month, 3 = per year
foreach yy in 16 19 {
    use "${hh_`yy'}/hh4a.dta", clear
    gen cons = .
    replace cons = h401c*52 if h401d==1
    replace cons = h401c*12 if h401d==2
    replace cons = h401c    if h401d==3
    by hhid: egen cons_food = total(cons)
    if "`yy'" == "16" {
        foreach var of varlist hhid - cons_food {
            rename `var' `var'16
        }
        gen log_cons_food16 = log(cons_food16)
    }
    else {
        gen log_cons_food = log(cons_food)
        foreach var of varlist hhid - log_cons_food {
            rename `var' `var'19
        }
    }
    label var log_cons_food`yy' "Log of food consumption in 20`yy'"
    collapse (mean) cons`yy' cons_food`yy' log_cons_food`yy', by(hhid`yy')
    save "$temporary/hh4a_20`yy'", replace
}

* --- Non-food consumption -------------------------------------------------------
* h404: 2 = per month, 3 = per year
foreach yy in 16 19 {
    use "${hh_`yy'}/hh4b.dta", clear
    gen cons_nf = .
    replace cons_nf = h403 * 12 if h404 == 2
    replace cons_nf = h403      if h404 == 3
    by hhid: egen cons_nonfood = total(cons_nf)
    foreach var of varlist hhid - cons_nonfood {
        rename `var' `var'`yy'
    }
    gen log_cons_nonfood`yy' = log(cons_nonfood`yy')
    label var log_cons_nonfood`yy' "Log of non-food consumption in 20`yy'"
    collapse (mean) cons_nf`yy' cons_nonfood`yy' log_cons_nonfood`yy', by(hhid`yy')
    save "$temporary/hh4b_20`yy'", replace
}


*******************************************************************************
* 5. Add consumption to the panel (keep all individuals; consumption is
*    attached where available)
*******************************************************************************
use "$temporary/merged_roster_2y.dta", clear
foreach yy in 16 19 {
    merge m:1 hhid`yy' using "$temporary/hh4a_20`yy'", keep(master match) nogen
    merge m:1 hhid`yy' using "$temporary/hh4b_20`yy'", keep(master match) nogen
}
save "$temporary/merged_roster_2y_additional.dta", replace
