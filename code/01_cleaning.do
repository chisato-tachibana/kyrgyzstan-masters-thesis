*******************************************************************************
* 01_cleaning.do
* Clean the raw LiK individual and household files for 2019, 2016, and 2013.
* Each file gets a person identifier idp<yy> = hhid*100 + pid and a year
* suffix on its variable names.
*
*   Input : raw LiK Stata files ($ind_yy, $hh_yy)
*   Output: $temporary/id*_20yy.dta, hh0_20yy.dta, hh1a_20yy.dta
*
* Run via code/00_master.do, which sets the project root and path globals.
*******************************************************************************

* Gender-attitude items (module 5), harmonized names
local attitudes Imp_deci_hus Man_earn_W_home W_ff_if_mom W_work_good Huscareer_imp_wife Unieduc_imp_boy Both_contri_inc Wife_ff_eq_pay No_WWOH_reli


*******************************************************************************
* 1. 2019
*******************************************************************************

* --- id2: risk attitude (and education) -----------------------------------------
use "$ind_19/id2.dta", clear
gen idp19 = (hhid + pid/100)*100
foreach var of varlist hhid - i251_8 {
    rename `var' `var'19
}
rename i22719 risk19
tab risk19
save "$temporary/id2_2019", replace

* --- id3: work in the past 7 days ---------------------------------------------
* work7 = 1 if any of the following in the past 7 days:
*   i301 worked as an employee
*   i302 worked in a family business or own business
*   i303 subsistence agriculture, forestry, or fishing
*   i304 had a job but was temporarily absent (leave, sickness, etc.)
use "$ind_19/id3.dta", clear
gen idp19 = (hhid + pid/100)*100
foreach var of varlist hhid - i381 {
    rename `var' `var'19
}
gen work719 = (i30119 == 1 | i30219 == 1 | i30319 == 1 | i30419 == 1)
move work719 i305_119
save "$temporary/id3_2019", replace

* --- id5: decision making (i500) and gender attitudes (i501) ------------------
* The i500 items have the same names and order in 2016 and 2019.
use "$ind_19/id5.dta", clear
rename i501_1  Imp_deci_hus
rename i501_3  W_ff_if_mom
rename i501_4  Unieduc_imp_boy
rename i501_5  Man_earn_W_home
rename i501_6  Huscareer_imp_wife
rename i501_7  W_work_good
rename i501_8  Wife_ff_eq_pay
rename i501_9  No_WWOH_reli
rename i501_10 Both_contri_inc

gen idp19 = (hhid + pid/100)*100
foreach v of varlist hhid - i518 {
    rename `v' `v'19
}

local att19
foreach v of local attitudes {
    local att19 `att19' `v'19
}

* Drop "don't know" (99) answers to the attitude items
foreach v of varlist `att19' {
    estpost tabulate `v'
    eststo `v'
}
foreach v of varlist `att19' {
    drop if `v'==99
}
eststo clear
foreach v of varlist `att19' {
    estpost tabulate `v'
    eststo `v'
}
save "$temporary/id5_2019", replace

* --- hh1a: household roster, number of children under 18 -------------------------
use "$hh_19/hh1a.dta", clear
gen idp19 = (hhid + pid/100)*100
gen age18 = h103a < 18
egen num_child = total(age18), by(hhid)
move idp19 num_child
foreach var of varlist hhid - num_child {
    rename `var' `var'19
}
save "$temporary/hh1a_2019", replace

* --- hh0: household cover sheet (oblast codes are already 2-21) -----------------
use "$hh_19/hh0.dta", clear
foreach var of varlist hhid - residence {
    rename `var' `var'19
}
save "$temporary/hh0_2019", replace


*******************************************************************************
* 2. 2016
*******************************************************************************

* --- id1: risk attitude ---------------------------------------------------------
use "$ind_16/id1.dta", clear
gen idp16 = (hhid + pid/100)*100
foreach var of varlist hhid - i107 {
    rename `var' `var'16
}
rename i10716 risk16
tab risk16
save "$temporary/id1_2016", replace

* --- id3: work in the past 7 days (same definition as 2019) ---------------------
use "$ind_16/id3.dta", clear
gen idp16 = (hhid + pid/100)*100
foreach var of varlist hhid - i386_99 {
    rename `var' `var'16
}
gen work716 = (i30116 == 1 | i30216 == 1 | i30316 == 1 | i30416 == 1)
tab work716
save "$temporary/id3_2016", replace

* --- id5: decision making (i500) and gender attitudes (i501) ------------------
use "$ind_16/id5.dta", clear
rename i501_1 Imp_deci_hus
rename i501_3 W_ff_if_mom
rename i501_6 Unieduc_imp_boy
rename i501_2 Man_earn_W_home
rename i501_5 Huscareer_imp_wife
rename i501_4 W_work_good
rename i501_8 Wife_ff_eq_pay
rename i501_9 No_WWOH_reli
rename i501_7 Both_contri_inc

gen idp16 = (hhid + pid/100)*100

