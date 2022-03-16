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

* Enter the location of the graph files
global graphs = `"$location/graphs"'

* Enter the location of the table files
global tables = `"$location/tables"'

* Enter the location of the CTS data files
global support_files = `"$location/support_files"'

* Change directory
cd "$location"

/*************
Load data
*************/

use "$data_files/cts_hmda_data_sample_20.dta",  clear
rename cbsa metroid

/*************
Income
*************/

replace income = income/10000

tab count
sum income,  d
drop if income<r(p1) | income>r(p99)
sum income,  d
tab count

/*************
CREATE SAMPLE
tab count
	*create sample
	sort id date
	preserve
	tempfile tmp
	bysort id: keep if _n == 1
	sample 5
	sort id
	save `tmp'
	restore
	merge id using `tmp'
	keep if _merge == 3
	drop _merge 
tab count
*************/


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
Segregation
*************/

merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta",  keepusing(region m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region)
keep if _m == 3
drop _m

merge m:1 metroid using "$support_files/acs_isolation_09.dta",  keepusing(metroname m_xbb_a_09 m_xhh_a_09 m_xaa_a_09)
keep if _m == 3
drop _m


/*************	
calculate mean and sd from full data set
*************/

foreach i of varlist income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv putoption calloption {
egen main_mn_`i' = mean(`i')
egen main_sd_`i' = sd(`i')
}


/*************
mean center
*************/

