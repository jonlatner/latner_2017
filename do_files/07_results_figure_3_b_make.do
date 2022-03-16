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

/*************
Income
*************/

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

merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta",  keepusing(region m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region)
keep if _m == 3
drop _m

merge m:1 metroid using "$support_files/acs_isolation_09.dta",  keepusing(metroname m_xbb_a_09 m_xhh_a_09 m_xaa_a_09)
keep if _m == 3
drop _m

/*************	
Centering
*************/

foreach var of varlist income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv putoption calloption {
sum `var'
replace `var' = `var' - r(mean)
sum `var'
}

foreach var of varlist income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 ltv putoption calloption {
sum `var'
local `var'_mean = r(mean)
local `var'_sd = r(sd)
}

/*************	
Competing risks hazard model
*************/

sort id date

by id: gen end = date[_N]
by id: gen start = date[1]
gen dur = date - start

stset dur, id(id) fail(reo == 1)

set more off
foreach i of numlist 1/4 {
preserve
	keep if region == `i'

	estimates use "$results/main_model_center_region_`i'.ster"
	estimates esample:
	estimates replay, nohr

	predict basecif, basecsh
	sum basecif, d
	gen reo_race_1_adj = 1 - (1 - basecif)^exp(0)
	gen reo_race_2_adj = 1 - (1 - basecif)^exp(_b[2.race#c.m_dwb_a_09]*`m_dwb_a_09_mean'+_b[2.race]+_b[income]*`income_mean'+_b[2.race#c.income]*`income_mean')
	gen reo_race_3_adj = 1 - (1 - basecif)^exp(_b[3.race#c.m_dwb_a_09]*`m_dwb_a_09_mean'+_b[3.race]+_b[income]*`income_mean'+_b[3.race#c.income]*`income_mean')

	by id: keep if _n==_N

	foreach x of numlist 1/3 {
	egen reo_race_`x'_unadj = mean(reo) if race == `x'
	}

	collapse reo_*
	gen region = `i'

	expand 2
	gen model = _n
	gen race = 1
	order model race

	expand 3
	sort model race
	by model: replace race = _n 
	gen predict = .
	order model race predict

	foreach j of numlist 1/3 {
	replace predict = reo_race_`j'_adj if model == 2 & race == `j'
	}

	foreach j of numlist 1/3 {
	replace predict = reo_race_`j'_unadj if model == 1 & race == `j'
	}

	drop reo_*
	replace predict = predict*100
	reshape wide predict, i(model) j(race)

	rename predict1 white
	rename predict2 black
	rename predict3 hispanic

	save "$results/predict_basecif_center_race_region_`i'.dta", replace

restore
}

use "$results/predict_basecif_center_race_region_1.dta", clear
append using "$results/predict_basecif_center_race_region_2.dta"
append using "$results/predict_basecif_center_race_region_3.dta"
append using "$results/predict_basecif_center_race_region_4.dta"

append using "$results/predict_basecif_race_graph.dta"
replace region = 0 if region == .
sort region model

save "$results/predict_basecif_center_race_region.dta", replace


*****************************************
*****************************************
*****************************************

capture log close
est clear
clear

use "$results/predict_basecif_center_race_region.dta", clear

#delimit;
graph bar white black hispanic if (model==1 | model == 2) & region == 0, 
over(model, relabel(1 "unadjusted" 2 `""model" "adjusted""') label(labsize(medium)))
blabel(bar, position(outside) format(%9.1f) color(black) size(small)) bar(1,bcolor(gs12)) bar(2,bcolor(gs6)) bar(3,bcolor(gs0)) 
legend( label(1 "White") label(2 "Black") label(3 "Hispanic") size(medium) rows(1)) 
ytitle("Predicted cumulative incidence" "of foreclosure x 100" " ", size(medium)) 
ylabel(0(10)30)
saving("$graphs/test_0", replace)
;
#delimit cr

#delimit;
graph bar white black hispanic if (model==1 | model == 2) & region == 1, 
over(model , relabel(1 " " 2 " ") label(labsize(medium)))
legend(off)
blabel(bar, position(outside) format(%9.1f) color(black) size(small)) bar(1,bcolor(gs12)) bar(2,bcolor(gs6)) bar(3,bcolor(gs0)) 
title("Northeast", size(medium)) 
ylabel(0(10)30)
saving("$graphs/test_1", replace)
;
#delimit cr

#delimit;
graph bar white black hispanic if (model==1 | model == 2) & region == 2, 
over(model , relabel(1 " " 2 " ") label(labsize(medium)))
legend(off)
blabel(bar, position(outside) format(%9.1f) color(black) size(small)) bar(1,bcolor(gs12)) bar(2,bcolor(gs6)) bar(3,bcolor(gs0)) 
title("Midwest", size(medium)) 
ylabel(0(10)30)
saving("$graphs/test_2", replace)
;
#delimit cr

#delimit;
graph bar white black hispanic if (model==1 | model == 2) & region == 3, 
over(model, relabel(1 "unadjusted" 2 `""model" "adjusted""') label(labsize(medium)))
blabel(bar, position(outside) format(%9.1f) color(black) size(small)) bar(1,bcolor(gs12)) bar(2,bcolor(gs6)) bar(3,bcolor(gs0)) 
legend( label(1 "White") label(2 "Black") label(3 "Hispanic") size(medium) rows(1)) 
title("South", size(medium)) 
ylabel(0(10)30)
saving("$graphs/test_3", replace)
;
#delimit cr

#delimit;
graph bar white black hispanic if (model==1 | model == 2) & region == 4, 
over(model, relabel(1 "unadjusted" 2 `""model" "adjusted""') label(labsize(medium)))
blabel(bar, position(outside) format(%9.1f) color(black) size(small)) bar(1,bcolor(gs12)) bar(2,bcolor(gs6)) bar(3,bcolor(gs0)) 
legend( label(1 "White") label(2 "Black") label(3 "Hispanic") size(medium) rows(1)) 
title("West", size(medium)) 
ylabel(0(10)30)
saving("$graphs/test_4", replace)
;
#delimit cr


#delimit ;
grc1leg 
"$graphs/test_1.gph" 
"$graphs/test_2.gph"
"$graphs/test_3.gph"
"$graphs/test_4.gph"
, ycommon 
saving("$graphs/region", replace)
;
#delimit cr

#delimit ;
grc1leg 
"$graphs/test_0.gph" 
"$graphs/region.gph"
, ycommon col(2)
note("Note: model controls for borrower race, income, credit, loan, and geographic characteristics")
;
#delimit cr
graph export "$graphs/predict_basecif_center_race_region.png", replace

rm "$graphs/test_0.gph"
rm "$graphs/test_1.gph"
rm "$graphs/test_2.gph"
rm "$graphs/test_3.gph"
rm "$graphs/test_4.gph"
rm "$graphs/region.gph"
