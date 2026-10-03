*******************************************************************************
* 04_heterogeneity.do
* Employment-history outcomes from the 12-month activity calendar,
* heterogeneity analysis, and multiple hypothesis testing.
* Produces Tables 6-8 and Appendix Tables 10-13 of the paper.
*
*   Input : $temporary/analysis_2y_long_DDD_2.dta   (from 03_main_analysis.do)
*           LiK module 3D (id3d.dta), 2016 and 2019
*   Output: $temporary/analysis_2y_long_DDD_2_12m.dta
*           $fig/mht_gender_norms.xlsx
*
* Run via code/00_master.do, which sets the project root and path globals.
*******************************************************************************


*******************************************************************************
* 1. Monthly activity calendar (past 12 months) from module 3D
*******************************************************************************

* 2016: id3d is long (one row per person x activity) with 0/1 month dummies;
* convert to one row per person holding the activity code for each month.
use "$ind_16/id3d.dta", clear
gen idp16 = (hhid + pid/100)*100
foreach m in 1115 1215 0116 0216 0316 0416 0516 0616 0716 0816 0916 1016 {
    replace i390_`m' = cond(i390_`m'==1, activity, .)
}
collapse (min) i390_*, by(idp16)
foreach m in 1115 1215 0116 0216 0316 0416 0516 0616 0716 0816 0916 1016 {
    label var i390_`m' "LiK16 main activity code, past 12 months: `m'"
}
tempfile cal16
save `cal16'

* 2019: id3d is already one row per person with the activity code by month.
use "$ind_19/id3d.dta", clear
gen idp19 = (hhid + pid/100)*100
keep idp19 i382_*
tempfile cal19
save `cal19'

use "$temporary/analysis_2y_long_DDD_2.dta", clear
merge m:1 idp16 using `cal16', keep(1 3) nogen
merge m:1 idp19 using `cal19', keep(1 3) nogen update
foreach v of varlist i390_* {
    replace `v' = . if year != 16
}
foreach v of varlist i382_* {
    replace `v' = . if year != 19
}

xtset idpp year

capture drop post_year
gen post_year = (year == 19)
label var post_year "Post period: 2019"


*******************************************************************************
* 2. Employment-history variables (survey-relative past 12 months)
*
*    act_m1-act_m12   main activity code in each month
*    emp_m1-emp_m12   employed in the month (activity codes 4-10)
*    any_work_12m     employed in at least one of the 12 months
*******************************************************************************

* Month m = 1 is the earliest month of the 12-month window
local m16 1115 1215 0116 0216 0316 0416 0516 0616 0716 0816 0916 1016
forvalues m = 1/12 {
    capture drop act_m`m' emp_m`m'
    local c16 : word `m' of `m16'
    gen act_m`m' = cond(year==16, i390_`c16', cond(year==19, i382_`m', .))
}

* Variable lists are built explicitly, so that they do not depend on the
* order of variables in the dataset (as emp_m1-emp_m12 would).
foreach s in act emp agri nonagri housewife other_work {
    local `s'_vars
    forvalues m = 1/12 {
        local `s'_vars ``s'_vars' `s'_m`m'
    }
}

* --- Any employment -----------------------------------------------------------
forvalues m = 1/12 {
    gen emp_m`m' = .
    replace emp_m`m' = 1 if inrange(act_m`m', 4, 10)
    replace emp_m`m' = 0 if !missing(act_m`m') & !inrange(act_m`m', 4, 10)
    label var emp_m`m' "Employed in relative month `m'"
}

