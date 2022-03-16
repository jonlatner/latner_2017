*use JPL.Folder/foreclosure/data_files/test.dta, clear

/********
Format loannum & servicer
********/

sort loannum zip date
by loannum zip date: replace svcer = svcer[1]
encode svcer, gen(servicer)
drop svcer
label var servicer "Servicer Name"

/********
If notedate is missing, use paydate as a proxy
********/

replace paydateyr = paydateyr+1900 if paydateyr>=10
replace paydateyr = paydateyr+2000 if paydateyr<10
gen indpaydate = 1 if notedateyr == .
replace notedateyr = paydateyr if notedateyr == .
replace notedatemo = paydatemo if notedatemo == .
drop paydate*

/********
For duplicate cases (loannum, zip, date) identify and drop as it is not known which case is "correct"
********/

sort loannum zip date
duplicates tag loannum date, gen (dups)
by loannum zip: replace dups = 1 if dups[_n-1] == 1
by loannum zip: replace dups = 1 if dups[_N] == 1
drop if dups == 1
drop dups

/********
Keep "living loans:"
reo ~= 1, prepaid ~= 1 in period 1
no Bankruptcy
********/

sort loannum zip date
by loannum zip: gen reo = 1 if delinquent[1] == 70
by loannum zip: gen prepaid = 1 if delinquent[1] == 60
drop if reo == 1
drop if prepaid == 1
drop reo prepaid
		
/********
Format dates
********/

gen notedate = ym(notedateyr, notedatemon)
tostring date, replace
gen year = substr(date, 1, 4)
gen month = substr(date, 5, 6)
destring year month, replace
drop date

gen date = ym(year, month)
drop year month pandimon pandiyr notedateyr notedatemon notedateday

generate year = yofd(dofm(notedate))
format year %ty

/******
Delinquency
******/

gen delinqhis2 = substr(delinqhis, 1, 1)
gen delinqhis3 = .

replace delinqhis3 = 0 if delinqhis2 == "0"
replace delinqhis3 = 1 if delinqhis2 == "1"
replace delinqhis3 = 2 if delinqhis2 == "2"
replace delinqhis3 = 3 if delinqhis2 == "3"
replace delinqhis3 = 4 if delinqhis2 == "U"

destring delinqhis3, replace
drop delinqhis2

rename delinqhis3 delinqhis2
label define delinqhis2 0 "Not Delinquent"
label define delinqhis2 1 "30 Days Delinquent", add
label define delinqhis2 2 "60 Days Delinquent", add
label define delinqhis2 3 "90 days Delinquent", add
label define delinqhis2 4 "Unknown", add
label values delinqhis2 delinqhis2
label var delinqhis2 "Months Delinquent as of Current Month"
drop delinqhis

gen delinqhis4 = delinqhis2
recode delinqhis4 (0/1=0) (4=.) (2/3=1)
label var delinqhis4 "60+ Days Delinquent"
 
/********
LTV
1) Within each group, if the first value is mising, but the last value is not, replace all values with the last value.
2) The opposite: Within each group, if the last value is mising, but the first value is not, replace all values with the first value.
3) Where the last value in a case does not equal the first value, replace all values with the first value
********/

sort loannum zip date
replace ltv = ltv*100 if ltv<1
by loannum zip: replace ltv = ltv[_N] if ltv[1] == . 
by loannum zip: replace ltv = ltv[1] if ltv[_n==_N] == .
by loannum zip: replace ltv = ltv[1] if ltv[1] != ltv[_N]
by loannum zip: replace ltv = ltv[1]

by loannum zip: replace cltv = cltv[_N] if cltv[1] == . 
by loannum zip: replace cltv = cltv[1] if cltv[_n==_N] == .
by loannum zip: replace cltv = cltv[1] if cltv[1] != cltv[_N]
by loannum zip: replace cltv = cltv[1]

replace ltv = . if ltv == 0
replace cltv = . if cltv == 0
replace ltv=ltv/10
replace cltv = ltv if cltv<ltv
replace cltv = ltv if cltv == .

drop ltv
rename cltv ltv
replace ltv = ltv*100 if ltv<1
drop if ltv == .

/********
Interest Rate
********/

