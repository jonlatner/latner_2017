
rename RepCounty county
destring county, replace
destring census, replace

sort loannum zip date

********
* Race characteristics
********

recode race (3 = 5)
recode race (4 = 3) (5 = 4)
label define racegen 4 "other, incl. asian", modify
tab race, gen(racegen)
rename racegen1 white
rename racegen2 black
rename racegen3 hispanic
rename racegen4 other
label var white "White"
label var black "Black"
label var hispanic "Hispanic"
label var other "Other"

capture label drop racegen
capture label drop race

label define race 1 "White"
label define race 2 "Black", add
label define race 3 "Hispanic", add
label define race 4 "Other", add
label values race race

drop minority
tab count
	
********
* Income characteristics
********

replace income = income* 1000
by loannum zip: gen pti = pandi[1]
replace pti = pti/(income/12)

*drop if pti >= 1 monthly take home pay
by loannum zip: gen test = 1 if (pti>1 & pti~=.)
by loannum zip: replace test = 1 if test[_n-1]==1
by loannum zip: replace test = 1 if test[_N]==1
drop if test == 1
drop test

tab count

********
* Loan characteristics
********

gen highcostloan = ratespread
replace highcostloan = 1 if ratespread != .
replace highcostloan = 0 if ratespread == .
label var highcost "High Cost Loan (\textgreater = 300 BPS Indicator)"
drop ratespread

*-Purpose
label drop purpose
replace purpose = 0 if purpose == 2
label define purpose 1 "Home purchase"
label define purpose 0 "Refinance", add
label values purpose purpose
tab count
