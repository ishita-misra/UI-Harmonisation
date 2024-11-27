/*******************************************************************************
United States - 2021

The do file cleans and analyses data from the PSID 2021 survey. The family file 
is used for age, sex, education, income, working hours, and parents' education.

*******************************************************************************/


********************************************************************************
* Directories
********************************************************************************

cd "$data_processed/USA"

********************************************************************************
* Loading PSID 2021 family file
******************************************************************************** 

clear
run "$data_raw/USA/FAM2021ER.do"
save us_psid21.dta, replace

********************************************************************************
* Renaming and reshaping
********************************************************************************
use us_psid21, clear

// The dataset is in wide format and relevant information is only there for 
// reference person and spouse/partner. Renaming is such that RP is 1 and SP is 2.

rename ER78002 hhid




reshape long age sex income hours_work educ_highest educ_parents, i(hhid) j(pid)


********************************************************************************
* Cleaning and labelling values
********************************************************************************

* Age 
************************************
rename ER78017 age1
rename ER78019 age2

preserve 
keep hhid age1 age2 sex1 sex2
reshape long age sex , i(hhid) j(pid)
keep if age >= 25 & age <= 60
tab sex, m
restore

codebook age1  // 999 used for NA/Don't know
keep if age >= 25 & age <= 60



* Sex
************************************
rename ER78018 sex1
rename ER78020 sex2

tab sex, m
drop if sex == 0 | sex == .






