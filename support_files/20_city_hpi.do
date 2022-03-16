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

* Enter the location of the CTS data files
global support_files = `"$location/support_files"'

* Change directory
cd "$location"

/******
Load data
******/

import excel "$support_files/20_city_hpi.xls", sheet("Sheet2") firstrow clear

gen date = ym(year,month)
format date %tm
drop year month

reshape long cbsa_, i(date) j(test)
rename test cbsa
rename cbsa_ hpi_msa

generate year = yofd(dofm(date))

keep if year==2007 | year==2013

sort cbsa year date
by cbsa year: egen hpi = mean(hpi_msa)
by cbsa year: keep if _n == 1

by cbsa: gen case_shiller = (hpi[2] - hpi[1])/ hpi[1]
by cbsa: keep if _n == 1

keep cbsa case_shiller

rename cbsa metroid
merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta", keepusing(metroname m_dwb_a_09 m_dwh_a_09 m_dwa_a_09 region m_t_a_09 rank)
keep if _m == 3
drop _m
rename metroid cbsa


*twoway (scatter case_shiller m_dwb_a_09 if rank<150) (lfit case_shiller m_dwb_a_09 if rank<150)


gen big_city = 1


save "$support_files/20_city_hpi.dta", replace
