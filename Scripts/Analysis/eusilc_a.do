********************************************************************************
* Descriptive statistics - EUSILC
********************************************************************************
use "$data_processed/eusilc/cleaned.dta"

*** Number of observations and missing data ***
gen data_missing = 0
replace data_missing = 1 if income_tot == . | hours_work == . | educ_highest == . | educ_parents == .  // Age and sex are not missing

bysort country: egen data_missing_p = total(data_missing == 1)
replace data_missing_p = (data_missing_p/totalpop)*100

bysort country: egen data_complete = total(data_missing == 0)

tabstat data_missing_p data_complete, by(country)


*** Income ***
tabstat income_tot, by (country) stat(mean, sd, p25, p50, p75 n) col(stat) long

*** Hours of work ***
tabstat hours_work, by (country) stat(mean, sd, p25, p50, p75 n) col(stat) long

*** Education ***
tab country educ_highest, m row nofreq

*** Parents's education ***
tab country educ_highest, m row nofreq