foreach var of varlist income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv putoption calloption {
sum `var'
replace `var' = `var' - r(mean)
sum `var'
}

/*************	
Competing risks hazard model
*************/

sort id date

by id: gen end = date[_N]
by id: gen start = date[1]
gen dur = date - start

stset dur,  id(id) fail(reo == 1)

/*************
NATIONAL SAMPLE EFFECT SIZE 
*************/

*CONTINUOUS VARIABLES
foreach var of varlist putoption calloption m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv income  {
set more off
estimates use "$results/borrower_geo_loan_seg_int_center.ster"
estimates esample:
sum main_mn_`var'
matrix `var'_mean = r(mean)
sum main_sd_`var'
matrix `var'_sd = `var'_mean + r(mean)
sum `var'
local mean = r(mean)
local sd = r(sd)
margins, at(`var'=(`mean' `=`mean'+`sd'')) predict(xb) post
matrix t=r(table)
matrix `var'_ln = (t[1,2]-t[1,1])
matrix `var'_exp = exp(t[1,2]-t[1,1])
test _b[1._at] = _b[2._at]
matrix `var'_pval = r(p)
}


*CATEGORICAL VARIABLES
*RACE
set more off
estimates use "$results/borrower_geo_loan_seg_int_center.ster"
estimates esample:
margins i.race, predict(xb) post
matrix t=r(table)
matrix black_ln = (t[1,2]-t[1,1])
matrix black_exp = exp(t[1,2]-t[1,1])
test _b[1.race] = _b[2.race]
matrix black_pval = r(p)
matrix hispanic_ln = (t[1,3]-t[1,1])
matrix hispanic_exp = exp(t[1,3]-t[1,1])
test _b[1.race] = _b[3.race]
matrix hispanic_pval = r(p)

*FICO
set more off
estimates use "$results/borrower_geo_loan_seg_int_center.ster"
estimates esample:
margins i.fico_, predict(xb) post
matrix t=r(table)
matrix fico_4_ln = (t[1,4]-t[1,1])
matrix fico_4_exp = exp(t[1,4]-t[1,1])
test _b[1.fico_] = _b[4.fico_]
matrix fico_4_pval = r(p)

*DUMMY VARIABLES - MISSING HIGHCOST LOAN
foreach i of varlist armind modind pti_dummy purpose highcost {
set more off
estimates use "$results/borrower_geo_loan_seg_int_center.ster"
estimates esample:
margins i.`i', predict(xb) post
matrix t=r(table)
matrix `i'_ln = (t[1,2]-t[1,1])
matrix `i'_exp = exp(t[1,2]-t[1,1])
test _b[0.`i'] = _b[1.`i']
matrix `i'_pval = r(p)
}

/*************
REGIONAL SAMPLE EFFECT SIZE 
*************/

foreach i of numlist 1/4 {
set more off
estimates use "$results/main_model_center_region_`i'.ster"
estimates esample:

*CONTINUOUS VARIABLES
foreach var of varlist putoption calloption m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv income {
set more off
estimates use "$results/main_model_center_region_`i'.ster"
estimates esample:
sum `var'
local mean = r(mean)
local sd = r(sd)
margins, at(`var'=(`mean' `=`mean'+`sd'')) predict(xb) post
matrix t=r(table)
matrix `var'_ln_region_`i' = (t[1,2]-t[1,1])
test _b[1._at] = _b[2._at]
matrix `var'_pval_region_`i' = r(p)
}

*CATEGORICAL VARIABLES
*RACE
set more off
estimates use "$results/main_model_center_region_`i'.ster"
estimates esample:
margins i.race, predict(xb) post
matrix t=r(table)
matrix black_ln_region_`i' = (t[1,2]-t[1,1])
test _b[1.race] = _b[2.race]
matrix black_pval_region_`i' = r(p)
matrix hispanic_ln_region_`i' = (t[1,3]-t[1,1])
test _b[1.race] = _b[3.race]
matrix hispanic_pval_region_`i' = r(p)

*FICO
set more off
estimates use "$results/main_model_center_region_`i'.ster"
estimates esample:
margins i.fico_, predict(xb) post
matrix t=r(table)
matrix fico_4_ln_region_`i' = (t[1,4]-t[1,1])
test _b[1.fico_] = _b[4.fico_]
matrix fico_4_pval_region_`i' = r(p)

*DUMMY VARIABLES - MISSING HIGHCOST LOAN
foreach var of varlist armind modind pti_dummy purpose highcostloan {
set more off
estimates use "$results/main_model_center_region_`i'.ster"
estimates esample:
margins i.`var', predict(xb) post
matrix t=r(table)
matrix `var'_ln_region_`i' = (t[1,2]-t[1,1])
test _b[0.`var'] = _b[1.`var']
matrix `var'_pval_region_`i' = r(p)
}
}

/*************	
Create table
*************/

matrix zero = 0


*CONTINUOUS VARIABLES
foreach var of varlist putoption calloption m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv income {
matrix a_`var' = `var'_mean,  `var'_sd,  `var'_exp,  `var'_ln, `var'_pval, `var'_ln_region_1, `var'_pval_region_1, `var'_ln_region_2, `var'_pval_region_2, `var'_ln_region_3, `var'_pval_region_3, `var'_ln_region_4, `var'_pval_region_4 
}

*CATEGORICAL VARIABLES
foreach var of varlist black hispanic fico_4 {
matrix a_`var' = zero,  zero,  `var'_exp,  `var'_ln, `var'_pval, `var'_ln_region_1, `var'_pval_region_1, `var'_ln_region_2, `var'_pval_region_2, `var'_ln_region_3, `var'_pval_region_3, `var'_ln_region_4, `var'_pval_region_4 
}

*DUMMY VARIABLES
foreach var of varlist armind modind pti_dummy purpose highcostloan {
matrix a_`var' = zero,  zero,  `var'_exp,  `var'_ln, `var'_pval, `var'_ln_region_1, `var'_pval_region_1, `var'_ln_region_2, `var'_pval_region_2, `var'_ln_region_3, `var'_pval_region_3, `var'_ln_region_4, `var'_pval_region_4 
}


#delimit ;
matrix A =
a_putoption \ 
a_calloption \ 
a_ltv \ 
a_income \ 
a_m_dwa_a_09 \ 
a_m_dwh_a_09 \ 
a_m_dwb_a_09 \ 
a_armind \ 
a_hispanic \ 
a_highcostloan \
a_purpose \ 
a_black \ 
a_pti_dummy \ 
a_modind \ 
a_fico_4
;
#delimit cr

#delimit ;
mat rownames A = 
"\indent Put option" 
"\indent Call option" 
"\indent LTV" 
"\indent Income (\$10,000s)" 
"\indent Asian segregation" 
"\indent Hispanic segregation" 
"\indent Black segregation" 
"\indent ARM indicator" 
"\indent Hispanic to white" 
"\indent High cost loan indicator" 
"\indent Purchase to refinance" 
"\indent Black to white" 
"\indent PTI $>$ 31\% indicator"
"\indent Modification indicator" 
"\indent FICO $>=$ 720 to FICO $<$ 620" 
;
#delimit cr

esttab matrix(A,  fmt(%9.3fc)) using "$tables/effect_size_data_region.tex",  replace nomtitle 

