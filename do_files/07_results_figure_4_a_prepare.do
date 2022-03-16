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

use "$data_files/cts_hmda_data_sample_20.dta", clear
rename cbsa metroid

replace income = income/10000

tab count
sum income, d
drop if income<r(p1) | income>r(p99)
sum income, d
tab count

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

merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta", keepusing(m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region)
keep if _m == 3
drop _m

merge m:1 metroid using "$support_files/acs_isolation_09.dta", keepusing(metroname m_xbb_a_09 m_xhh_a_09 m_xaa_a_09)
keep if _m == 3
drop _m

/*************	
Competing risks hazard model
*************/

sort id date

by id: gen end = date[_N]
by id: gen start = date[1]
gen dur = date - start

stset dur, id(id) fail(reo == 1)

set more off
estimates use "$results/borrower_geo_loan_seg_int_center.ster"
estimates esample:
estimates replay, nohr

sum m_dwb_a_09
local mean = r(mean)
local sd = r(sd)
di `mean'
di `sd'

margins race, at(m_dwb_a_09=(`=`mean'-(2*`sd')' `=`mean'-(`sd')' `mean' `=`mean'+(`sd')' `=`mean'+(2*`sd')+`sd'')) predict(xb) 

matrix at = r(at)
matrix list at
foreach x of numlist 1/5 {
local at_`x' = at[`x',10]
}

marginsplot, title("") ytitle(Pr(hazard)) xtitle("Income ($1,000s)") ///
legend(order(1 "White" 2 "Black" 3 "Hispanic" 4 "Other") row(1)) ///
plot1opts(msymbol(D)) plot2opts(msymbol(X)) plot3opts(msymbol(Sh)) plot4opts(msymbol(O)) ///
xlabel(`at_1' "-2 sd" `at_2' "-1 sd" `at_3' "mean" `at_4' "+1 sd" `at_5' "+2 sd")

predict basecif, basecsh
foreach var of varlist income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv putoption calloption {
sum `var'
local `var'_mean = r(mean)
local `var'_sd = r(sd)
}


*White
gen reo_race_1_m_2_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[income]*`income_mean')
gen reo_race_1_m_1_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[income]*`income_mean')
gen reo_race_1_m_0_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[m_dwb_a_09]*`m_dwb_a_09_mean'+_b[income]*`income_mean')
gen reo_race_1_p_1_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[income]*`income_mean')
gen reo_race_1_p_2_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[income]*`income_mean')

*Black
gen reo_race_2_m_2_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[2.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[2.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[income]*`income_mean'+_b[2.race#c.income]*`income_mean')
gen reo_race_2_m_1_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[2.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[2.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[income]*`income_mean'+_b[2.race#c.income]*`income_mean')
gen reo_race_2_m_0_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[2.race#c.m_dwb_a_09]*`m_dwb_a_09_mean'+_b[2.race]+_b[m_dwb_a_09]*`m_dwb_a_09_mean'+_b[income]*`income_mean'+_b[2.race#c.income]*`income_mean')
gen reo_race_2_p_1_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[2.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[2.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[income]*`income_mean'+_b[2.race#c.income]*`income_mean')
gen reo_race_2_p_2_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[2.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[2.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[income]*`income_mean'+_b[2.race#c.income]*`income_mean')

*Hispanic
gen reo_race_3_m_2_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[3.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[3.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[income]*`income_mean'+_b[3.race#c.income]*`income_mean')
gen reo_race_3_m_1_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[3.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[3.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[income]*`income_mean'+_b[3.race#c.income]*`income_mean')
gen reo_race_3_m_0_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[3.race#c.m_dwb_a_09]*`m_dwb_a_09_mean'+_b[3.race]+_b[m_dwb_a_09]*`m_dwb_a_09_mean'+_b[income]*`income_mean'+_b[3.race#c.income]*`income_mean')
gen reo_race_3_p_1_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[3.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[3.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[income]*`income_mean'+_b[3.race#c.income]*`income_mean')
gen reo_race_3_p_2_sd = 1 - (1 - basecif)^exp(_b[calloption]*`calloption_mean'+_b[c.calloption#c.calloption]*`calloption_mean'+_b[putoption]*`putoption_mean'+_b[c.putoption#c.putoption]*`putoption_mean'+_b[ltv]*`ltv_mean'+_b[m_dwa_a_09]*`m_dwa_a_09_mean'+_b[m_dwh_a_09]*`m_dwh_a_09_mean'+_b[3.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[3.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[income]*`income_mean'+_b[3.race#c.income]*`income_mean')

sum reo_*

collapse segregation=m_dwb_a_09 (sd) segregation_sd=m_dwb_a_09 (max) reo_*

save "$results/predict_basecif_segregation.dta", replace

*****************************************
*****************************************
*****************************************

*use "$results/predict_basecif_segregation.dta", clear

expand 5
gen sd = _n
order sd

label define sd 1 "-2sd"
label define sd 2 "-1sd", add
label define sd 3 "mean", add
label define sd 4 "+1sd", add
label define sd 5 "+2sd", add
label values sd sd 

replace segregation = segregation - 2*segregation_sd if sd == 1
replace segregation = segregation - segregation_sd if sd == 2
replace segregation = segregation + segregation_sd if sd == 4
replace segregation = segregation + 2*segregation_sd if sd == 5

gen black = .
gen white = .
gen hispanic = .

replace white = reo_race_1_m_2_sd if sd == 1
replace white = reo_race_1_m_1_sd if sd == 2
replace white = reo_race_1_m_0_sd if sd == 3
replace white = reo_race_1_p_1_sd if sd == 4
replace white = reo_race_1_p_2_sd if sd == 5

replace black = reo_race_2_m_2_sd if sd == 1
replace black = reo_race_2_m_1_sd if sd == 2
replace black = reo_race_2_m_0_sd if sd == 3
replace black = reo_race_2_p_1_sd if sd == 4
replace black = reo_race_2_p_2_sd if sd == 5

replace hispanic = reo_race_3_m_2_sd if sd == 1
replace hispanic = reo_race_3_m_1_sd if sd == 2
replace hispanic = reo_race_3_m_0_sd if sd == 3
replace hispanic = reo_race_3_p_1_sd if sd == 4
replace hispanic = reo_race_3_p_2_sd if sd == 5

order sd segregation white black hispanic

drop reo_*

replace white = white * 100
replace black = black * 100
replace hispanic = hispanic * 100

graph twoway scatter white sd, connect(l) lcolor(gs12) mcolor(gs12) lwidth(thick) msymbol(S) msize(large) || ///
scatter black sd, connect(l) lcolor(gs6) mcolor(gs6) lwidth(thick) msymbol(T) msize(large)  || ///
scatter hispanic sd, connect(l) lcolor(gs0) mcolor(gs0) lwidth(thick) msymbol(O) msize(large) ///  
legend(order(1 "White" 2 "Black" 3 "Hispanic") row(1)) ///
xlabel(1 `""-2 sd (38)" "Las Vegas, NV""' 2 `""-1 sd (49)" "Phoenix, AZ""' 3 `""mean (60)" "Atlanta, GA""' 4 `""+1 sd (71)" "Philadelphia, PA""' 5 `""+2 sd (82)" "Milwaukee, WI""') ///
xtitle(" " "Black/white dissimilarity index of segregation") ytitle("Model adjusted cumulative incidence" "of foreclosure x 100")  ylabel(0(5)25) xscale(range(.75 5.25)) ///
note("Note: Representative MSA's with a similar index of dissimilarity are listed below the" "appropriate tick mark.")
graph export "$graphs/predict_basecif_segregation_policy.png", replace

save "$results/predict_basecif_segregation_graph.dta", replace
