/***************
Preliminaries

This file is for the creation of 50% sample used to run separate models in the 4 regions
50% sample is not strictly necessary as similar results are attained with 20% model
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

* Enter the location of the HMDA data files
global hmda_raw_data_files = `"/Volumes/GoogleDrive/My Drive/HMDA"'

* Enter the location of the CTS data files
global cts_raw_data_files = `"/Volumes/GoogleDrive/My Drive/CTS/raw_data"'
global cts_data_files = `"/Volumes/GoogleDrive/My Drive/CTS/data_CTS/sample_50"'

* Change directory
cd "$location"

*******
* Append CTS data
*******

forval i = 1/56 {
use "$cts_raw_data_files/CTS_200612.dta", clear
foreach x in 200701 200702 200703 200704 200705 200706 200707 200708 200709 200710 200711 200712 200801 200802 200803 200804 200805 200806 200807 200808 200809 200810 200811 200812 200901 200902 200903 200904 200905 200906 200907 200908 200909 200910 200911 200912 201001 201002 201003 201004 201005 201006 201007 201008 201009 201010 201011 201012 201101 201102 201103 201104 201105 201106 201107 201108 201109 201110 201111 201112 201201 201202 201203 201204 201205 201206 201207 201208 201209 201210 201211 201212 201301 201302 201303 201304 201305 201306 201307 201308 201309 201310 201311 201312 201401 201402 201403 {
append using "$cts_raw_data_files/CTS_`x'.dta", force
keep if state == `i'
}

*******
* HMDA merge
*******
drop purpose2 proptype2 /*drop purpose and proptype from cts because of missing data issues.  cts has missing data, hmda has none.  plus there is conflicting data.  i take hmda */

sort loannum zip notedateyr
merge m:1 loannum zip notedateyr using "$hmda_raw_data_files/HMDA.merge.carolina.dta", keepusing(race minority male income loanamount ratespread RepCounty censustract proptype purpose)
keep if _merge == 3 
drop _merge
label drop _merge

*create sample

sort loannum zip
preserve
tempfile tmp
bysort loannum zip: keep if _n == 1
sample 50
sort loannum zip
save `tmp'
restore
merge loannum zip using `tmp'
keep if _merge == 3
drop _merge 


save "$cts_data_files/CTS_state_`i'.dta", replace
}

* Region 1

use "$cts_data_files/CTS_state_9.dta", clear
foreach i in 23 25 33 34 36 42 44 50 {
append using  "cts_data_files/CTS_state_`i'.dta"
}

save "$data_files/region_1.dta", replace

* Region 2

use "$cts_data_files/CTS_state_17.dta", clear
foreach i in 18 19 20 21 26 27 29 31 38 39 55 {
append using  "$cts_data_files/CTS_state_`i'.dta"
}

save "$data_files/region_2.dta", replace

* Region 3

use "$cts_data_files/CTS_state_1.dta", clear
foreach i in 5 10 11 12 13 21 22 24 28 37 40 45 47 48 51 54 {
append using  "$cts_data_files/CTS_state_`i'.dta"
}

save "$data_files/region_3.dta", replace

* Region 4

use "$cts_data_files/CTS_state_2.dta", clear
foreach i in 4 6 8 15 16 30 32 35 41 49 53 56 {
append using  "$cts_data_files/CTS_state_`i'.dta"
}

save "$data_files/region_4.dta", replace


