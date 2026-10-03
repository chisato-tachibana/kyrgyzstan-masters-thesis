*******************************************************************************
* 03_main_analysis.do
* Build the 2016-2019 analysis panel and estimate the triple-difference (DDD)
* models. Tables 1-5 of the paper are produced in sections 6 and 7.3;
* gender-specific marginal effects (appendix) in section 7.4; gender
* attitudes in the full sample (appendix) in section 7.5.
*
*   Input : $temporary/merged_roster_2y_additional.dta   (from 02_merge.do)
*   Output: $temporary/analysis_2y_long_DDD_2.dta         (used by 04)
*           $fig/table1_summary.tex
*           $fig/table2_ttest.tex
*           $fig/table3_gender_attitudes.tex
*           $fig/table4_risk_decision_making.tex
*           $fig/table5_work.tex
*           $fig/tableA_gender_marginal_effects.tex
*           $fig/tableA_attitudes_full_sample.tex
*
* Run via code/00_master.do, which sets the project root and path globals.
*******************************************************************************


*******************************************************************************
* 1. Reshape to long format (one row per individual x survey year)
*******************************************************************************
use "$temporary/merged_roster_2y_additional.dta", clear

rename (cons16 cons19) (consp16 consp19)
* Decision-making items are already named i500_<k>_16 / i500_<k>_19 in 02

local dm_items
forvalues k = 1/17 {
    local dm_items `dm_items' i500_`k'_
}

reshape long risk i301 i302 i303 i304 work7 `dm_items' Imp_deci_hus Man_earn_W_home W_ff_if_mom W_work_good Huscareer_imp_wife Unieduc_imp_boy Both_contri_inc Wife_ff_eq_pay No_WWOH_reli h108 num_child marriedyes consp cons_food log_cons_food cons_nf cons_nonfood log_cons_nonfood, i(idpp) j(year)
* Note: highest completed education is not included yet

save "$temporary/merged_roster_2y_additional_long.dta", replace

xtset idpp year


*******************************************************************************
* 2. Outcomes
*******************************************************************************

* --- Female decision-making index -------------------------------------------
* Bargaining power of "the wife" and of "women in the household" cannot be
* separately identified, so the index only records whether a woman takes part
* in each of the 17 household decisions (module i500).
* Response codes: 1 = myself, 2 = my spouse, 3 = jointly with spouse,
* 7 = all female members, 8 = all members together.

* 1 if there is at least one woman in the household
bysort hhidp year: egen female_in_hh = max(female == 1)

forvalues j = 1/17 {
    gen fem_dm_`j' = .
    * female respondent: myself
    replace fem_dm_`j' = 1 if gender == 2 & i500_`j'_ == 1
    * male respondent: my spouse (wife)
    replace fem_dm_`j' = 1 if gender == 1 & i500_`j'_ == 2
    * jointly with spouse
    replace fem_dm_`j' = 1 if i500_`j'_ == 3
    * all female household members
    replace fem_dm_`j' = 1 if i500_`j'_ == 7
    * all household members together, with at least one woman in the household
    replace fem_dm_`j' = 1 if i500_`j'_ == 8 & female_in_hh == 1
    replace fem_dm_`j' = 0 if fem_dm_`j' == .
}
egen fem_dm_sum = rowtotal(fem_dm_1-fem_dm_17)
* Share of decisions (0-1)
gen fem_dm_ave = fem_dm_sum / 17

* --- Risk attitude, standardized to the 2016 distribution ---------------------
* All years are scaled by the 2016 mean and SD (2016: mean 0, SD 1)
summarize risk if year == 16
local m  = r(mean)
local sd = r(sd)
assert `sd' > 0
gen risk_std = (risk - `m') / `sd'
label var risk_std "Risk (std. to 2016 mean & SD)"
summarize risk_std if year == 16


*******************************************************************************
* 3. Treatment intensity: reported DV incidence among women by oblast, 2016,
*    in percent (built in 00_dv_rate.do from National Statistical Committee
*    data). See Section 4 of the paper.
*******************************************************************************
merge m:1 oblast using "$temporary/dv_rate_baseline.dta", keepusing(DV_rate_16) keep(1 3) nogen


*******************************************************************************
* 4. Age, cohorts, and post-reform indicator
*******************************************************************************
gen year_abs = 2000 + year
gen age = year_abs - byear
drop if age < 18

