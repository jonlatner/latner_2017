import excel `"$support_files/Zip_Zhvi_AllHomes.xls"', sheet("Zip_Zhvi_AllHomes") firstrow clear

reshape long d_ ,i(RegionName City State Metro CountyName) j(test)

rename test date
rename d_ mean_value

gen test = RegionName
gen test2 = 0
tostring test test2, replace
egen test3 = concat(test2 test) if RegionName<10000
replace test3 = test if RegionName>=10000 

rename test3 zip
drop test*

format date %tm

save `"$support_files/zillow.dta"', replace
