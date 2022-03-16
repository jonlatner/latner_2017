*cd /project/cts/CTSProject/Foreclosure/
*use JPL.Folder/foreclosure/data_files/test3.dta, clear

egen id = group(loannum zip)
sort id date

*Drop all cases after REO or Payoff
*REO
gen reo = 1 if outcome == 2
by id: replace reo = 0 if reo[_n-1]==1
by id: replace reo = 0 if reo[_n-1]==0
drop if reo == 0
drop reo

*Payoff
gen payoff = 1 if outcome == 1
by id: replace payoff = 0 if payoff[_n-1]==1
by id: replace payoff = 0 if payoff[_n-1]==0
drop if payoff == 0
drop payoff

recode outcome (1=0) (2=1), gen(reo)
drop prepay
recode outcome (2=0), gen(prepay)
label var prepay "Prepay"
label var reo "REO"

*Drop cases if cbalance == 0 & _n==_N because it appears that these people prepay or default or something, but not clear which
by id: gen test = 1 if _n==_N & cbalance == 0 & outcome == 0
by id: replace test = 1 if test[_n-1]==1
by id: replace test = 1 if test[_N]==1
drop if test == 1
drop test
tab count

*Need to correct for the fact that given reo/payoff current balance zeros out
by id: replace cbalance = cbalance[_n-1] if cbalance == 0 & outcome>0 & _n==_N

recode ltv (min/80=1) (80/90=2) (90/100=3) (100/max=4), gen(ltv_)
label var ltv "Loan to value (LTV)"
replace ltv_=2 if ltv == 80
replace ltv_=3 if ltv == 90
replace ltv_=4 if ltv == 100
tab ltv_, gen(ltv_)
label var ltv_1 "LTV ($<$ 80)"
label var ltv_2 "LTV (80-89)"
label var ltv_3 "LTV (90-99)"
label var ltv_4 "LTV ($>=$ 100)"

*Call option
*Firestone et al., 2007
*the larger the call option, the more savings from refinance, and the more likely you are to prepay
gen calloption = (1 - (fedrate/rate)) * 100
label var calloption "Call (prepay) option"
gen calloption_1 = 0
replace calloption_1 = 1 if calloption<-3.5
gen calloption_2 = 0
replace calloption_2 = 1 if calloption>=-3.5 & calloption<3.5
gen calloption_3 = 0
replace calloption_3 = 1 if calloption>=3.5 & calloption<10
gen calloption_4 = 0
replace calloption_4 = 1 if calloption>=10 & calloption<25
gen calloption_5 = 0
replace calloption_5 = 1 if calloption>=25
label var calloption_1 "Penalty ($<$ -3.5\%)"
label var calloption_2 "Current ($-$3.5\%-3.49\%)"
label var calloption_3 "Cusp (3.5\%-9\%)"
label var calloption_4 "Premium (10\%-24\%)"
label var calloption_5 "Super-Premium ($>=$ 25\%)"
gen calloption_ = 1 if calloption_1 == 1
replace calloption_ = 2 if calloption_2 == 1
replace calloption_ = 3 if calloption_3 == 1
replace calloption_ = 4 if calloption_4 == 1
replace calloption_ = 5 if calloption_5 == 1
label define calloption_ 1 "Penalty ($<$ -3.5\%)"
label define calloption_ 2 "Current ($-$3.5\%-3.49\%)", add
label define calloption_ 3 "Cusp (3.5\%-9\%)", add
label define calloption_ 4 "Premium (10\%-24\%)", add
label define calloption_ 5 "Super-Premium ($>=$ 25\%)", add
label values calloption_ calloption_

/*
Deng, 1997
A typical way to value the call option in empirical real estate finance research is to
compute the ratio of the present discounted value of the unpaid mortgage balance at the
contract interest rate relative to the value discounted at the current market mortgage rate,
assuming a deterministic term structure.

in other words: total loan cost at current market rate / total loan cost at market interest rate

http://www.calcunation.com/calculators/business%20and%20finance/mortgage-total-cost.php

destring term, replace
gen test_current_r = rate/100/12
gen test_market_r = fedrate/100/12
gen test_term = date - (term - notedate)
gen test_current = ((test_current_r*cbalance)/(1-(1+test_current_r)^-test_term))*test_term
gen test_market = ((test_market_r*cbalance)/(1-(1+test_market_r)^-test_term))*test_term
gen alt_calloption = 100*(1-test_market/test_current)
drop test*

cor *calloption
alt_calloption and calloption are virtually identical

Therefore, firestone et al., 1997, who use rate not discounted value, is appropriate

*/

*Put option
*the larger the put option, the more likely you are to default
gen current_value = (obalance*((100-ltv)/100+1))*(mean_value/value_at)
*if putoption>0, then the balance of the loan is larger than the current value (bad) - i.e., you sell the house and you have to pay more
*if putoption<0, then the balance of the loan is smaller than the current value (good) - i.e., you sell the house and you get money back
*Note: putoption can still be in the money even if the house has depreciated in value.  The reason is the put option merely refers to equity in the house.
gen putoption = (cbalance/current_value - 1) * 100
label var putoption "Put (default) option"

gen appreciation = (current_value/obalance - 1) * 100
*delete cases where put option is greater than 500, meaning if they sold  their home, they would reap quintiple their original investment.  given that no loan was originated prior to 2004 and the time period, this seems implausible.
gen test = 1 if putoption>=500 & putoption ~= .
by id: replace test = 1 if test[_n-1]==1
by id: replace test = 1 if test[_N]==1
drop if test == 1
drop test
tab count


