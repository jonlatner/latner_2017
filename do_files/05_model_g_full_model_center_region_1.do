/***************
Preliminaries
***************/
clear all
capture log close
set more off

* Enter the location
global location = "/Users/jonathanlatner/GitHub/latner_2017"

* Enter the location of the do files
global do_files = `"$location/do_files"'

* Enter the location of the data files
global data_files = `"$location/data_files"'

* Enter the location of the results files
global results = `"$location/results"'

* Enter the location of the CTS data files
global support_files = `"$location/support_files"'

* Change directory
cd "$location"

/*************
Load data

The paper creates/uses a 50% sample:
do "$do_files/02_clean_f_region_1.do"
use "$data_files/cts_hmda_data_region_1.dta", clear

Alternatively, simply use the 20% sample for each region
*************/

use "$data_files/cts_hmda_data_sample_20.dta", clear
rename cbsa metroid
drop if date>647 /*keep if year<=2013*/

keep if region == 1

merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta", keepusing(m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region)
keep if _m == 3
drop _m

merge m:1 metroid using "$support_files/acs_isolation_09.dta", keepusing(m_xbb_a_09 m_xhh_a_09 m_xaa_a_09)
keep if _m == 3
drop _m

replace income = income/10000

tab count
sum income, d
drop if income<r(p1) | income>r(p99)
sum income, d
tab count

keep if region == 1

foreach var of varlist income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv putoption calloption {
sum `var'
replace `var' = `var' - r(mean)
sum `var'
}

/*************
Identify short sale and declare as foreclosure
*************/

sort id date
gen short = 1 if loss>0 & delinqhis2[_n-1]==3 & delinquent == 60
by id: replace short = 1 if short[_n-1] == 1

*Drop all cases after short sale
gen test = 1 if short == 1
by id: replace test = 0 if test[_n-1]==1
by id: replace test = 0 if test[_n-1]==0
drop if test == 0
drop test

replace outcome = 2 if short == 1

/*************
Default hazard model, controlling for probability of prepayment
*************/
*set up the model

sort id date

by id: gen end = date[_N]
by id: gen start = date[1]
gen dur = date - start

stset dur, id(id) fail(outcome == 2)

stcrreg  i.race##c.income i.fico_ i.race##c.m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 i.highcost ltv i.purpose i.arm i.mod i.pti_dummy c.putoption##c.putoption c.calloption##c.calloption i.year, compete(outcome == 1) vce(cluster id)
est sto dissimilarity
est save "$results/main_model_center_region_1", replace

predict basecif, basecsh
sum basecif, d