capture drop any_work_12m emp_months emp_nonmiss emp_share always_emp
egen any_work_12m = rowmax(`emp_vars')
label var any_work_12m "Any work during the past 12 months"

egen emp_months = rowtotal(`emp_vars'), missing
* Number of months with a non-missing activity (normally 12)
egen emp_nonmiss = rownonmiss(`emp_vars')
tab emp_nonmiss
drop if emp_nonmiss == 0

gen emp_share = emp_months / emp_nonmiss if emp_nonmiss > 0

* always_emp = 1: worked in every observed month
* always_emp = 0: did not work in at least one observed month
* always_emp = .: all 12 months missing
gen always_emp = emp_months == emp_nonmiss if emp_nonmiss > 0

label var emp_months "Number of employed months in past 12 months"
label var emp_share  "Share of employed months in past 12 months"
label var always_emp "Worked all observed months in past 12 months"

* --- Baseline (2016) employment history, carried to both years -----------------
foreach v in emp_months emp_share any_work_12m always_emp {
    capture drop `v'_16 `v'_16b
    bysort idpp (year): gen `v'_16 = `v' if year == 16
    bysort idpp: egen `v'_16b = max(`v'_16)
    label var `v'_16b "Baseline 2016 `v'"
}

capture drop high_emp16 any_emp16 full_emp16
* Worked in at least half of the observed months in 2016
gen high_emp16 = emp_share_16b >= .5 if !missing(emp_share_16b)
* Worked in at least one month in 2016
gen any_emp16  = any_work_12m_16b == 1 if !missing(any_work_12m_16b)
* Worked in all observed months in 2016
gen full_emp16 = always_emp_16b == 1 if !missing(always_emp_16b)

label var high_emp16 "Baseline employed at least half of past 12 months"
label var any_emp16  "Baseline worked at least one month"
label var full_emp16 "Baseline worked all observed months"

* --- Monthly activity types ---------------------------------------------------
*   agri       4 employee in agriculture, 6 own-account worker in agriculture
*   nonagri    5 employee in non-agriculture, 7 own-account worker in non-agriculture
*   housewife  12
*   other_work 5, 7, 8 employer, 9 producers' cooperative, 10 contributing family worker
local codes_agri       4, 6
local codes_nonagri    5, 7
local codes_housewife  12
local codes_other_work 5, 7, 8, 9, 10

local lab_agri       "Agricultural work"
local lab_nonagri    "Non-agricultural work"
local lab_housewife  "Housewife"
local lab_other_work "Other work"

forvalues m = 1/12 {
    capture drop agri_m`m' nonagri_m`m' housewife_m`m' other_work_m`m'
}

foreach s in agri nonagri housewife {
    forvalues m = 1/12 {
        gen `s'_m`m' = .
        replace `s'_m`m' = 1 if inlist(act_m`m', `codes_`s'')
        replace `s'_m`m' = 0 if !missing(act_m`m') & !inlist(act_m`m', `codes_`s'')
        label var `s'_m`m' "`lab_`s'' in relative month `m'"
    }
}

capture drop act_nonmiss
egen act_nonmiss = rownonmiss(`act_vars')
label var act_nonmiss "Number of non-missing main activity months"

* Months, shares, and any experience in the past 12 months
capture drop agri_months nonagri_months housewife_months
capture drop agri_share nonagri_share housewife_share
capture drop any_agri_12m any_nonagri_12m any_housewife_12m
foreach s in agri nonagri housewife {
    egen `s'_months = rowtotal(``s'_vars'), missing
}
foreach s in agri nonagri housewife {
    gen `s'_share = `s'_months / act_nonmiss if act_nonmiss > 0
}
foreach s in agri nonagri housewife {
    gen any_`s'_12m = `s'_months > 0 if act_nonmiss > 0
}

label var agri_months       "Number of agricultural work months in past 12 months"
label var nonagri_months    "Number of non-agricultural work months in past 12 months"
label var housewife_months  "Number of housewife months in past 12 months"
label var agri_share        "Share of agricultural work months in past 12 months"
label var nonagri_share     "Share of non-agricultural work months in past 12 months"
label var housewife_share   "Share of housewife months in past 12 months"
label var any_agri_12m      "Any agricultural work during past 12 months"
label var any_nonagri_12m   "Any non-agricultural work during past 12 months"
label var any_housewife_12m "Any housewife months during past 12 months"

