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

* Enter the location of the HMDA data files
global hmda_raw_data_files = `"/Volumes/GoogleDrive/My Drive/HMDA"'

* Enter the location of the CTS data files
global cts_data_files = `"/Volumes/GoogleDrive/My Drive/CTS/raw_data"'
global cts_raw_data_files = `"/Volumes/GoogleDrive/My Drive/CTS/raw_data"'

* Enter the location of the CTS data files
global support_files = `"$location/support_files"'

* Change directory
cd "$location"

/******
Load data
******/

import excel "$support_files/housing_prices_msa/4q13hpi_cbsa.xls", sheet("Sheet1") firstrow allstring
destring cbsa year quarter Index standarderror, replace

rename Index hpi_msa
keep name cbsa year quarter hpi

gen quarterly = yq(year,quarter)
format quarterly %tq

keep if year==2007 | year==2013

sort cbsa year quarter
by cbsa year: egen hpi = mean(hpi_msa)
by cbsa year: keep if _n == 1

by cbsa: gen fhfa = (hpi[2] - hpi[1])/ hpi[1]
by cbsa: keep if _n == 1

keep cbsa fhfa 

replace cbsa = 14460 if cbsa == 14454 /*Boston-Quincy, MA Metropolitan Division*/
replace cbsa = 35620 if cbsa == 35614 /*New York-White Plains-Wayne, NY-NJ Metropolitan Division*/
replace cbsa = 42660 if cbsa == 42644 /*Seattle-Bellevue-Everett, WA Metropolitan Division*/

rename cbsa metroid
merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta", keepusing(metroname m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region m_t_a_09 rank)
keep if _m == 3
drop _m

*twoway (scatter hpi_delta m_dwb_a_09 if rank<150) (lfit hpi_delta m_dwb_a_09 if rank<150)

save "$support_files/fhfa_hpi_cbsa.dta", replace