* Age at baseline (2016)
bysort idpp (year): gen age_16 = age if year_abs == 2016
bysort idpp: egen age_16b = max(age_16)
* In 2016 rows, age_16b must equal age
by idpp: assert age_16b == age if year_abs == 2016
count if missing(age_16b)

gen age2_16b = age_16b^2
label var age_16b  "Age at 2016"
label var age2_16b "Age^2 at 2016"
label var work7    "take 1 if worked past 7 days"

* Birth cohorts by decade: 1 = before 1940, 2 = 1940s, ..., 7 = 1990s
capture drop age_cohort
gen age_cohort = 0
replace age_cohort = 1 if byear < 1940
forvalues k = 2/7 {
    replace age_cohort = `k' if byear >= 1920 + 10*`k' & byear < 1930 + 10*`k'
}

capture drop age2040
gen age2040 = inlist(age_cohort, 5, 6, 7)
label var age2040 "Cohorts 1970-1999"

* Age category
gen agecat = .
replace agecat = 1 if inrange(age, 20, 29)
replace agecat = 2 if inrange(age, 30, 39)
replace agecat = 3 if inrange(age, 40, 49)
replace agecat = 4 if inrange(age, 50, 59)
replace agecat = 5 if age >= 60
label define agecat 1 "20s" 2 "30s" 3 "40s" 4 "50s" 5 "60+"
label values agecat agecat

* Post-reform indicator
* (for the 2013-2016 baseline analysis, post_year = year == 16 is used instead)
gen post_year = year == 19

save "$temporary/analysis_2y_long.dta", replace


*******************************************************************************
* 5. Baseline (2016) covariates, held constant within individual
*******************************************************************************
replace marriedyes = 0 if marriedyes == 2

bysort idpp (year): gen married2016  = marriedyes       if year == 16
bysort idpp (year): gen num_child_16 = num_child        if year == 16
bysort idpp (year): gen lcf_16       = log_cons_food    if year == 16
bysort idpp (year): gen lcnf_16      = log_cons_nonfood if year == 16

bysort idpp: egen married2016b         = max(married2016)
bysort idpp: egen num_child_16b        = max(num_child_16)
bysort idpp: egen log_cons_food_16b    = max(lcf_16)
bysort idpp: egen log_cons_nonfood_16b = max(lcnf_16)

label var married2016b         "Married (2016 baseline)"
label var num_child_16b        "# children (2016 baseline)"
label var log_cons_food_16b    "Log food cons. (2016 baseline)"
label var log_cons_nonfood_16b "Log non-food cons. (2016 baseline)"

* Mean-center the DV rate so that the Post coefficient is evaluated at the
* average DV rate (mean taken before restricting to the balanced panel)
summarize DV_rate_16
gen double DV_rate_16_c = DV_rate_16 - r(mean)

* Employment variables
gen flfp = work7 if female == 1
label var flfp "Female Labor Force Participation (female sample only)"
gen work7_male = work7 if female == 0
label var work7_male "Male Labor Force Participation (male sample only)"

* Balanced panel: keep individuals observed in both 2016 and 2019
bysort idpp: keep if _N == 2

* Urban residence at baseline: 1 = urban, 0 = rural (originally coded 1 / 2)
replace residence16 = 0 if residence16 == 2

save "$temporary/analysis_2y_long_DDD.dta", replace
save "$temporary/analysis_2y_long_DDD_2.dta", replace


*******************************************************************************
* 6. Descriptive statistics (Tables 1 and 2)
*******************************************************************************

* --- Table 1: summary statistics, analysis sample ----------------------------
* Number of observations per oblast
preserve
collapse (count) N = idpp, by(oblast)
summarize N
restore

preserve
bysort oblast: gen oblast_n = _N if _n == 1
label var oblast_n "Average sample size per oblast"
estpost summarize work7 No_WWOH_reli Huscareer_imp_wife risk_std fem_dm_ave DV_rate_16 DV_rate_16_c female post_year oblast_n num_child_16b age_16b log_cons_food_16b log_cons_nonfood_16b married2016b nowwoh416 hus416
esttab using "$fig/table1_summary.tex", cells("mean(fmt(3)) sd(fmt(3)) min max") label booktabs nonumbers nomtitles noobs replace
esttab, cells("mean(fmt(3)) sd(fmt(3)) min max count") label noobs varwidth(30)
restore

