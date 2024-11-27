********************************************************************************
* MASTER DO FILE
********************************************************************************
set varabbrev off 

*** Directories ***

global dir_main "C:/Users/gc24182/OneDrive - University of Bristol/Desktop/Unfair Inequality"

global data_raw "$dir_main/Data/Raw"

global data_processed "$dir_main/Data/Processed"

global output "$dir_main/Output"

global dir_scripts "C:/Users/gc24182/OneDrive - University of Bristol/Documents/GitHub/UI-harmonisation/Scripts"

//Run the next line only the first time
* run "dir_scripts/directories.do"

* EUSILC
********************************************************************************

run "$dir_scripts/Cleaning/eusilc_c.do"

run "dir_scripts/Analysis/eusilc_a.do"

* US - PSID 2021
********************************************************************************
run "$dir_scripts/Cleaning/us_psid_c.do" 