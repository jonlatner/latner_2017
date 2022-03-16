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

* Enter the location of the CTS data files
global support_files = `"$location/support_files"'

* Change directory
cd "$location"

/*************
* Load data
*************/

import delimited using "$data_files/test_compare_stata_r_small.csv", clear

/*************
Default hazard model, controlling for probability of prepayment
*************/

stset dur, id(id) fail(outcome == 2)

stcrreg black hispanic other putoption calloption, compete(outcome == 1)

mlogit outcome black hispanic other ficoscore putoption calloption, cluster(id)