* Drop "don't know" (99) answers to the attitude items
foreach v of varlist `attitudes' {
    estpost tabulate `v'
    eststo `v'
}
foreach v of varlist `attitudes' {
    drop if `v'==99
}
eststo clear
foreach v of varlist `attitudes' {
    estpost tabulate `v'
    eststo `v'
}

foreach v of varlist hhid - i513 {
    rename `v' `v'16
}

* Strong agreement (= 4) with each attitude item in 2016
gen decihus4  = Imp_deci_hus16 == 4
gen earnhome4 = Man_earn_W_home16 == 4
gen momwork4  = W_ff_if_mom16 == 4
gen workgood4 = W_work_good16 == 4
gen hus4      = Huscareer_imp_wife16 == 4
gen eduboy4   = Unieduc_imp_boy16 == 4
gen bothcont4 = Both_contri_inc16 == 4
gen eqpay4    = Wife_ff_eq_pay16 == 4
gen nowwoh4   = No_WWOH_reli16 == 4
foreach v of varlist decihus4 - nowwoh4 {
    rename `v' `v'16
}
save "$temporary/id5_2016", replace

* --- hh1a: household roster, number of children under 18 -------------------------
use "$hh_16/hh1a.dta", clear
gen idp16 = (hhid + pid/100)*100
gen age18 = h103a < 18
egen num_child = total(age18), by(hhid)
foreach var of varlist hhid - num_child {
    rename `var' `var'16
}
rename idp1616 idp16
save "$temporary/hh1a_2016", replace

* --- hh0: household cover sheet; oblast SOATO codes 417xx -> xx -----------------
use "$hh_16/hh0.dta", clear
foreach var of varlist ih2013 - langh {
    rename `var' `var'16
}
foreach c in 2 3 4 5 6 7 8 11 21 {
    replace oblast16 = `c' if oblast16 == 41700 + `c'
}
save "$temporary/hh0_2016", replace


*******************************************************************************
* 3. 2013
*******************************************************************************

* --- id1: risk attitude ---------------------------------------------------------
use "$ind_13/id1.dta", clear
gen idp13 = (hhid + pid/100)*100
foreach var of varlist hhid - i106 {
    rename `var' `var'13
}
rename i10613 risk13
save "$temporary/id1_2013", replace

* --- id3a: work in the past 7 days (same definition as 2019) --------------------
use "$ind_13/id3a.dta", clear
gen idp13 = (hhid + pid/100)*100
foreach var of varlist hhid - i304 {
    rename `var' `var'13
}
gen work713 = (i30113 == 1 | i30213 == 1 | i30313 == 1 | i30413 == 1)
tab work713
save "$temporary/id3a_2013", replace

* --- id5b: decision making (items are mapped to the 2016 items in 05) -----------
use "$ind_13/id5b.dta", clear
gen idp13 = (hhid + pid/100)*100
foreach var of varlist hhid - i500_34 {
    rename `var' `var'13
}
save "$temporary/id5b_2013", replace

* --- id5e: gender attitudes -----------------------------------------------------
use "$ind_13/id5e.dta", clear
gen idp13 = (hhid + pid/100)*100

rename i537_1  Imp_deci_hus
rename i537_2  Man_earn_W_home
rename i537_3  W_ff_if_mom
rename i537_4  W_work_good
rename i537_5  Huscareer_imp_wife
rename i537_6  Unieduc_imp_boy
rename i537_7  Both_contri_inc
rename i537_8  Wife_ff_eq_pay
rename i537_10 No_WWOH_reli

* Strong agreement (= 4) with each attitude item in 2013
gen decihus4  = Imp_deci_hus == 4
gen earnhome4 = Man_earn_W_home == 4
gen momwork4  = W_ff_if_mom == 4
gen workgood4 = W_work_good == 4
gen hus4      = Huscareer_imp_wife == 4
gen eduboy4   = Unieduc_imp_boy == 4
gen bothcont4 = Both_contri_inc == 4
gen eqpay4    = Wife_ff_eq_pay == 4
gen nowwoh4   = No_WWOH_reli == 4

* Drop "don't know" (99) answers to the attitude items
foreach v of varlist `attitudes' {
    estpost tabulate `v'
    eststo `v'
}
foreach v of varlist `attitudes' {
    drop if `v'==99
}
eststo clear
foreach v of varlist `attitudes' {
    estpost tabulate `v'
}
* Check that no out-of-range values remain
eststo clear
foreach v of varlist `attitudes' {
    estpost su `v'
}

foreach var of varlist hhid - nowwoh4 {
    rename `var' `var'13
}
rename idp1313 idp13
save "$temporary/id5e_2013", replace

* --- hh0: household cover sheet -------------------------------------------------
use "$hh_13/hh0.dta", clear
foreach var of varlist hhid - oblast {
    rename `var' `var'13
}
save "$temporary/hh0_2013", replace

* --- hh1a: household roster, number of children under 18 -------------------------
use "$hh_13/hh1a.dta", clear
gen idp13 = (hhid + pid/100)*100
gen age18 = h103a < 18
egen num_child = total(age18), by(hhid)
foreach var of varlist hhid - num_child {
    rename `var' `var'13
}
rename idp1313 idp13
save "$temporary/hh1a_2013", replace