* Other work
capture drop other_work_months other_work_share any_other_work_12m
capture drop main_housewife_12m main_agri_12m main_nonagri_12m main_other_work_12m
forvalues m = 1/12 {
    gen other_work_m`m' = .
    replace other_work_m`m' = 1 if inlist(act_m`m', `codes_other_work')
    replace other_work_m`m' = 0 if !missing(act_m`m') & !inlist(act_m`m', `codes_other_work')
    label var other_work_m`m' "Other work in relative month `m'"
}
egen other_work_months = rowtotal(`other_work_vars'), missing
gen other_work_share = other_work_months / act_nonmiss if act_nonmiss > 0
gen any_other_work_12m = other_work_months > 0 if act_nonmiss > 0

label var other_work_months  "Other work months in past 12 months"
label var other_work_share   "Share of other work months in past 12 months"
label var any_other_work_12m "Any other work during past 12 months"

* --- Main activity over the past 12 months ------------------------------------
* Strict plurality: = 1 if the category has more months than each of the
* other two categories (agriculture, other work, housewife); ties are 0.
* Example: 5 months agriculture, 3 other work, 4 housewife -> main_agri_12m = 1.
gen main_housewife_12m = .
replace main_housewife_12m = 1 if housewife_months > agri_months & housewife_months > other_work_months & housewife_months > 0
replace main_housewife_12m = 0 if !missing(housewife_months, agri_months, other_work_months) & main_housewife_12m != 1
label var main_housewife_12m "Main activity housewife in past 12 months"

gen main_agri_12m = .
replace main_agri_12m = 1 if agri_months > housewife_months & agri_months > other_work_months & agri_months > 0
replace main_agri_12m = 0 if !missing(housewife_months, agri_months, other_work_months) & main_agri_12m != 1
label var main_agri_12m "Main activity agricultural work in past 12 months"

gen main_other_work_12m = .
replace main_other_work_12m = 1 if other_work_months > agri_months & other_work_months > housewife_months & other_work_months > 0
replace main_other_work_12m = 0 if !missing(housewife_months, agri_months, other_work_months) & main_other_work_12m != 1
label var main_other_work_12m "Main activity other work in past 12 months"

* Alias kept for older table code; this is other work, not only codes 5 and 7
gen main_nonagri_12m = main_other_work_12m
label var main_nonagri_12m "Main activity other work in past 12 months"

* --- Consistency checks ---------------------------------------------------------
capture drop check_work_decomp check_main_type
* Employed months decompose into agricultural work and other work
gen check_work_decomp = emp_months - agri_months - other_work_months
tab check_work_decomp, missing
* Main activity types are mutually exclusive (0 = tie or none strictly largest)
egen check_main_type = rowtotal(main_agri_12m main_other_work_12m main_housewife_12m), missing
tab check_main_type, missing

* --- Rescaled treatment -------------------------------------------------------
* DV_rate_16 is in percent (see 00_dv_rate.do), so one unit of the rescaled
* variable corresponds to 0.1 percentage points of the DV incidence rate.
gen DV_rate_16_cs = DV_rate_16_c / 0.10
label var DV_rate_16_cs "DV rate in 2016, centered, per 0.1 percentage points"

save "$temporary/analysis_2y_long_DDD_2_12m.dta", replace


*******************************************************************************
* 3. Helper programs
*******************************************************************************

capture program drop ddd_boot
program define ddd_boot, eclass
    * Wild cluster bootstrap p-value (Webb weights) for one coefficient of the
    * current estimates, attached to stored estimates <name> as e(bootp).
    * term(): coefficient to test. If omitted, the DDD term is looked up in
    * e(b) as the coefficient containing 1.post_year, 1.female, and dvvar().
    syntax namelist(max=1) [, Term(string) DVvar(string) Controls(string)]
    if "`term'" == "" {
        local coefname : colfullnames e(b)
        foreach v of local coefname {
            if strpos("`v'", "1.post_year") & strpos("`v'", "1.female") & strpos("`v'", "`dvvar'") {
                local term `v'
            }
        }
    }
    boottest `term', cluster(oblast) reps(9999) seed(1234) weight(webb) nograph noci
    matrix bootp = J(1,1,r(p))
    matrix colnames bootp = `term'
    estadd matrix bootp = bootp: `namelist'
    estadd scalar clusters = e(N_clust): `namelist'
    estadd scalar reps = 9999: `namelist'
    estadd local controls "`controls'": `namelist'
end

capture program drop ddd_employment
program define ddd_employment
    * DDD for each employment outcome on the data in memory, without (nc#)
    * and with (c#) baseline controls; reports the DDD coefficient only.
    syntax, Outcomes(string) Controls(string)
    local dddcoef 1.post_year#1.female#c.DV_rate_16_cs
    local notes addnotes("Wild bootstrap p-values in parentheses. Wild bootstrap uses Webb weights. Stars based on wild bootstrap p-values." "Individual FE absorbed; SEs clustered at oblast." "DV rate is scaled so one unit equals 0.1 percentage points.")
    local tabopts keep(`dddcoef') cells(b(fmt(3) star pvalue(bootp)) bootp(par fmt(3))) stats(controls clusters reps, labels("Controls" "Clusters" "Reps")) starlevels(* 0.10 ** 0.05 *** 0.01) `notes' varwidth(35)

    eststo clear
    local i = 1
    local nc_list
    local c_list
    foreach y of local outcomes {
        eststo nc`i': xtreg `y' i.post_year##c.DV_rate_16_cs##i.female if act_nonmiss > 0, fe vce(cluster oblast)
        ddd_boot nc`i', term(`dddcoef') controls("")
        local nc_list `nc_list' nc`i'
        local ++i
    }
    local i = 1
    foreach y of local outcomes {
        eststo c`i': xtreg `y' i.post_year##c.DV_rate_16_cs##i.female `controls' if act_nonmiss > 0, fe vce(cluster oblast)
        ddd_boot c`i', dvvar(DV_rate_16_cs) controls("Yes")
        local c_list `c_list' c`i'
        local ++i
    }
    esttab `nc_list', `tabopts'
    esttab `c_list', `tabopts'
end

capture program drop mht_adjust
program define mht_adjust
    * Holm-adjusted p-values and Benjamini-Hochberg q-values for the p-values
    * stored in a dataset with variables Outcome and Wild_p.
    syntax using/ [, Export(string)]
    preserve
    use "`using'", clear

    sort Wild_p
    gen rank = _n
    gen m = _N

    gen Holm_raw = (m - rank + 1) * Wild_p
    gen Holm_adj_p = Holm_raw
    replace Holm_adj_p = max(Holm_adj_p, Holm_adj_p[_n-1]) if _n > 1
    replace Holm_adj_p = 1 if Holm_adj_p > 1

    gen BH_raw = Wild_p * m / rank
    gsort -rank
    gen BH_FDR_q = BH_raw
    replace BH_FDR_q = min(BH_FDR_q, BH_FDR_q[_n-1]) if _n > 1
    replace BH_FDR_q = 1 if BH_FDR_q > 1

    sort rank
    format Wild_p Holm_adj_p BH_FDR_q %9.3f
    list Outcome Wild_p Holm_adj_p BH_FDR_q, noobs separator(0)
    if "`export'" != "" {
        export excel using "`export'", firstrow(variables) replace
    }
    restore
end


*******************************************************************************
* 4. DDD for employment outcomes: full sample and subsamples
*    (Tables 6 and 7; Appendix Table 11)
*******************************************************************************
local outcomes work7 emp_months agri_months other_work_months housewife_months main_agri_12m main_other_work_12m main_housewife_12m

local bl_ctrl c.num_child_16b#i.post_year c.age_16b#i.post_year c.age2_16b#i.post_year c.log_cons_food_16b#i.post_year c.log_cons_nonfood_16b#i.post_year
local bl_ctrl_m i.married2016b#i.post_year

* Panel A: full sample
ddd_employment, outcomes(`outcomes') controls(`bl_ctrl' `bl_ctrl_m')

* Panels B-D: married at baseline, below age 40 at baseline, urban at baseline
foreach cond in "married2016b == 1" "age_16b < 40" "residence16 == 1" {
    preserve
    keep if `cond'
    ddd_employment, outcomes(`outcomes') controls(`bl_ctrl' `bl_ctrl_m')
    restore
}


*******************************************************************************
* 5. Quadruple interactions: test differences between subsamples
*    (Table 8; Appendix Table 12)
*******************************************************************************
capture drop young40_16
gen young40_16 = age_16b < 40 if !missing(age_16b)
label var young40_16 "Age below 40 at baseline"

local pre_married2016b mar
local pre_young40_16   young
local pre_residence16  urb
local note_married2016b "Coefficient is the additional DDD effect for baseline married individuals."
local note_young40_16   "Coefficient is the additional DDD effect for individuals below age 40 at baseline."
local note_residence16  "Coefficient is the additional DDD effect for urban individuals relative to rural individuals."

eststo clear
foreach het in married2016b young40_16 residence16 {
    local qcoef 1.post_year#1.female#1.`het'#c.DV_rate_16_cs
    local p `pre_`het''
    local i = 1
    local q_list
    foreach y of local outcomes {
        eststo `p'_nc`i': xtreg `y' i.post_year##c.DV_rate_16_cs##i.female##i.`het' if act_nonmiss > 0, fe vce(cluster oblast)
        ddd_boot `p'_nc`i', term(`qcoef') controls("")
        local q_list `q_list' `p'_nc`i'
        local ++i
    }
    esttab `q_list', keep(`qcoef') cells(b(fmt(3) star pvalue(bootp)) bootp(par fmt(3))) stats(controls clusters reps, labels("Controls" "Clusters" "Reps")) starlevels(* 0.10 ** 0.05 *** 0.01) addnotes("Wild bootstrap p-values in parentheses. Wild bootstrap uses Webb weights. Stars based on wild bootstrap p-values." "Individual FE absorbed; SEs clustered at oblast." "DV rate is scaled so one unit equals 0.1 percentage points." "`note_`het''") varwidth(35)
}


*******************************************************************************
* 6. Descriptive statistics of employment history by year, area, and gender
*    (Appendix Table 10)
*******************************************************************************
preserve

capture drop year_table
gen year_table = year
replace year_table = 2000 + year if inlist(year, 16, 19)

capture drop area
gen area = .
replace area = 0 if residence16 == 0
replace area = 1 if residence16 == 1
label define area_lbl 0 "rural" 1 "urban", replace
label values area area_lbl

capture drop gender
gen gender = .
replace gender = 0 if female == 0
replace gender = 1 if female == 1
label define gender_lbl 0 "men" 1 "women", replace
label values gender gender_lbl

collapse (count) N = idpp (mean) main_agri_12m main_other_work_12m main_housewife_12m agri_months other_work_months housewife_months, by(year_table area gender)

* Main activity dummies shown as percentages
foreach v in main_agri_12m main_other_work_12m main_housewife_12m {
    replace `v' = `v' * 100
}
format main_agri_12m main_other_work_12m main_housewife_12m agri_months other_work_months housewife_months %9.1f

sort year_table area gender
list year_table area gender N main_agri_12m main_other_work_12m main_housewife_12m agri_months other_work_months housewife_months, noobs separator(0)

restore


*******************************************************************************
* 7. Multiple hypothesis testing (Appendix Table 13)
*    Original wild bootstrap p-value, Holm-adjusted p, and BH-FDR q,
*    within each outcome family. Full sample, no controls.
*******************************************************************************

* --- Panels A-C: employment outcome families (Webb weights) --------------------
local family_A work7 emp_months
local family_B other_work_months housewife_months agri_months
local family_C main_other_work_12m main_housewife_12m main_agri_12m

foreach f in A B C {
    tempfile mht_raw
    tempname mhtpost
    postfile `mhtpost' str40 Outcome double Wild_p using `mht_raw', replace

    foreach y of local family_`f' {
        quietly xtreg `y' i.post_year##c.DV_rate_16_cs##i.female if act_nonmiss > 0, fe vce(cluster oblast)
        local coefname : colfullnames e(b)
        local dddname
        foreach v of local coefname {
            if strpos("`v'", "1.post_year") & strpos("`v'", "1.female") & strpos("`v'", "DV_rate_16_cs") {
                local dddname `v'
            }
        }
        quietly boottest `dddname', cluster(oblast) reps(9999) seed(1234) weight(webb) nograph noci
        post `mhtpost' ("`y'") (r(p))
    }
    postclose `mhtpost'

    di as text _n "Panel `f'"
    mht_adjust using `mht_raw'
}

* --- Panel D: gender norm outcomes ----------------------------------------------
* Same regressions and bootstrap settings as Table 3 columns (1) and (3):
* DV rate in percent, year FE, sample restricted to respondents who strongly
* agreed with the statement in 2016, Webb weights, seed 12345. The analysis
* sample of 03 is used (the 12-month calendar restriction above does not
* apply), so the unadjusted p-values equal those reported in Table 3.
preserve
use "$temporary/analysis_2y_long_DDD_2.dta", clear
local norm_outcomes No_WWOH_reli Huscareer_imp_wife
local smp_No_WWOH_reli       "nowwoh416 == 1"
local smp_Huscareer_imp_wife "hus4 == 1"

tempfile mht_norm_raw
tempname mhtpost
postfile `mhtpost' str40 Outcome double Wild_p using `mht_norm_raw', replace

foreach y of local norm_outcomes {
    quietly reghdfe `y' c.DV_rate_16_c##i.female##i.post_year i.year if `smp_`y'', absorb(idpp) vce(cluster oblast)
    quietly boottest 1.female#1.post_year#c.DV_rate_16_c, cluster(oblast) reps(9999) seed(12345) weight(webb) nograph noci
    post `mhtpost' ("`y'") (r(p))
}
postclose `mhtpost'
restore

di as text _n "Panel D"
mht_adjust using `mht_norm_raw', export("$fig/mht_gender_norms.xlsx")
