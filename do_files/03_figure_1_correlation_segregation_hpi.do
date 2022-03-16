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

* Enter the location of the data files
global graphs = `"$location/graphs"'

* Enter the location of the CTS data files
global support_files = `"$location/support_files"'

* Change directory
cd "$location"

/******
Load data
Data are from the Case Schiller Housing Price Index
******/

* do "$support_files/20_city_hpi.do"
use "$support_files/20_city_hpi.dta", clear
keep if case_shiller ~= .
keep cbsa m_dwb_a_09

merge 1:1 cbsa using "$support_files/20_city_hpi.dta", keepusing(case_shiller)
keep if _m == 3
drop _m

replace cbsa = 16974 if cbsa == 16980 /*Chicago, IL Metropolitan Division*/
replace cbsa = 19124 if cbsa == 19100 /*Fort Worth-Arlington, TX Metropolitan Division*/
replace cbsa = 19804 if cbsa == 19820 /*Detroit, MI Metropolitan Division*/
replace cbsa = 31084 if cbsa == 31100 /*Los Angeles, CA Metropolitan Division*/
replace cbsa = 33124 if cbsa == 33100 /*Miami, FL Metropolitan Division*/
replace cbsa = 41884 if cbsa == 41860 /*Oakland, CA Metropolitan Division*/
replace cbsa = 47894 if cbsa == 47900 /*Washington, D.C. Metropolitan Division*/

rename cbsa metroid
merge 1:1 metroid using "$support_files/fhfa_hpi_cbsa.dta", keepusing(fhfa)
keep if _m == 3
drop _m

cor case_shiller fhfa 
local cor_case_fhfa= trim("{it:r} = `:display %3.2f r(rho)'")

use "$support_files/fhfa_hpi_cbsa.dta", clear
append using "$support_files/20_city_hpi.dta"

replace big_city = 0 if big_city == .
gen str10 case_name = "."

replace case_name = "New York" if cbsa == 35620 
replace case_name = "Los Angeles" if cbsa == 31100 
replace case_name = "Chicago" if cbsa == 16980 
replace case_name = "Dallas" if cbsa == 19100 
replace case_name = "Miami" if cbsa == 33100 
replace case_name = "Washington D.C." if cbsa == 47900 
replace case_name = "Atlanta" if cbsa == 12060 
replace case_name = "Boston" if cbsa == 14460 
replace case_name = "Detroit " if cbsa == 19820 
replace case_name = "San Francisco" if cbsa == 41860 
replace case_name = "Phoenix" if cbsa == 38060 
replace case_name = "Seattle" if cbsa == 42660 
*replace case_name = "Minneapolis" if cbsa == 33460 
*replace case_name = "San Diego" if cbsa == 41740 
replace case_name = "Tampa Bay" if cbsa == 45300 
replace case_name = "Denver" if cbsa == 19740 
replace case_name = "Portland" if cbsa == 38900 
replace case_name = "Cleveland" if cbsa == 17460 
replace case_name = "Las Vegas" if cbsa == 29820 
replace case_name = "Charlotte" if cbsa == 16740 

gsort -m_t_a_09 
cor case_shiller m_dwb_a_09
local case = trim("{it:r} = `:display %3.2f r(rho)'")
cor fhfa m_dwb_a_09 if rank<=150
local fhfa = trim("{it:r} = `:display %3.2f r(rho)'")

*NEW - two lines
#delimit;
graph twoway  
(scatter case_shiller m_dwb_a_09 if m_dwb_a_09>35 & cbsa~=33460 & cbsa~=41740, msymbol(oh) mlabcolor(gs0) mcolor(gs0) mlabel(case_name)) 
(scatter fhfa m_dwb_a_09 if rank<=150, msymbol(oh) mcolor(gs12)) 
(lfit case_shiller m_dwb_a_09, lpattern(shortdash) lcolor(gs0)) 
(lfit fhfa m_dwb_a_09 if rank<=150, lcolor(gs8)) , 
xtitle(" " "Black/white dissimilarity index of segregation") ytitle("% change in HPI (2007 - 2013)" " ") ylabel(-.5(.1)0) 
text(.12 44.5 "`cor_case_fhfa' (FHFA & Case Shiller)") text(.06 39.5 "`fhfa' (FHFA)") text(0.0 41.5 "`case' (Case Shiller)") 
legend(order(2 "Case Shiller" 3 "Federal Housing Finance Agency (FHFA)") row(2)) 
xscale(r(35 80)) xlabel(39 `" "39"  "Las Vegas, NV" "' 48 `" "48"  "Phoenix, NV" "' 58 `" "60"  "Atlanta, GA" "' 70 `" "70"  "Philadelphia, PA" "' 80 `" "80"  "Detroit, MI" "') 
note("Source of segregation index: 2005 - 2009 American Community Survey" "Note: A few representative cities are shown for ease of understanding." "Case Shiller is 20 city index.  FHFA index is from the 150 largest cities (2005 - 2009 ACS)") 
;
#delimit cr
graph export "$graphs/segregation_hpi.png", replace
