/*******************************************************************************
EU-SILC 2019 Datasets

The do file appends 28 EU-SILC 2019 datasets from different countries and cleans
the data. Countries included: Austria, Belgium, Bulgaria, Switzerland, Czech Republic, 
Croatia, Germany, Denmark, Estonia, Greece, Spain, Finland, France, Hungary, Cyprus,
Latvia, Luxembourg, Lithuania, Malta, Netherlands, Norway, Poland, Portugal, Romania, 
Serbia, Sweden, Slovenia, Slovakia
 
*******************************************************************************/

clear

********************************************************************************
* Directories
********************************************************************************

cd "$data_processed"


********************************************************************************
* Appending datatsets
* Variable names are harmonised across all countries by data provider
********************************************************************************

// The following loop merges personal and household datasets for each country and then appends it to a master dataset
tempfile eusilc
save `eusilc', emptyok replace

local countries AT BE BG CH CY CZ DE DK EE EL ES FI FR HR HU LT LU LV MT NL NO PL PT RO RS SE SI SK

foreach country of local countries {
	
	import delimited using "$data_raw/`country'/2019/UDB_c`country'19P.csv", delimiter(",") case(lower) clear
	
	keep pb020 pb010 pb030 px030 	/// identification variables
	pb140* px020* 	/// age
	pb150* 	/// gender 
	pe010* pe020* pe040* 	/// education
	py030g* py010g* py200g* py020g* py050g* py* 	/// income
	pl031* pl051* px050* pl040* pl060* pl100* pl073* pl074* pl075* pl076* pl111*	/// work
	pt* 	// parent's characteristics
	
	save "$data_processed/`country'/UDB_c`country'19P.dta", replace
	
	import delimited using "$data_raw/`country'/2019/UDB_c`country'19H.csv", delimiter(",") case(lower) clear
	keep hb020 hb030 	/// identification
	hy170g* hy010* hy* 	// Value of goods produced for own consumption/sources of income
	rename (hb020 hb030)(pb020 px030)	// To merge with individual-level data
	
	qui merge 1:m pb020 px030 using "$data_processed/`country'/UDB_c`country'19P.dta"
	
	save "$data_processed/`country'/UDB_`country'19.dta", replace
	
	qui append using `eusilc'
	save `eusilc', replace
}