gen putoption_1 = 0
replace putoption_1 = 1 if putoption<-3.5
gen putoption_2 = 0
replace putoption_2 = 1 if putoption>=-3.5 & putoption<3.5
gen putoption_3 = 0
replace putoption_3 = 1 if putoption>=3.5 & putoption<10
gen putoption_4 = 0
replace putoption_4 = 1 if putoption>=10 & putoption<25
gen putoption_5 = 0
replace putoption_5 = 1 if putoption>=25
label var putoption_1 "Discount ($<$ -3.5\%)"
label var putoption_2 "Current ($-$3.5\%-3.49\%)"
label var putoption_3 "Cusp (3.5\%-9\%)"
label var putoption_4 "Premium (10\%-24\%)"
label var putoption_5 "Super-Premium ($>=$ 25\%)"
gen putoption_ = 1 if putoption_1 == 1
replace putoption_ = 2 if putoption_2 == 1
replace putoption_ = 3 if putoption_3 == 1
replace putoption_ = 4 if putoption_4 == 1
replace putoption_ = 5 if putoption_5 == 1
label define putoption_ 1 "Penalty ($<$ -3.5\%)"
label define putoption_ 2 "Current ($-$3.5\%-3.49\%)", add
label define putoption_ 3 "Cusp (3.5\%-9\%)", add
label define putoption_ 4 "Premium (10\%-24\%)", add
label define putoption_ 5 "Super-Premium ($>=$ 25\%)", add
label values putoption_ putoption_

recode fico (min/620=1) (620/680=2) (680/720=3) (720/max=4), gen(fico_)
label var ficoscore "FICO"
replace fico_=2 if ficoscore == 620
replace fico_=3 if ficoscore == 680
replace fico_=4 if ficoscore == 720
tab fico_, gen(fico_)
label var fico_1 "FICO ($<$ 620)"
label var fico_2 "FICO (620-679)"
label var fico_3 "FICO (680-719)"
label var fico_4 "FICO ($>=$ 720)"

recode pti (min/.31=0)(.31/max=1), gen(pti_dummy)
label var pti_dummy "Payment to income $>$ 31\%"
	
/**************
Inflate to 2009 Dollars
CPI-U-RS, all items
From Table: Annual Average Consumer Price Index Research Series (CPI-U-RS) Using Current Methods All Items: 1947-2009
From File: Income, Poverty, and Health Insurance Coverage in the United States: 2009 (P60-238, September, 2010)
**************/

replace income = income * 1.13554434 if year == 2004
replace income = income * 1.098709452 if year == 2005
replace income = income * 1.063829787 if year == 2006
replace income = income * 1.034482759 if year == 2007
		
gen income_to_msa=income/cbsa_med_fam_income*100
label var income_to_msa "Individual income to MSA median"
recode income_to_msa (0/100=1) (100/200=2) (200/max=3) (.=.), gen(inc_)
replace inc_= 2 if income_to_msa == 100
replace inc_= 3 if income_to_msa == 200
label define inc_ 1 "Income to MSA median ($<$ 100\%)"
label define inc_ 2 "Income to MSA median (100-200\%)", add
label define inc_ 3 "Income to MSA median ($>=$ 200\%)", add
label values inc_ inc_
tab inc_, gen(inc_)
label var inc_1 "Income to MSA median ($<$ 100\%)"
label var inc_2 "Income to MSA median (100-200\%)"
label var inc_3 "Income to MSA median ($>=$ 200\%)"

gen tract_to_cbsa = tract_med_fam_income/cbsa_med_fam_income*100
label var tract_to_cbsa "Tract to MSA median income"
recode tract_to_cbsa (0/80=1) (80/120=2) (120/max=3), gen(msaincome_)
label define msaincome_ 1 "Tract to MSA median income ($<$ 80\%)"
label define msaincome_ 2 "Tract to MSA median income (80-119\%)", add
label define msaincome_ 3 "Tract to MSA median income ($>=$ 120\%)", add
replace msaincome_=2 if tract_to_cbsa == 80
replace msaincome_=3 if tract_to_cbsa == 120
label values msaincome_ msaincome_
tab msaincome_, gen(msaincome_)
label var msaincome_1 "Tract to MSA median income ($<$ 80\%)"
label var msaincome_2 "Tract to MSA median income (80-119\%)"
label var msaincome_3 "Tract to MSA median income ($>=$ 120\%)"

tab year, gen(year_)
label var year_1 "2004"
label var year_2 "2005"
label var year_3 "2006"
label var year_4 "2007"

label var armind "ARM indicator"
label var purpose "Purchase (vs. refinance) indicator"
label var modind "Loan modification"

gen low_black = 1 if inc_ == 1 & black == 1
gen mid_black = 1 if inc_ == 2 & black == 1
gen high_black = 1 if inc_ == 3 & black == 1
label var low_black "Low-income \& Black"
label var mid_black "Mid-income \& Black"
label var high_black "High-income \& Black"

gen low_hisp = 1 if inc_ == 1 & hispanic == 1
gen mid_hisp = 1 if inc_ == 2 & hispanic == 1
gen high_hisp = 1 if inc_ == 3 & hispanic == 1
label var low_hisp "Low-income \& Hispanic"
label var mid_hisp "Mid-income \& Hispanic"
label var high_hisp "High-income \& Hispanic"

gen low_other = 1 if inc_ == 1 & other == 1
gen mid_other = 1 if inc_ == 2 & other == 1
gen high_other = 1 if inc_ == 3 & other == 1
label var low_other "Low-income \& Other"
label var mid_other "Mid-income \& Other"
label var high_other "High-income \& Other"

foreach i of varlist  low_black mid_black high_black low_hisp mid_hisp high_hisp low_other mid_other high_other {
replace `i' = 0 if `i' == .
}

label var per_poor "\% Poverty in tract"
label var per_nonwhite "\% Minority in tract"