* --- Table 2: 2016 vs 2019 means (two-sample t-tests) -----------------------
estpost ttest work7 No_WWOH_reli Huscareer_imp_wife risk_std fem_dm_ave marriedyes female, by(year)
esttab using "$fig/table2_ttest.tex", cells("mu_1(fmt(3)) mu_2(fmt(3)) b(fmt(3) star) p(fmt(4))") starlevels(* 0.10 ** 0.05 *** 0.01) label booktabs nonumbers nomtitles noobs replace
esttab, cells("mu_1(fmt(3)) mu_2(fmt(3)) b(fmt(3) star) p(fmt(4))") starlevels(* 0.10 ** 0.05 *** 0.01) label noobs varwidth(30)


*******************************************************************************
* 7. DDD estimation (Tables 3-5)
*
*    y_it = b1 Post + b2 Post x DV + b3 Post x Female + b4 Post x DV x Female
*           + Pre x X_i,2016 + individual FE + year FE + e_it
*
*    How to read the coefficients:
*      Post x DV          : intensity DID for men (female = 0)
*      Post x DV x Female : additional effect for women (the core DDD term),
*                           i.e. how much the post-period gender gap changes
*                           when the DV rate is one unit higher
*
*    Only 9 oblast clusters, so inference uses the wild cluster bootstrap
*    (Webb weights, 9,999 replications; Roodman et al. 2019).
*******************************************************************************

* --- Helper programs ----------------------------------------------------------

capture program drop ddd_wild
program define ddd_wild, eclass
    * Run boottest on each listed coefficient of the current estimates and
    * attach the p-values as e(wildp), so esttab can report them.
    syntax anything(name=terms) [, reps(integer 9999) seed(integer 12345)]
    tempname P
    matrix `P' = J(1, `: word count `terms'', .)
    matrix colnames `P' = `terms'
    local j 0
    foreach t of local terms {
        local ++j
        quietly boottest `t', cluster(oblast) reps(`reps') seed(`seed') weight(webb) nograph noci
        matrix `P'[1, `j'] = r(p)
    }
    estadd matrix wildp = `P'
    estadd scalar clusters = e(N_clust)
    estadd scalar reps = `reps'
end

capture program drop boot_main
program define boot_main
    * Wild bootstrap tests for the four DDD terms
    foreach t in 1.post_year 1.post_year#c.DV_rate_16_c 1.post_year#1.female 1.post_year#c.DV_rate_16_c#1.female {
        boottest `t', cluster(oblast) reps(9999) seed(12345) weight(webb)
    }
end

capture program drop boot_ctrl
program define boot_ctrl
    * Wild bootstrap tests for the baseline-control terms
    foreach t in 0.post_year#c.num_child_16b 0.post_year#c.age_16b 0.post_year#c.age2_16b 0.post_year#c.log_cons_food_16b 0.post_year#c.log_cons_nonfood_16b 0.post_year#1.married2016b {
        boottest `t', cluster(oblast) reps(9999) seed(12345) weight(webb)
    }
end

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

* --- Specification ------------------------------------------------------------
local ddd c.DV_rate_16_c##i.female##i.post_year i.year

* Baseline controls interacted with the period (factor-variable form)
local bl_ctrl      i.post_year#c.(num_child_16b age_16b age2_16b log_cons_food_16b log_cons_nonfood_16b)
local bl_ctrl_m    i.married2016b#i.post_year
local bl_ctrl_city i.residence16#i.post_year

* The same controls as explicit variables, used for the paper tables. Because
* the covariates are time-invariant, the 1.post_year interactions are collinear
* with the individual FE and dropped; the estimated terms are the pre-period
* (post = 0) interactions, so X x Post equals minus the reported coefficient.
local ctrl_terms
foreach v in num_child_16b age_16b age2_16b log_cons_food_16b log_cons_nonfood_16b married2016b {
    gen pre_`v' = `v' * (1 - post_year)
    local ctrl_terms `ctrl_terms' pre_`v'
}

* DDD coefficient names as stored in e(b)
local main_terms 1.post_year 1.post_year#c.DV_rate_16_c 1.female#1.post_year 1.female#1.post_year#c.DV_rate_16_c

* Outcomes and estimation samples. Gender-attitude models are restricted to
* respondents who strongly agreed (= 4) with the statement in 2016.
local y_FLFP         work7
local s_FLFP         ""
local y_No_WWOH_reli No_WWOH_reli
local s_No_WWOH_reli "if nowwoh416 == 1"
local y_Hus          Huscareer_imp_wife
local s_Hus          "if hus4 == 1"
local y_risk         risk_std
local s_risk         ""
local y_fem_dm       fem_dm_ave
local s_fem_dm       ""


