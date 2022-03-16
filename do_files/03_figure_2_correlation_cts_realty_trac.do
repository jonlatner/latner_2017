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

* Enter the location of the CTS data files
global support_files = `"$location/support_files"'

* Change directory
cd "$location"

/******
1. Create CTS foreclosure data
******/

/*

use "$data_files/cts_hmda_data_sample_20.dta", clear

collapse (sum) reo ,by(cbsa date)

save "$support_files/date_reo_cbsa_sample_20.dta", replace

generate year = yofd(dofm(date))
browse
collapse (sum) reo, by(cbsa year)

save "$support_files/year_reo_cbsa_sample_20.dta", replace
*/
 
/******
2. Create realty trac foreclosure data
******/

/*

NAME: CreateStateData.do
AUTHOR: Erik Hembre
DATE:  7/16/2014 (revised)
PURPOSE:  This file spits foreclosures by state


* Separate Foreclosures by State
* 1 instance per property (begin tracking everywhere in 2007 through 2013)  (Right now the file does not include REO sales at all. This might need to change)

clear 
set more off

cd "/GoogleDrive/My Drive/realty_trac"

* Open Main Foreclosure Data
use /raw_data/foreclosure/MasterForeclosure.dta

* Begin Tracking in 2007, through 2013
keep if Date>=`=m(2005m1)' & Date<=`=m(2013m12)'
* Get State FIPS Code
gen FIPS = floor(situsstatecountyfips/1000)
* Get County Code
gen county  = situsstatecountyfips-FIPS*1000
* Drop Territories
foreach i in 72 78 38 50 {
drop if FIPS==`i'
}
merge m:1 rtpropertyuniqueidentifier using /raw_data/tax_assessor/TaxMaster.dta, keep(master match) keepusing(combinedstatisticalarea)
drop _m
gen date = dofm(Date)
gen year = year(date)
drop if combinedstatisticalarea == ""
rename FIPS state
merge m:1 state combinedstatisticalarea using /geo_codes/realty_trac_cbsa.dta
keep if _m == 3
drop _m

recode recordtype (1/4=1) (nonm=.),gen(ForeInd)

collapse (firstnm) year recordtype cbsa combinedstatisticalarea (sum) ForeInd, by(rtpropertyuniqueidentifier)
collapse (sum) ForeInd, by(year cbsa combinedstatisticalarea)

save createcbsadata.dta, replace
*/

/******
3. Combine data
******/

use "$support_files/createcbsadata.dta", clear

replace cbsa = cbsa*10
merge 1:1 cbsa year using "$support_files/year_reo_cbsa_sample_20.dta", nogen

rename cbsa metroid
merge m:1 metroid using "$support_files/acs_dissimilarity_09.dta", keepusing(m_dwb_a_09 m_t_a_09 rank)
keep if _m == 3
drop _m

rename reo reo_cts
rename ForeInd reo_rt
rename m_t_a_09 population

sort metroid year
replace reo_cts = . if reo_cts == 0

/******
4. Summarise data
******/
collapse (sum) reo_*, by(metroid m_dwb)

*Calculate correlation

gen ln_reo_cts = ln(reo_cts)
gen ln_reo_rt = ln(reo_rt)

cor ln_reo_rt ln_reo_cts
local rt_cts = trim("{it:r} = `:display %3.2f r(rho)'")
cor ln_reo_rt m_dwb_a_09 
local realtytrac = trim("{it:r} = `:display %3.2f r(rho)'")
cor ln_reo_cts m_dwb_a_09 
local cts = trim("{it:r} = `:display %3.2f r(rho)'")

*Just to make the graph easier to interpret, drop bottom 5% of cities by segregation measure 
drop if m_dwb_a_09 <35 

/******
5. Graph data
******/

#delimit ;
graph twoway scatter ln_reo_rt m_dwb , mcolor(gs8) msymbol(Sh) || 
lfit ln_reo_rt m_dwb , lcolor(gs8) || 
scatter ln_reo_cts m_dwb , mcolor(gs1) msymbol(Oh) || 
lfit ln_reo_cts m_dwb , lcolor(gs1) 
xtitle(" " "Black/white dissimilarity index of segregation") ytitle("LN foreclosures (2007 - 2013)") 
legend(order(1 "Realtytrac" 2 "Fitted values" 3 "CTS" 4 "Fitted values")) 
yscale(range(0 20)) xscale(range(35 85)) xlabel(39 `" "39"  "Las Vegas, NV" "' 48 `" "48" " " "Phoenix, NV" "' 58 `" "60"  "Atlanta, GA" "' 70 `" "70" " " "Philadelphia, PA" "' 80 `" "80"  "Detroit, MI" "') 
note("Source of segregation index: 2005 - 2009 American Community Survey" "Note: A few representative cities are shown for ease of understanding.") 
text(18 39 "`cts' (CTS)") text(16 40.75 "`realtytrac' (Realtytrac)") text(20 43 "`rt_cts' (CTS & Realtytrac)")
;
#delimit cr

graph export "$graphs/cor_cts_realtytrac.png", replace

