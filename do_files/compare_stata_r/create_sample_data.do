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
* Load data
*************/

use "$data_files/cts_hmda_data_sample_20.dta", clear
rename cbsa metroid
drop if date>647 /*keep if year<=2013*/
sort id date

/*************
* Create sample of 1000 unique observations
* Over sample to ensure correct distribution of outcomes
preserve
	bysort id: keep if _n == _N
	tab outcome
restore
*************/
set seed 5678

*Current
preserve
	bysort id: keep if _n == _N
	keep if outcome == 0
	sample 600, count
	keep id
	sort id
	save "$data_files/tmp0.dta", replace
restore

*REO
preserve
	bysort id: keep if _n == _N
	keep if outcome == 1
	sample 1000, count
	keep id
	sort id
	save "$data_files/tmp1.dta", replace
restore

*Payoff
preserve
	bysort id: keep if _n == _N
	keep if outcome == 2
	sample 400, count
	keep id
	sort id
	save "$data_files/tmp2.dta", replace
restore

*Append (current, reo, payoff)
preserve
	use "$data_files/tmp0.dta", clear
	append using "$data_files/tmp1.dta"
	append using "$data_files/tmp2.dta"
	sort id
	save "$data_files/tmp.dta", replace
restore

merge id using "$data_files/tmp.dta"
keep if _merge == 3
drop _merge 

/*************
* Clean data
*************/

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
Save
*************/

keep id date year state region outcome race black hispanic other ficoscore fico_ fico_1 fico_2 fico_3 fico_4 putoption calloption income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 highcost ltv purpose arm mod pti_dummy
label drop outcome

sort id date
by id: gen end = date[_N]
by id: gen start = date[1]
gen dur = date - start

save "$data_files/test_compare_stata_r.dta", replace

keep id date start end dur outcome race black hispanic other ficoscore putoption calloption

export delimited using "$data_files/test_compare_stata_r_small.csv", replace

/*************
Model
*************/

stset dur, id(id) fail(outcome == 2)

stcrreg black hispanic other putoption calloption, compete(outcome == 1)
