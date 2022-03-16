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

use "$data_files/CTS_sample_1.dta", clear

/******
Clean
******/

sort loannum zip date
by loannum zip: gen count = 1 if _n==_N
tab count

* Keep single (1-4) family homes from HMDA

keep if proptype== 1
drop proptype*
tab count

*-Owner

keep if owner == 2
drop owner
tab count

* Keep 1st lien and single (1-4) family homes from HMDA

keep if lien == 1
drop lien
tab count

* Drop if a loannum ever went into Bankruptcy

sort loannum zip date
gen bankind = 0
replace bankind = 1 if delinquent == 15
gen everbank = bank
by loannum zip: replace everbank = 1 if everbank[_n-1]==1
by loannum zip: replace everbank = 1 if everbank[_N]==1
drop if everbank == 1
drop everbank bank
tab count

* Drop if hmda data is missing
drop if race == .
drop if income == .
drop if purpose == .
tab count

*Drop if there is only one observation
by loannum zip: gen number = _n
by loannum zip: replace number = _N
drop if number==1
drop number
tab count

*interim save 
*save `$data_files/test.dta', replace
*use `$data_files/test.dta', clear

do `"$do_files/02_clean_b_cts.do"' /*clean cts data*/
tab count

do `"$do_files/02_clean_c_hmda.do"' /*clean hmda data*/
tab count

/********
Merges
********/

*2005 - 2009 ACS, 5 year average
*ACS tract files
merge m:1 state county censustract using  `"$support_files/acs_tract_stuff.dta"', keepusing(per_poor per_nonwhite tract_med_fam_income)
keep if _m == 3
drop _m
tab count

*Convert tract to cbsa
merge m:1 state county censustract using `"$support_files/tract_to_cbsa.dta"', keepusing(cbsa)
keep if _m == 3
drop _m
tab count

*ACS cbsa files
merge m:1 cbsa using `"$support_files/acs_cbsa_stuff.dta"', keepusing(cbsa_med_fam_income)
keep if _m == 3
drop _m
tab count

drop if per_poor == . | per_nonwhite == . | tract_med_fam_income == . | cbsa_med_fam_income == .
tab count

*interim save 2
*save JPL.Folder/foreclosure/data_files/test2.dta, replace
*use JPL.Folder/foreclosure/data_files/test2.dta, clear

/******
Freddie Mac PMMS
http://www.freddiemac.com/pmms/pmms_archives.html
30 Year Fixed Rate Mortgage
******/

merge m:1 date using `"$support_files/fedrate.dta"', keepusing(fedrate)
keep if _merge == 3
drop _merge
label drop _merge
label var fedrate "Freddie Mac PMMS - Current Month x 100"
tab count

/******
Zillow Real Estate Research
http://www.zillow.com/research/data/
Zillow Home Value Index (ZHVI)
All Homes (SFR, Condo/Co-op)
90% match
******/
drop count
sort loannum zip date
by loannum zip: gen count = 1 if _n == _N
sum count
local pre = r(N)
di `pre'

/*
preserve
	do `"$do_files/02_clean_d_zillow.do"' /*clean zillow data*/
restore
*/

*Home value by zip
merge m:1 zip date using `"$support_files/zillow.dta"'
keep if _m == 3
drop _m
rename date test
rename notedate date
rename mean_value test2
merge m:1 zip date using `"$support_files/zillow.dta"'
keep if _m == 3
drop _m
rename date notedate
rename test date	
rename mean_value value_at_origination
rename test2 mean_value

drop count
sort loannum zip date
by loannum zip: gen count = 1 if _n == _N
tab count
local pst = r(N)
di `pst'/`pre' /*% of cases matching to zillow data*/

*drop if loan has missing zillow data, i.e. zillow has values for some, but not all zips by date

sort loannum zip date
by loannum zip: gen test = 1 if mean_value == . & _n~=_N
by loannum zip: replace test = 1 if test[_n-1]==1
by loannum zip: replace test = 1 if test[_N]==1
drop if test == 1
drop test
tab count


/******
do "$do_files/fhfa_hpi_cbsa_segregation.do"
Replace home value by zip with cbsa value if zip == .
Federal Housing Finance Agency
Housing price index
quarterly index data
http://www.fhfa.gov/Default.aspx?Page=87
All-transactions index metropolitian statistical areas (not seasonally adjusted)
gen quarterly = qofd(dofm(date))
merge m:1 cbsa quarterly using JPL.Folder/foreclosure/support_files/housing_prices_msa/fhfa_hpi_cbsa.dta,keepusing(hpi)
tab count _m
******/

*interim save 3
*save JPL.Folder/foreclosure/data_files/test3.dta, replace
*use JPL.Folder/foreclosure/data_files/test3.dta, clear

/*******
Clean
*******/
drop count
sort loannum zip date
by loannum zip: gen count = 1 if _n == _N
tab count

do  `"$do_files/02_clean_e_labelling.do"'
tab count

/*******
Region
*******/

gen region = 1 if state == 23 | state == 25 | state ==  33 | state ==  34 | state ==  36 | state ==  42 | state ==  44 | state ==  50
replace region = 2 if state == 17 | state ==  18 | state ==  19 | state ==  20 | state ==  21 | state ==  26 | state ==  27 | state ==  29 | state ==  31 | state ==  38 | state ==  39 | state ==  55 
replace region = 3 if state == 1 | state ==  5 | state ==  10 | state ==  11 | state ==  12 | state ==  13 | state ==  21 | state ==  22 | state ==  24 | state ==  28 | state ==  37 | state ==  40 | state ==  45 | state ==  47 | state ==  48 | state ==  51 | state ==  54
replace region = 4 if state == 2 | state ==  4 | state ==  6 | state ==  8 | state ==  15 | state ==  16 | state ==  30 | state ==  32 | state ==  35 | state ==  41 | state ==  49 | state ==  53 | state ==  56 

/*******
Save
*******/

drop count
sort id date
by id: gen count = 1 if _n==_N
tab count

drop loannum inirate intforgive prinforgive tempmodif loanamount indpaydate 
sort id date
compress
order id date
save `"$data_files/cts_hmda_data_sample_1.dta"' , replace
