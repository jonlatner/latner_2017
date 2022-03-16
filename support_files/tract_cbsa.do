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
global data_files = `"$location/data_files/sample_20"'

* Enter the location of the HMDA data files
global hmda_data_files = `"/Volumes/GoogleDrive/My Drive/HMDA"'

* Enter the location of the CTS data files
global cts_data_files = `"/Volumes/GoogleDrive/My Drive/CTS/raw_data"'

* Enter the location of the CTS data files
global support_files = `"$location/support_files"'

* Change directory
cd "$location"

/******
Load data
******/

import delimited "$support_files/tract_cbsa.csv", varnames(1) rowrange(3) encoding(ISO-8859-1) clear

replace county=substr(county,-3,.)
destring county tract cbsa, replace
rename tract censustract

gen state = substr(cntyname,-2,.)
replace state = "VA" if state == "R)"
replace state = "DC" if state == "D)"

drop if cbsa == .

merge m:1 state using "$support_files/state_fips.dta", keepusing(fips) 
keep if _m == 3
drop _m


gen state2=state
drop state
rename fips state
rename state2 statename



*duplicates tag state county censustract, gen(dups)

gsort state county censustract -afact
by state county censustract: keep if _n == 1

save "$support_files/tract_to_cbsa.dta", replace
