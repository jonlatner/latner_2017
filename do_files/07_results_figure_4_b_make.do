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
foreach i of numlist 1 2 3 4 {
preserve

	keep if region == `i'

	estimates use "$results/main_model_center_region_`i'.ster"
	estimates esample:
	estimates replay, nohr

	predict basecif, basecsh

	*White
	gen reo_race_1_m_2_sd = 1 - (1 - basecif)^exp(_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')')
	gen reo_race_1_m_1_sd = 1 - (1 - basecif)^exp(_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')')
	gen reo_race_1_m_0_sd = 1 - (1 - basecif)^exp(_b[m_dwb_a_09]*`m_dwb_a_09_mean')
	gen reo_race_1_p_1_sd = 1 - (1 - basecif)^exp(_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')')
	gen reo_race_1_p_2_sd = 1 - (1 - basecif)^exp(_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')')

	*Black
	gen reo_race_2_m_2_sd = 1 - (1 - basecif)^exp(_b[2.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[2.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[2.race#c.income]*`income_mean')
	gen reo_race_2_m_1_sd = 1 - (1 - basecif)^exp(_b[2.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[2.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[2.race#c.income]*`income_mean')
	gen reo_race_2_m_0_sd = 1 - (1 - basecif)^exp(_b[2.race#c.m_dwb_a_09]*`m_dwb_a_09_mean'+_b[2.race]+_b[m_dwb_a_09]*`m_dwb_a_09_mean'+_b[2.race#c.income]*`income_mean')
	gen reo_race_2_p_1_sd = 1 - (1 - basecif)^exp(_b[2.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[2.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[2.race#c.income]*`income_mean')
	gen reo_race_2_p_2_sd = 1 - (1 - basecif)^exp(_b[2.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[2.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[2.race#c.income]*`income_mean')

	*Hispanic
	gen reo_race_3_m_2_sd = 1 - (1 - basecif)^exp(_b[3.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[3.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(2*`m_dwb_a_09_sd')'+_b[3.race#c.income]*`income_mean')
	gen reo_race_3_m_1_sd = 1 - (1 - basecif)^exp(_b[3.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[3.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'-(`m_dwb_a_09_sd')'+_b[3.race#c.income]*`income_mean')
	gen reo_race_3_m_0_sd = 1 - (1 - basecif)^exp(_b[3.race#c.m_dwb_a_09]*`m_dwb_a_09_mean'+_b[3.race]+_b[m_dwb_a_09]*`m_dwb_a_09_mean'+_b[3.race#c.income]*`income_mean')
	gen reo_race_3_p_1_sd = 1 - (1 - basecif)^exp(_b[3.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[3.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(`m_dwb_a_09_sd')'+_b[3.race#c.income]*`income_mean')
	gen reo_race_3_p_2_sd = 1 - (1 - basecif)^exp(_b[3.race#c.m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[3.race]+_b[m_dwb_a_09]*`=`m_dwb_a_09_mean'+(2*`m_dwb_a_09_sd')'+_b[3.race#c.income]*`income_mean')

	sum reo_*

	collapse segregation=m_dwb_a_09 (sd) segregation_sd=m_dwb_a_09 (max) reo_*
	gen region = `i'

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

	save "$results/predict_basecif_segregation_center_region_`i'.dta", replace
restore
}

use "$results/predict_basecif_segregation_center_region_1.dta", clear
append using "$results/predict_basecif_segregation_center_region_2.dta"
append using "$results/predict_basecif_segregation_center_region_3.dta"
append using "$results/predict_basecif_segregation_center_region_4.dta"
append using "$results/predict_basecif_segregation_graph.dta"
replace region = 0 if region == .
sort region sd

save "$results/predict_basecif_segregation_center_region.dta", replace

use "$results/predict_basecif_segregation_center_region.dta", clear

#delimit;
graph twoway 
scatter white sd if region == 0, connect(l) lcolor(gs12) mcolor(gs12) lwidth(medium) msymbol(S) msize(medium) || 
scatter black sd if region == 0, connect(l) lcolor(gs6) mcolor(gs6) lwidth(medium) msymbol(T) msize(medium)  || 
scatter hispanic sd if region == 0, connect(l) lcolor(gs0) mcolor(gs0) lwidth(medium) msymbol(O) msize(medium)   
xtitle(" " "Black/white dissimilarity index of segregation") ytitle("Model adjusted cumulative incidence" "of foreclosure x 100")  
xlabel(1 `""-2 sd" "(38)" "Las Vegas, NV""' 2 `""-1 sd" "(49)" " " "Phoenix, AZ""' 3 `""mean" "(60)" "Atlanta, GA""' 4 `""+1 sd" "(71)" " " "Philadelphia, PA""' 5 `""+2 sd" "(82)" "Milwaukee, WI""')
ytitle("Predicted cumulative incidence" "of foreclosure x 100")
xscale(range(0.5 5.5)) yscale(range(0(10)30)) ylabel(0(10)30)
title("All regions", size(medium)) 
legend(order(1 "White" 2 "Black" 3 "Hispanic") row(1)) 
saving("$graphs/test_0", replace)
;
#delimit cr

#delimit;
graph twoway 
scatter white sd if region == 1, connect(l) lcolor(gs12) mcolor(gs12) lwidth(medium) msymbol(S) msize(medium) || 
scatter black sd if region == 1, connect(l) lcolor(gs6) mcolor(gs6) lwidth(medium) msymbol(T) msize(medium)  || 
scatter hispanic sd if region == 1, connect(l) lcolor(gs0) mcolor(gs0) lwidth(medium) msymbol(O) msize(medium)   
xscale(range(0.5 5.5)) yscale(range(0(5)30))
title("Northeast", size(medium)) 
legend(order(1 "White" 2 "Black" 3 "Hispanic") row(1)) 
xtitle("") xlabel(none) xtick(1(1)5)
saving("$graphs/test_1", replace)
;
#delimit cr

#delimit;
graph twoway 
scatter white sd if region == 2, connect(l) lcolor(gs12) mcolor(gs12) lwidth(medium) msymbol(S) msize(medium) || 
scatter black sd if region == 2, connect(l) lcolor(gs6) mcolor(gs6) lwidth(medium) msymbol(T) msize(medium)  || 
scatter hispanic sd if region == 2, connect(l) lcolor(gs0) mcolor(gs0) lwidth(medium) msymbol(O) msize(medium)   
xscale(range(0.5 5.5)) yscale(range(0(5)30))
title("Midwest", size(medium)) 
legend(order(1 "White" 2 "Black" 3 "Hispanic") row(1)) 
xtitle("") xlabel(none) xtick(1(1)5)
saving("$graphs/test_2", replace)
;
#delimit cr

#delimit;
graph twoway 
scatter white sd if region == 3, connect(l) lcolor(gs12) mcolor(gs12) lwidth(medium) msymbol(S) msize(medium) || 
scatter black sd if region == 3, connect(l) lcolor(gs6) mcolor(gs6) lwidth(medium) msymbol(T) msize(medium)  || 
scatter hispanic sd if region == 3, connect(l) lcolor(gs0) mcolor(gs0) lwidth(medium) msymbol(O) msize(medium)   
xscale(range(0.5 5.5)) yscale(range(0(5)30))
xlabel(1 "-2 sd" 2 `"" " "-1 sd""' 3 "mean" 4 `"" " "+1 sd""' 5 "+2 sd") 
legend(order(1 "White" 2 "Black" 3 "Hispanic") row(1)) 
title("South", size(medium)) xtitle("") xtick(1(1)5)
saving("$graphs/test_3", replace)
;
#delimit cr

#delimit;
graph twoway 
scatter white sd if region == 4, connect(l) lcolor(gs12) mcolor(gs12) lwidth(medium) msymbol(S) msize(medium) || 
scatter black sd if region == 4, connect(l) lcolor(gs6) mcolor(gs6) lwidth(medium) msymbol(T) msize(medium)  || 
scatter hispanic sd if region == 4, connect(l) lcolor(gs0) mcolor(gs0) lwidth(medium) msymbol(O) msize(medium)   
xscale(range(0.5 5.5)) yscale(range(0(5)30))
xlabel(1 "-2 sd" 2 `"" " "-1 sd""' 3 "mean" 4 `"" " "+1 sd""' 5 "+2 sd") 
title("West", size(medium)) xtitle("") xtick(1(1)5)
legend(order(1 "White" 2 "Black" 3 "Hispanic") row(1)) 
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
note("Note: Representative MSA's with a similar index of dissimilarity are listed below the" "appropriate tick mark.")
;
#delimit cr
graph export "$graphs/predict_basecif_segregation_center_race_region.png", replace

rm "$graphs/test_0.gph"
rm "$graphs/test_1.gph"
rm "$graphs/test_2.gph"
rm "$graphs/test_3.gph"
rm "$graphs/test_4.gph"
rm "$graphs/region.gph"