* --- 7.1 Individual and year FE both absorbed ---------------------------------
reghdfe work7 c.DV_rate_16_c##i.female##i.post_year `bl_ctrl' `bl_ctrl_m', absorb(idpp year) vce(cluster oblast)
* FLFP with urban x post control
reghdfe work7 c.DV_rate_16_c##i.female##i.post_year `bl_ctrl' `bl_ctrl_m' `bl_ctrl_city', absorb(idpp year) vce(cluster oblast)
eststo FLFP_2fe
estadd scalar clusters = e(N_clust)

foreach o in No_WWOH_reli Hus risk fem_dm {
    reghdfe `y_`o'' c.DV_rate_16_c##i.female##i.post_year `bl_ctrl' `bl_ctrl_m' `s_`o'', absorb(idpp year) vce(cluster oblast)
    eststo `o'_2fe
    estadd scalar clusters = e(N_clust)
}


* --- 7.2 Main results: individual FE absorbed, year FE as regressors ----------
* Models with baseline controls are stored as <outcome>, models without
* controls as <outcome>_nc. Wild bootstrap p-values are attached to each model.
foreach o in FLFP No_WWOH_reli Hus risk fem_dm {
    reghdfe `y_`o'' `ddd' `ctrl_terms' `s_`o'', absorb(idpp) vce(cluster oblast)
    ddd_wild `main_terms' `ctrl_terms'
    eststo `o'

    reghdfe `y_`o'' `ddd' `s_`o'', absorb(idpp) vce(cluster oblast)
    ddd_wild `main_terms'
    eststo `o'_nc
}

