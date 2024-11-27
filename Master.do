********************************************************************************
* MASTER DO FILE
********************************************************************************
set varabbrev off 

*** Directories ***

global dir_main `c(pwd)'

global data_raw "$dir_main/Data/Raw"

global data_processed "$dir_main/Data/Processed"

global output "$dir_main/Output"

//Run the next line only the first time
* run "dir_main/Scripts/directories.do"

* EUSILC
********************************************************************************

run "$dir_main/Scripts/Cleaning/eusilc_c.do"

run "dir_main/Scripts/Analysis/eusilc_a.do"

* US - PSID 2021
********************************************************************************
run "$dir_main/Scripts/Cleaning/us_psid_c.do" 