use `eusilc', clear
save "$data_processed/eusilc/appended.dta", replace

tab pb020 // All 28 countries appended with 477,739 observations

********************************************************************************
* Renaming and labelling
********************************************************************************
use "$data_processed/eusilc/appended.dta", clear

rename (pb010 pb020 pb030 px030)(year country pid hhid)
rename (pb140 px020)(birth_year age)
rename pb150 sex
rename (pe010 pe020 pe040)(educ_status educ_current educ_highest)
rename (py010g py020g py030g py050g hy170g) (income_empl_cash income_empl_other income_empl_contribution income_self_cash income_self_goods)
rename (pl031 pl051 px050 pl040 pl060 pl100 pl073 pl074 pl075 pl076 pl111) ///
(empl_status occupation empl_status2 empl_status3 hours_main hours_others months_emlp_full months_empl_part months_self_full months_self_part occ_nace)
rename (pt110 pt110_f pt120 pt120_f)(educ_father educ_father_response educ_mother educ_mother_response)

label var year "Year of survey"
label var country "Country"
label var pid "Personal ID"
label var hhid "Household ID"
label var birth_year "Birth year"
label var age "Age"
label var sex "Sex"
label var educ_status "Current education status"
label var educ_current "Education level currently attending"
label var educ_highest "Highest education level attained"
label var income_empl_cash "Employee cash income (gross)"
label var income_empl_other "Employee non-cash income (gross)"
label var income_empl_contribution "Employer contribution to social insurance"
label var income_self_cash "Self-employment income"
label var income_self_goods "Value of goods produced for own consumption"
label var empl_status "Economic status (self-defined)"
label var occupation "Occupation"
label var empl_status2 "Activity status (defined by Eurostat)"
label var empl_status3 "Status of main job"
label var hours_main "Numbers of hours worked in main job"
label var hours_others "Numbers of hours worked other jobs"
label var months_emlp_full "Months spent as full-time employee"
label var months_empl_part "Months spent as part-time employee"
label var months_self_full "Months spent as full-time self-employed"
label var months_self_part "Months spent as part-time self-employed"
label var occ_nace "NACE classification of occupation"
label var educ_father "Highest education level attained by father"
label var educ_mother "Highest education level attained by mother"
label var educ_father_response "Type of response for father's education"
label var educ_mother_response "Type of response for mother's education"


********************************************************************************
* Cleaning and labelling values
********************************************************************************

* Age 
************************************

sum age // 13-81 
keep if age >= 25 & age <= 60 // Restrict sample to working-age population. 255,745 observations

* Sex 
************************************

label define sex_lab 1 "Male" 2 "Female"
label values sex sex_lab
tab sex, m //No missing values


* Income 
************************************

*** Employee Status ***

tab empl_status, m
label define empl_lab1 1 "Employee full-time" 2 "Employee part-time" 3 "Self-employed full-time" 4 "Self-employed part-time" 5 "Unemployed" 6 "Student/Unpaid work experience" 7 "Retired" 8 "Disabled/unfit to work" 9 "Compulsory military service" 10 "Domestic tasks and care" 11 "Other inactive"
label values empl_status empl_lab1

tab empl_status2, m
label define empl_lab2 2 "Employed(SAL)" 3 "Employed(NSAL)" 4 "Employed(Other)" 5 "Unemployed" 6 "Retired" 7 "Inactive" 8 "Other inactive"
label values empl_status2 empl_lab2

tab empl_status empl_status2, m	// Self-defined and Eurostat defined status
count if empl_status < 5 & empl_status2 >= 5 & empl_status != . & empl_status2 != .
// 5,723 self-identify as employed but not as per Eurostat definition 


*** Income from employment ***

sum income_empl_cash // 2 negative values from NL. Both self-employed so likely income given to employees

/* CHECK
sort country
by country: sum income_empl_cash
// Av incomes range 4,800 to 61,000.
// Av income < 10,000 : Bulgaria, Greece, Croatia, Hungary, Lithuania, Latvia, Poland, Romania, Serbia, Slovakia
*/ 

*** Employee cash + non-cash income

sum income_empl_other // 3 negative values from NL.

/* CHECK
sort country
by country: sum income_empl_other
// Av non-cash income range 3 to 866 (Not recorded for Austria and Switzerland).
*/

replace income_empl_other = 0 if income_empl_other == . & income_empl_cash != . // Only 4 missing observations excluding AT and CH
count if income_empl_cash == . & income_empl_other != . // 0

gen income_empl = income_empl_cash + income_empl_other
label var income_empl "Employee income as cash and non-cash"
	

*** Income from self-employment ***

sum income_self_cash
	// 915 negative values
sum income_self_goods
	// Missing for Austria, Switzerland and Malta. 44,007 non-0 values
	
count if income_self_goods == . & country != "AT" & country != "CH" & country != "MT" // 44
replace income_self_goods = 0 if income_self_goods == . & income_self_cash != .
count if income_self_cash == . & income_self_goods != . //10. All in Norway with value 0. Employee income is also 0

gen income_self = income_self_cash + income_self_goods 
sum income_self 
count if income_self < 0 // 966 negative values
label var income_self "Income from self-employment as cash and goods consumed"


*** Total labour income ***

gen income_cash = income_empl_cash + income_self_cash
label var income_cash "Income from self-employmnet and outside employment (Cash)"
su income_cash 
count if income_cash < 0 // 284 negative values

gen income_tot = income_empl + income_self 
sum income_tot 
count if income_tot < 0 // 268 negative values
label var income_tot "Income from self-employment and outside employment"
// All negative values driven by self-employed income
// Self-employed income 0 for those with 0 total income 

sort country
by country: sum income_tot

*** 0 income ***
count if income_tot == 0  // 32,698
tab empl_status if income_tot == 0 // 7.5% identify as employed
tab hours_main if income_tot == 0 // Missing for 93%
tab occupation if income_tot == 0 & empl_status < 5 // Various occupations
tab hy040g if income_tot == 0 & empl_status < 5 // 10% get rental income
tab hy080g if income_tot == 0 & empl_status < 5 // 10% get interhousehold transfers
tab hy081g if income_tot == 0 & empl_status < 5 // 5.5% get alimonies
tab hy090g if income_tot == 0 & empl_status < 5 // 30% get interest/dividends/profits from businesses
tab hy090g if income_tot == 0 & empl_status < 5 // 40% get family/children-related allowances
tab py090g if income_tot == 0 & empl_status < 5 // 15% get unemployment 

tab empl_status empl_status2 if income_tot == 0 
count if income_tot == 0 & empl_status >= 5 & empl_status2 >= 5 & empl_status != . & empl_status2 != . // 29,320

replace income_tot = . if income_tot == 0 & hours_main == .
replace income_tot = . if income_tot == 0 & empl_status >= 5 & empl_status2 >= 5 & empl_status != . & empl_status2 != .
// Self-identify and eurostat status of unemployed/not in labour force

count if income_tot == 0 & empl_status2 >= 5 & empl_status2 != .   // 1,168
tab hours_main if income_tot == 0 & empl_status2 >= 5 & empl_status2 != . // Various hours

egen income_quint = xtile (income_tot), n(5) by(country)
egen income_dec = xtile (income_tot), n(10) by(country)

encode occ_nace, gen (occ_nace_nu)
label define nace_lab 1 "Agriculture, forestry & fishing" 2 "Mining, manufacturing, electricity, gas & water supply" 3 "Construction" 4 "Wholesale&retail" 5 "Transport, storage" 6 "Accomodation&food service" 7 "Info & Communication" 8 "Finance & Insurance" 9 "Real estate, professional, scientific & admin" 10 "Public admin, defense, social security" 11 "Education" 12 "Human health & social work" 13 "Arts, service activities, household activities"
label values occ_nace_nu nace_lab 


* Education
************************************

*** Current education status ***

label define educ_lab1 1 "In education" 2 "Not in education"
label values educ_status educ_lab1
tab educ_status, m // 3.3% in education

*** Level of education currently attending ***
*Categories: Lower sec, upper sec, post-secondary non-tertiary, tertiary

replace educ_current = 20 if educ_current <= 20
replace educ_current = 30 if educ_current < 40 & educ_current >= 30
replace educ_current = 40 if educ_current < 50 & educ_current >= 40
replace educ_current = 50 if educ_current >= 50 & educ_current <= 80

label define educ_lab2 20 "Lower secondary" 30 "Upper secondary" 40 "Post-secondary non-tertiary" 50 "Tertiary"
label values educ_current educ_lab2

*** Highest level of education attained ***
*Categories: Less than pimary, Primary, lower sec, upper sec, post-sec non-tertiary, tertiary

replace educ_highest = 100 if educ_highest == 0
replace educ_highest = 300 if educ_highest < 400 & educ_highest >= 300
replace educ_highest = 400 if educ_highest < 500 & educ_highest >= 400
replace educ_highest = 500 if educ_highest <= 800 & educ_highest >= 500 

label define educ_lab3 100 "Primary or less" 200 "Lower secondary" 300 "Upper secondary" 400 "Post-secondary non-tertiary" 500 "Tertiary"
label values educ_highest educ_lab3

tab educ_highest, m // 5,426 missing
tab educ_highest if income_tot != ., m // 4,616 missing

tab educ_current if educ_highest == ., m  // 45 have information on current education
replace educ_highest = 100 if educ_current == 20 & educ_highest == .
replace educ_highest = 200 if educ_current == 30 & educ_highest == .
replace educ_highest = 300 if educ_current == 40 & educ_highest == .
replace educ_highest = 300 if educ_current == 50 & educ_highest == .

tab country if educ_highest == . & income_tot != . 
bysort country: egen totalpop = total(sex != .)   // Sex not missing for any observation
bysort country: egen educ_missing = total(educ_highest == .) 
gen educ_missing_p = (educ_missing/totalpop)*100 
bysort country: sum educ_missing_p  // LV-4.6%; NL-4.1%; PL-15.7%; 

/* CHECK - Missing educ after removing observations that don't have info on income
preserve
drop if income_tot == .
bysort country: egen totalpop_i = total(sex != .) 
bysort country: egen educ_missing_i = total(educ_highest == .) 
gen educ_missing_p_i = (educ_missing_i/totalpop_i)*100 
bysort country: sum educ_missing_p_i  // LV-4.3%; NL-3.7%; PL-16.1%; 
restore
*/



/* CHECK - Missing in each quintile

tab educ_highest income_quint if country == "LV", m col 
	// Missings as % of quintile: 6.5, 4.5, 3.3, 4.6, 2.3
	
tab educ_highest income_quint if country == "NL", m col 
	// Missings as % of quintile: 5.1, 3.8, 4.3, 3.4, 2.3
	
tab educ_highest income_quint if country == "PL", m col 
	// Missings as % of quintile: 15.7, 17.7, 16.7, 15.1, 15.5
	
tab educ_highest if country == "NL" & age < 31 & income_quint == 1, m
// 38% and 46% at upper-sec and tertiary.
tab occ_nace_nu if educ_highest == . & country == "NL" & income_quint == 1, m // 93% missing
tab educ_highest if occ_nace_nu == . & country == "NL"   // 39% and 39% at upper-sec and tertiary
*/



* Working hours 
************************************

su hours_main hours_others
codebook hours_main hours_others // hours_others missing for 95% of observations

count if hours_main == . // 69,382 missing.
count if hours_main == . & (empl_status >= 5 | empl_status2 >= 5) // 61,876
count if hours_main == . & income_tot != . & educ_highest != . // 28,951 missing

replace hours_others = 0 if pl100_f == -2  // Working but does not have second job. Now only 0.32% missing
count if hours_main != . & hours_others == . // 555. 306 from NL

gen hours_work = hours_main + hours_others
replace hours_work = hours_main if hours_others == .
label var hours_work "Total hours worked in a week"

su hours_work // Highest value is 128 
count if hours_work > 80 & hours_work != . // 366
replace hours_work = . if hours_work > 80

preserve 
drop if income_tot == .
tab empl_status if hours_work == .
tab empl_status2 if hours_work == .
count if income_tot > 0 & hours_work == . & empl_status == 5
count if income_tot > 0 & hours_work == . & empl_status2 == 5
restore

replace hours_work = 0 if hours_work == . & empl_status >= 5 & empl_status != . // Data not collected if empl_status >= 5


/* CHECK - Missing observations in each country
preserve 
drop if income_tot == .
drop if empl_status >= 5
bysort country: egen totalpop_i = total(sex != .)
bysort country: egen hours_missing_i = total (hours_work == .)
replace hours_missing_i = (hours_missing_i/totalpop_i)*100
bysort country: sum hours_missing_i
// HU-7.8%; LU: 3.9%; RO-4%
restore 
*/

/* CHECK - Missing in each quintile
gen hours_missing = 0
replace hours_missing = 1 if hours_work == .

tab hours_missing income_quint if country == "HU", m col 
	// Missings as % of quintile: 4.6, 6.5, 5.7, 6.9, 10
	
tab hours_missing income_quint if country == "LU", m col 
	// Missings as % of quintile: 5.2, 2.3, 2.7, 3.3, 3, 2.1
	
tab hours_missing income_quint if country == "RO", m col 
	// Missings as % of quintile: 3.8, 8, 1.5, 1, 1.5, 0
	
*/

preserve 
keep if country == "LU"
bysort educ_highest: sum hours_work if income_quint == 1 // SD ~17 at every level of education
bysort educ_highest: sum hours_work if income_quint == 1 & age < 31 // Too few observations
restore



* Parent's education 
************************************

*Categories: Low (primary/Lower sec), Middle (Upper sec/non-tertiary), High(tertiary)

tab educ_mother, m // 24% missing or dont know
tab educ_father, m // 29% missing or dont know

tab educ_mother if income_tot != . & hours_work != . & educ_highest != ., m // 22% missing or dont know
tab educ_father if income_tot != . & hours_work != . & educ_highest != ., m // 26% missing or dont know

* Replacing missing/unkown based on reason why value is missing/unkown
replace educ_father = 1 if educ_father_response == -5 | educ_father_response == -2 // Father not present or lived in collective household/institution
replace educ_mother = 1 if educ_mother_response == -5 | educ_mother_response == -2 // Mother not present or lived in collective household/institution

gen educ_parents = educ_father
replace educ_parents = educ_mother if educ_mother > educ_father & educ_mother != . & educ_father != .
replace educ_parents = educ_mother if educ_father == . & educ_mother != .
replace educ_parents = . if educ_parents == -1
label var educ_parents "Highest level of education achieved by either parent"

tab educ_parents, m // About 21% of sample missing/dont know
tab educ_parents educ_father_response, m row // 53% of missings due to sample selection method in DK, FI, HU, NL, NO, SE, SI


/* CHECK - Missing in each quintile

tab educ_parents income_quint, m col nofreq

gen educ_parents_missing = 0
replace educ_parents_missing = 1 if educ_parents == . 

local countries AT BE BG CH CY CZ DE EE EL ES FR HR LT LU LV MT PL PT RO RS SK
foreach country of local countries {
	di "Country: `country'"
	tab educ_parents_missing income_quint if country == "`country'", m col
}

*/

* Correlation of parents' education within household - Not high (0.25-0.65)
preserve 
keep country pid hhid educ_parents
gen byte pid2 = mod(pid, 100) // 1-2 didgit pid for reshaping
duplicates report country hhid pid2 // 42 duplicates 
duplicates tag country hhid pid2, gen(pid_flag)
drop if pid_flag == 1
drop pid pid_flag
reshape wide educ_parents, i(country hhid) j(pid2)
local countries AT BE BG CH CY CZ DE EE EL ES FR HR LT LU LV MT PL PT RO RS SK
foreach country of local countries {
	di "Country: `country' "
	corr educ_parents1 educ_parents2 if country == "`country'"
// Parents' education not correlated within the household 
}
restore

tab pt190 educ_father if income_quint == 1 & country == "DE", m col // Financial status when growing up
tab educ_highest educ_father if income_quint == 1 & country == "DE", m col
tab pt150 educ_father if income_quint == 1 & country == "DE", m col // Father's occupation

save "$data_processed/eusilc/cleaned.dta", replace