* Conventional cluster-robust p-values
esttab No_WWOH_reli Hus risk FLFP fem_dm, keep(`main_terms') scalars(clusters) cells(b(fmt(3) star) p(fmt(3) par)) starlevels(* 0.10 ** 0.05 *** 0.01) addnotes("p-values in parentheses. Stars based on p-values. Individual FE absorbed; SEs clustered at oblast.") varwidth(30)
esttab No_WWOH_reli_nc Hus_nc FLFP_nc risk_nc fem_dm_nc, keep(`main_terms') scalars(clusters) cells(b(fmt(3) star) p(fmt(3) par)) starlevels(* 0.10 ** 0.05 *** 0.01) addnotes("p-values in parentheses. Stars based on p-values. Individual FE absorbed; SEs clustered at oblast.") varwidth(30)


* --- 7.3 Paper Tables 3-5 (wild bootstrap p-values) ----------------------------
local labels 1.post_year "Post (2019 = 1)" 1.post_year#c.DV_rate_16_c "Post $\times$ DV rate" 1.female#1.post_year "Post $\times$ Female" 1.female#1.post_year#c.DV_rate_16_c "Post $\times$ DV rate $\times$ Female (DDD)" pre_num_child_16b "Num children (baseline) $\times$ Pre" pre_age_16b "Age (baseline) $\times$ Pre" pre_age2_16b "Age$^2$ (baseline) $\times$ Pre" pre_log_cons_food_16b "Log food cons. (baseline) $\times$ Pre" pre_log_cons_nonfood_16b "Log non-food cons. (baseline) $\times$ Pre" pre_married2016b "Married (baseline) $\times$ Pre"

local tabopts keep(`main_terms' `ctrl_terms') order(`main_terms' `ctrl_terms') cells(b(fmt(3) star pvalue(wildp)) wildp(fmt(3) par)) starlevels(* 0.10 ** 0.05 *** 0.01) coeflabels(`labels') stats(N clusters reps, labels("Observations" "Clusters" "Replications") fmt(0 0 0)) booktabs collabels(none) nonotes replace

esttab No_WWOH_reli_nc No_WWOH_reli Hus_nc Hus using "$fig/table3_gender_attitudes.tex", `tabopts' mtitles("No controls" "Controls" "No controls" "Controls")
esttab risk_nc risk fem_dm_nc fem_dm using "$fig/table4_risk_decision_making.tex", `tabopts' mtitles("No controls" "Controls" "No controls" "Controls")
esttab FLFP_nc FLFP using "$fig/table5_work.tex", `tabopts' mtitles("No controls" "Controls")

* Same tables in the log
esttab No_WWOH_reli_nc No_WWOH_reli Hus_nc Hus risk_nc risk fem_dm_nc fem_dm FLFP_nc FLFP, keep(`main_terms' `ctrl_terms') order(`main_terms' `ctrl_terms') cells(b(fmt(3) star pvalue(wildp)) wildp(fmt(3) par)) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N clusters reps) varwidth(40)


* --- 7.4 Gender-specific marginal effects (Appendix table) ---------------------
* The DDD coefficient is the difference between women and men. To test the
* effect for each gender, the same model is reparametrized with separate Post
* and Post x DV slopes for men and women:
*   Post x DV (women) = Post x DV + Post x DV x Female in the DDD model
*   Post x DV (men)   = Post x DV
* With individual FE this is identical to the DDD model above, and the
* difference postdv_w - postdv_m equals the DDD coefficient.
gen post_m   = post_year * (1 - female)
gen post_w   = post_year * female
gen postdv_m = post_year * DV_rate_16_c * (1 - female)
gen postdv_w = post_year * DV_rate_16_c * female
label var post_m   "Post (men)"
label var post_w   "Post (women)"
label var postdv_m "Post $\times$ DV rate (men)"
label var postdv_w "Post $\times$ DV rate (women)"

local me_terms postdv_m postdv_w post_m post_w
local me_list
foreach o in No_WWOH_reli Hus risk fem_dm FLFP {
    foreach c in nc c {
        local X ""
        if "`c'" == "c" local X `ctrl_terms'
        reghdfe `y_`o'' `me_terms' `X' `s_`o'', absorb(idpp) vce(cluster oblast)
        ddd_wild `me_terms'
        * DDD = women - men, with its wild bootstrap p-value
        quietly boottest {postdv_w = postdv_m}, cluster(oblast) reps(9999) seed(12345) weight(webb) nograph noci
        estadd scalar ddd_b = _b[postdv_w] - _b[postdv_m]
        estadd scalar ddd_p = r(p)
        eststo me_`o'_`c'
        local me_list `me_list' me_`o'_`c'
    }
}

esttab `me_list' using "$fig/tableA_gender_marginal_effects.tex", keep(`me_terms') order(`me_terms') cells(b(fmt(3) star pvalue(wildp)) wildp(fmt(3) par)) starlevels(* 0.10 ** 0.05 *** 0.01) label stats(ddd_b ddd_p N clusters reps, labels("DDD (women $-$ men)" "\quad wild bootstrap p-value" "Observations" "Clusters" "Replications") fmt(3 3 0 0 0)) mtitles("No WWOH" "No WWOH" "Husband career" "Husband career" "Risk" "Risk" "Female DM" "Female DM" "Work" "Work") booktabs collabels(none) nonotes replace
esttab `me_list', keep(`me_terms') order(`me_terms') cells(b(fmt(3) star pvalue(wildp)) wildp(fmt(3) par)) starlevels(* 0.10 ** 0.05 *** 0.01) stats(ddd_b ddd_p N clusters reps) varwidth(30)


