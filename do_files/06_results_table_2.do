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
Segregation
*************/

merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta", keepusing(m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region division)
keep if _m == 3
drop _m

merge m:1 metroid using "$support_files/acs_isolation_09.dta", keepusing(metroname m_xbb_a_09 m_xhh_a_09 m_xaa_a_09)
keep if _m == 3
drop _m

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
mean center
*************/
drop if putoption == .
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
NATIONAL SAMPLE
*************/

*RACE AND INCOME
set more off
estimates use "$results/race_inc_interaction_region_center.ster"
estimates esample:
estimates replay
est sto race_inc_int

estadd local space ""
estadd local control ""
estadd local year "Yes"
estadd local race_inc_int "Yes"
estadd local region "Yes"
estadd local loan "No"

*SEGREGATION
set more off
estimates use "$results/segregation_region_center.ster"
estimates esample:
estimates replay
est sto seg

estadd local control ""
estadd local space ""
estadd local control ""
estadd local year "Yes"
estadd local race_inc_int "No"
estadd local region "Yes"
estadd local loan "No"

*RACE/INCOME + SEGREGATION 
set more off
estimates use "$results/race_segregation_region_center.ster"
estimates esample:
estimates replay
est sto main_effect

estadd local control ""
estadd local space ""
estadd local control ""
estadd local year "Yes"
estadd local race_inc_int "Yes"
estadd local region "Yes"
estadd local loan "No"

*RACE/INCOME + SEGREGATION + RACE/SEGREGATION INTERACTION
set more off
estimates use "$results/race_segregation_int_center.ster"
estimates esample:
estimates replay
est sto interaction

estadd local control ""
estadd local space ""
estadd local control ""
estadd local year "Yes"
estadd local race_inc_int "Yes"
estadd local region "Yes"
estadd local loan "No"

*RACE/INCOME + SEGREGATION + RACE/SEGREGATION INTERACTION + LOAN CONTROLS
set more off
estimates use "$results/full_model_no_option.ster"
estimates esample:
estimates replay
est sto control

estadd local control ""
estadd local space ""
estadd local control ""
estadd local year "Yes"
estadd local race_inc_int "Yes"
estadd local region "Yes"
estadd local loan "Yes"

*RACE/INCOME + SEGREGATION + RACE/SEGREGATION INTERACTION + LOAN CONTROLS + OPTIONS (MAIN MODEL)
set more off
estimates use "$results/borrower_geo_loan_seg_int_center.ster"
estimates esample:
estimates replay
est sto main

estadd local space ""
estadd local control ""
estadd local year "Yes"
estadd local race_inc_int "Yes"
estadd local region "Yes"
estadd local loan "Yes"

/*************
REGIONAL SAMPLE
*************/