* Rate
replace rate = rate/1000 if rate>=1000
label var rate "Interest Rate x 100"

*Cleaning
*replace case with previous case if case jumps dramatically from one period to the next
by loannum zip: gen test = 1 if (abs(rate - rate[_n+1]) > 2) & _n~=_N & (abs(rate - rate[_n-1]) > 2) & _n ~= 1
by loannum zip: replace rate = rate[_n-1] if test == 1
drop test

*replace case with previous case if case jumps dramatically from the first period to the second
by loannum zip: gen test = 1 if (rate[_n+1] - rate > 4) & _n == 1 
by loannum zip: replace rate = rate[_n+1] if test == 1
drop test

*after all this, drop case if rate<1 or rate>15
by loannum zip: gen test = 1 if rate < 1
by loannum zip: replace test = 1 if test[_n-1]==1
by loannum zip: replace test = 1 if test[_N]==1
drop if test == 1
drop test
by loannum zip: gen test = 1 if rate > 15
by loannum zip: replace test = 1 if test[_n-1]==1
by loannum zip: replace test = 1 if test[_N]==1
drop if test == 1
drop test

*replace case if there is a missing rate 
by loannum zip: gen test = 1 if rate == .
by loannum zip: replace test = 1 if test[_n-1]==1
by loannum zip: replace test = 1 if test[_N]==1
drop if test == 1
drop test

/********
Assorted
********/

* Loan term
*destring term, replace

* FICO
replace fico = . if fico == 0 | fico > 800
by loannum zip: replace fico = fico[_N] if fico[1] == . 
by loannum zip: replace fico = fico[1] if fico[_n==_N] == .
by loannum zip: replace fico = fico[1] if fico[1] != fico[_N]
by loannum zip: replace fico = fico[1]
drop if fico == .

* PANDI
replace pandi = pandi/100
label var pandi "Current Payment \& Interest (PANDI) (\\$)"

*drop if loan has missing pandi data in period 1
by loannum zip: gen test = 1 if pandi == 0 & _n == 1
by loannum zip: replace test = 1 if test[_n-1]==1
by loannum zip: replace test = 1 if test[_N]==1
drop if test == 1
drop test

* OBALANCE
replace obalance = obalance/100 if date>=597 | date == 595
*replace case with previous case if case jumps dramatically from one period to the next*/
by loannum zip: gen test = 1 if obalance/obalance[_n-1] > 1.5 & _n~=_N & _n>1
replace obalance = obalance[_n-1] if test == 1
drop test
replace obalance = obalance/100 if obalance>10000000
replace obalance = round(round(obalance,.1),1)
by loannum zip: replace obalance = obalance[1]

* CBALANCE
replace cbalance = cbalance/100 if date>=597 | date == 595
replace cbalance = round(round(cbalance,.1),1)
*replace case with previous case if case jumps dramatically from one period to the next*/
by loannum zip: gen test = 1 if cbalance/cbalance[_n-1] > 1.5 & _n~=_N & _n>1 
replace cbalance = cbalance[_n-1] if test == 1
drop test
replace cbalance = cbalance/100 if cbalance>10000000

* ARM
replace armind = 1 if armind == 1
label var armind "Adjustable Rate Mortgage (ARM) Indicator"

* If a loannum received a mod, then all future loans are modified
gen modind = 0
replace modind = 1 if modifdatyr != .
drop modif*

replace modind = . if modind == 0
by loannum zip: replace modind = 1 if modind[_n-1] == 1
replace modind = 0 if modind == .
label var modind "Post Modification Indicator"

/******
Declare outcome:
Basically, REO trumps payoff.  If a loan went into REO before payoff, it is REO.  If a loan went into REO after payoff, it is payoff.
******/
by loannum zip: gen outcome = 0
by loannum zip: replace outcome = 1 if delinquent == 60
by loannum zip: replace outcome = 1 if outcome[_n-1] == 1
by loannum zip: replace outcome = 2 if delinquent == 70 
by loannum zip: replace outcome = 2 if outcome[_n-1] == 2
label define outcome 0 "current"
label define outcome 1 "payoff", add
label define outcome 2 "reo", add
label values outcome outcome
drop if outcome == .