* --- 7.5 Gender attitudes in the full sample (Appendix robustness table) -------
* Same models as Table 3, without restricting the sample to respondents who
* strongly agreed with the statement in 2016.
local fs_list
foreach o in No_WWOH_reli Hus {
    reghdfe `y_`o'' `ddd', absorb(idpp) vce(cluster oblast)
    ddd_wild `main_terms'
    eststo `o'_full_nc
    reghdfe `y_`o'' `ddd' `ctrl_terms', absorb(idpp) vce(cluster oblast)
    ddd_wild `main_terms' `ctrl_terms'
    eststo `o'_full
    local fs_list `fs_list' `o'_full_nc `o'_full
}

esttab `fs_list' using "$fig/tableA_attitudes_full_sample.tex", `tabopts' mtitles("No controls" "Controls" "No controls" "Controls")
esttab `fs_list', keep(`main_terms' `ctrl_terms') order(`main_terms' `ctrl_terms') cells(b(fmt(3) star pvalue(wildp)) wildp(fmt(3) par)) starlevels(* 0.10 ** 0.05 *** 0.01) stats(N clusters reps) varwidth(40)


*******************************************************************************
* 8. Urban vs. rural subsamples (wild bootstrap via boottest)
*******************************************************************************

* --- 8.1 FLFP: urban (c) and rural (v), without and with controls -------------
local r_c 1
local r_v 0
foreach a in c v {
    preserve
    keep if residence16 == `r_`a''

    reghdfe work7 c.DV_rate_16_c##i.female##i.post_year i.year, absorb(idpp) vce(cluster oblast)
    boot_main
    eststo FLFP_`a'
    estadd scalar clusters = e(N_clust)

    reghdfe work7 c.DV_rate_16_c##i.female##i.post_year `bl_ctrl' `bl_ctrl_m' i.year, absorb(idpp) vce(cluster oblast)
    boot_main
    boot_ctrl
    eststo FLFP_`a'c
    estadd scalar clusters = e(N_clust)

    restore
}

esttab FLFP_c FLFP_cc FLFP_v FLFP_vc, keep(`main_terms') scalars(clusters) cells(b(fmt(3) star) p(fmt(3) par)) starlevels(* 0.10 ** 0.05 *** 0.01) addnotes("p-values in parentheses. Stars based on p-values. Individual FE absorbed; SEs clustered at oblast.") varwidth(30)

* --- 8.2 Urban subsample: other outcomes ---------------------------------------
preserve
keep if residence16 == 1

reghdfe No_WWOH_reli c.DV_rate_16_c##i.female##i.post_year i.year, absorb(idpp) vce(cluster oblast)
boot_main
eststo No_WWOH_reli_c
estadd scalar clusters = e(N_clust)

foreach o in Hus risk fem_dm {
    reghdfe `y_`o'' c.DV_rate_16_c##i.female##i.post_year `bl_ctrl' `bl_ctrl_m' i.year `s_`o'', absorb(idpp) vce(cluster oblast)
    eststo `o'_c
    estadd scalar clusters = e(N_clust)
}
boot_main
boot_ctrl

restore


*******************************************************************************
* 9. Wild cluster bootstrap with the wildboot package (rseed 1234)
*******************************************************************************

* --- 9.1 DDD without controls: m1-m5 ------------------------------------------
local m1 No_WWOH_reli i.post_year##c.DV_rate_16_c##i.female i.year if nowwoh416==1
local m2 Huscareer_imp_wife i.post_year##c.DV_rate_16_c##i.female i.year if hus416==1
local m3 risk_std i.post_year##c.DV_rate_16_c##i.female i.year
local m4 fem_dm_ave post_year i.post_year##c.DV_rate_16_c##i.female i.year
local m5 work7 i.post_year##c.DV_rate_16_c##i.female i.year

forvalues k = 1/5 {
    eststo m`k': wildboot xtreg `m`k'', fe cluster(oblast) reps(9999) rseed(1234)
    wb_bootp m`k'
}

esttab m1 m2 m3 m4 m5, keep(1.post_year 1.post_year#c.DV_rate_16_c 1.post_year#1.female 1.post_year#1.female#c.DV_rate_16_c) scalars(clusters reps) cells(b(fmt(3) star pvalue(bootp)) bootp(par)) starlevels(* 0.10 ** 0.05 *** 0.01) addnotes("p-values in parentheses. Stars based on p-values." "Individual FE absorbed (idpp, year); SEs clustered at oblast.") varwidth(30)

* --- 9.2 Robustness: quadruple interaction with urban residence, rm1-rm5 -------
local rm1 No_WWOH_reli i.post_year##c.DV_rate_16_c##i.female##i.residence16 i.year if nowwoh416==1
local rm2 Huscareer_imp_wife i.post_year##c.DV_rate_16_c##i.female##i.residence16 if hus416==1
local rm3 risk_std i.post_year##c.DV_rate_16_c##i.female##i.residence16
local rm4 fem_dm_ave post_year i.post_year##c.DV_rate_16_c##i.female##i.residence16 i.year
local rm5 work7 i.post_year##c.DV_rate_16_c##i.female##i.residence16 i.year

forvalues k = 1/5 {
    eststo rm`k': wildboot xtreg `rm`k'', fe cluster(oblast) reps(9999) rseed(1234)
    wb_bootp rm`k'
}

esttab rm1 rm2 rm3 rm4 rm5, keep(1.post_year 1.post_year#c.DV_rate_16_c 1.post_year#1.female 1.post_year#1.female#c.DV_rate_16_c 1.post_year#1.residence16 1.post_year#1.residence16#c.DV_rate_16_c 1.post_year#1.female#1.residence16 1.post_year#1.female#1.residence16#c.DV_rate_16_c) scalars(clusters reps) cells(b(fmt(3) star pvalue(bootp)) bootp(par)) starlevels(* 0.10 ** 0.05 *** 0.01) addnotes("p-values in parentheses. Stars based on p-values." "Individual FE absorbed (idpp, year); SEs clustered at oblast.") varwidth(30)
