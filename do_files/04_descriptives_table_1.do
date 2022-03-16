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

merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta", keepusing(m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region division)
keep if _m == 3
drop _m

merge m:1 metroid using "$support_files/acs_isolation_09.dta", keepusing(metroname m_xbb_a_09 m_xhh_a_09 m_xaa_a_09)
keep if _m == 3
drop _m

/*************
Labels
*************/

label var m_dwb_a_09 "\hspace{5 mm}Black (+)" 
label var m_dwh_a_09 "\hspace{5 mm}Hispanic (+)"
label var m_dwa_a_09 "\hspace{5 mm}Asian (+)"
label var m_xbb_a_09 "\hspace{10 mm}Black (+)"
label var m_xhh_a_09 "\hspace{10 mm}Hispanic (+)"
label var m_xaa_a_09 "\hspace{10 mm}Asian (+)"

gen putoption2 = putoption*putoption
gen calloption2 = calloption*calloption
label var putoption "\hspace{5 mm}*Put (default) option (+)"
label var putoption2 "\hspace{5 mm}*Put option$^2$ (+)"
label var calloption "\hspace{5 mm}*Call (prepay) option (-)"
label var calloption2 "\hspace{5 mm}*Call option$^2$ (-)"

label var fico_1 "\hspace{5 mm}$<$ 620 (Omitted)"
label var fico_2 "\hspace{5 mm}620-679 (-)"
label var fico_3 "\hspace{5 mm}680-719 (-)"
label var fico_4 "\hspace{5 mm}$>=$ 720 (-)"

gen white_inc = white*income if white == 1
gen black_inc = black*income if black == 1
gen hispanic_inc = hispanic*income if hispanic == 1
gen other_inc = other*income if other == 1

label var white_inc "\hspace{10 mm}Income \& White (Omitted)"
label var black_inc "\hspace{10 mm}Income \& Black (+)"
label var hispanic_inc "\hspace{10 mm}Income \& Hispanic (+)"
label var other_inc "\hspace{10 mm}Income \& Other (unknown)"

label var white "\hspace{5 mm}White (Omitted)"
label var black "\hspace{5 mm}Black (+)"
label var hispanic "\hspace{5 mm}Hispanic (+)"
label var other "\hspace{5 mm}Other (Unknown)"

label var income "\hspace{5 mm}Income (\\$10,000s) (-)"

label var highcostloan "\hspace{5 mm}High Cost Loan ($>=$ 300 BPS indicator) (+)"
label var ltv "\hspace{5 mm}Loan to value (LTV) (+)"
label var purpose "\hspace{5 mm}Purchase (vs. refinance) indicator (+)"
label var armind "\hspace{5 mm}*ARM (vs. FRM) indicator (+)"
label var modind "\hspace{5 mm}*Modification indicator (-)"
label var pti_dummy "\hspace{5 mm}Payment to income (PTI) $>$ 31\% indicator (+)"

tab outcome, gen(outcome_)
label var outcome_1 "\hspace{5 mm}Current"
label var outcome_2 "\hspace{5 mm}Prepay"
label var outcome_3 "\hspace{5 mm}Foreclosure"

tab region, gen(region_)
label var region_1 "\hspace{5 mm}Northeast"
label var region_2 "\hspace{5 mm}Midwest"
label var region_3 "\hspace{5 mm}South"
label var region_4 "\hspace{5 mm}West"

drop if putoption == .
/*************
Tables - paper
*************/

sort id date
set more off

by id: keep if _n==_N

	estpost tabstat ///
	white black hispanic other income /// /*race and income */
	m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region_1 region_2 region_3 region_4 /// /*neighborhood*/
	putoption putoption2 calloption calloption2 /// /*put and call option*/
	fico_1-fico_4 highcostloan ltv purpose arm modind pti_dummy putoption putoption2 calloption calloption2 /// /*loan*/
	outcome_1 outcome_2 outcome_3 /// /*dependent variables*/
	, statistics(N mean sd min max) columns(statistics)
	est sto basic_race_all
	
	#delimit ;
	esttab basic_race_all using "$tables/descriptives_paper.tex",
	varlabels(,blist(
	white "& & & & \\ `=char(13)' \emph{Race \& income:} & & & \\ `=char(13)'" 
	m_dwb_a_09 "& & & & \\ `=char(13)' \emph{Index of segregation:} & & & \\ `=char(13)'" 
	region_1 "& & & & \\ `=char(13)' \emph{Region:} & & & \\ `=char(13)'" 
	putoption "& & & & \\ `=char(13)' \emph{Put (default) option:} & & & \\ `=char(13)'" 	
	calloption "& & & & \\ `=char(13)' \emph{Call (prepay) option:} & & & \\ `=char(13)'"
	fico_1 "& & & & \\ `=char(13)' \emph{Loan:} & & & \\ `=char(13)'" 
	outcome_1 "& & & & \\ `=char(13)' \emph{Dependent variables:} & & & \\ `=char(13)'")) 
	collabels(, lhs("Variables (expected sign)"))  cell("mean(fmt(%9.3fc)) sd(fmt(%9.3fc)) min(fmt(%9.0fc)) max(fmt(%9.0fc))") nomtitle nostar unstack nonote nonumber label replace  
	addnote("As of last period of observation" "* Indicates time-varying covariate") noobs ;
	#delimit cr


est clear