foreach i of numlist 1/4 {
set more off
estimates use "$results/main_model_center_region_`i'.ster"
estimates esample:
estimates replay
est sto region_`i'

estadd local space ""
estadd local control ""
estadd local year "Yes"
estadd local race_inc_int "Yes"
estadd local region "N/A"
estadd local loan "Yes"
}

/*************
SELECTED CHARACTERISTICS FOR NATIONAL SAMPLE
*************/

#delimit;
esttab race_inc_int seg main_effect interaction control main region_1 region_2 region_3 region_4 using "$tables/stcrreg_default.tex", 
mlabels("Race \& inc." "Segregation" "Race, inc., \& seg" "+ Interaction" "+ Loan controls" "+ Options (Main)" "Northeast" "Midwest" "South" "West")
varlabels( 
2.race "Black" 3.race "Hispanic" 4.race "Other" income "Income (\\$10,000s)"
putoption "Put option" calloption "Call option" c.putoption#c.putoption "Put option$^2$" c.calloption#c.calloption "Call option$^2$"
m_dwb_a_09 "Black" m_dwh_a_09 "Hispanic" m_dwa_a_09 "Asian" 
2.race#c.m_dwb_a_09 "Black \& Black segregation" 3.race#c.m_dwb_a_09 "Hispanic \& Black segregation" 4.race#c.m_dwb_a_09 "Other \& Black segregation"
,blist( 
2.race "& & & & & \\ `=char(13)' \emph{Borrower:} & & & & & \\ `=char(13)'" 
m_dwb_a_09 "& & & & & \\ `=char(13)' \emph{Segregation:} & & & & & \\ `=char(13)'" 
2.race#c.m_dwb_a_09 "& & & & & \\ `=char(13)' \emph{Race \& segregation interaction:} & & & & & \\ `=char(13)'" 
putoption "& & & & & \\ `=char(13)' \emph{Put (default) option:} & & & & & \\ `=char(13)'" 	
calloption "& & & & & \\ `=char(13)' \emph{Call (prepay) option:} & & & & & \\ `=char(13)'" 
))
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
drop(*b.* *o.*, relax)
 keep(2.race 3.race 4.race income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 2.race#c.m_dwb_a_09 3.race#c.m_dwb_a_09 4.race#c.m_dwb_a_09 putoption c.putoption#c.putoption calloption c.calloption#c.calloption) 
order(2.race 3.race 4.race income m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 2.race#c.m_dwb_a_09 3.race#c.m_dwb_a_09 4.race#c.m_dwb_a_09 putoption c.putoption#c.putoption calloption c.calloption#c.calloption) 
scalar("N Number of Observations" "N_sub Number of Subjects" "N_fail Number of Failures (Foreclosure)" "N_compete Number of Competing (Prepay)" 
"space \hspace{5mm}" "control \emph{Control variables:}" "year Year of origination" "region Region" "race_inc_int Race \& Income interaction" "loan Loan performance (LTV, ARM, etc.)") 
sfmt(%12.0fc %12.0fc %12.0fc) 
note("National models are run on a 20\% sample.  Regional models are run on a 50\% regional sample.")
eqlabels(none) noobs legend depvars tex label nomtitle eform replace;
#delimit cr

/*************
CONTROL VARIABLES FOR NATIONAL SAMPLE
*************/

#delimit;
esttab race_inc_int seg main_effect interaction control main region_1 region_2 region_3 region_4 using "$tables/control.tex", 
mlabels("Race \& inc." "Segregation" "Race, inc., \& seg" "+ Interaction" "+ Loan controls" "+ Options (Main)" "Northeast" "Midwest" "South" "West")
varlabels( 
2.race "Black" 3.race "Hispanic" 4.race "Other" income "Income (\\$10,000s)"
2.race#c.income "Black \& income" 3.race#c.income "Hispanic \& income" 4.race#c.income "Other \& income" 
1b.fico_ "FICO $<$620 (\emph{ommitted})" 2.fico_ "FICO (620-679)" 3.fico_ "FICO (680-719)" 4.fico_ "FICO ($>=$ 720)"	
1.highcostloan "High cost loan (\textgreater = 300 BPS indicator)" 1.purpose "Purchase (vs. refinance) indicator" 1.armind "ARM indicator" 1.modind "Modification indicator" 1.pti_dummy "PTI $>$ 31\% indicator"	
putoption "Put option" calloption "Call option" c.putoption#c.putoption "Put option$^2$" c.calloption#c.calloption "Call option$^2$"
m_dwb_a_09 "Black/white segregation in MSA" m_dwh_a_09 "Hispanic/white segregation in MSA" m_dwa_a_09 "Asian/white segregation in MSA" 
2.race#c.m_dwb_a_09 "Black \& Black segregation" 3.race#c.m_dwb_a_09 "Hispanic \& Black segregation" 4.race#c.m_dwb_a_09 "Other \& Black segregation"
1b.region "Northeast (\emph{ommitted})" 2.region "Midwest" 3.region "South" 4.region "West" 
2005.year "2005" 2006.year "2006" 2007.year "2007"
,blist( 
2005.year "& & & & & \\ `=char(13)' \emph{Year of origination:} & & & & & \\ `=char(13)'" 
2.race#c.income "& & & & & \\ `=char(13)' \emph{Race \& income interaction:} & & & & & \\ `=char(13)'" 
2.region "& & & & & \\ `=char(13)' \emph{Region:} & & & & & \\ `=char(13)' \emph{Northeast (ommitted)} & & & & & \\ `=char(13)'" 
2.fico_ "& & & & & \\ `=char(13)' \emph{Loan characteristics:} & & & & & \\ `=char(13)' \emph{FICO $<$ 620 (ommitted)} & & & & & \\ `=char(13)'"))
cells(b(star fmt(%9.3f)) se(par fmt(%9.3f)))
rename(highcostloan 1.highcostloan)
keep(2005.year 2006.year 2007.year 2.race#c.income 3.race#c.income 4.race#c.income 2.region 3.region 4.region 2.fico_ 3.fico_ 4.fico_ 1.highcostloan ltv 1.purpose 1.armind 1.modind 1.pti_dummy)
order(2005.year 2006.year 2007.year 2.race#c.income 3.race#c.income 4.race#c.income 2.region 3.region 4.region 2.fico_ 3.fico_ 4.fico_ 1.highcostloan ltv 1.purpose 1.armind 1.modind 1.pti_dummy)
note("National models are run on a 20\% sample.  Regional models are run on a 50\% regional sample.")
eqlabels(none) noobs legend depvars tex nomtitle eform label replace;
#delimit cr

