********************************************************************************
* Create folders and directories
********************************************************************************

* Project Folders 
********************************************************************************


mkdir "$dir_main/Data/Processed"
mkdir "$dir_main/Output"


* Country/data specific
********************************************************************************


*** EUSILC ***

local countries AT BE BG CH CY CZ DE DK EE EL ES FI FR HR HU LT LU LV MT NL NO PL PT RO RS SE SI SK
foreach country of local countries {
	mkdir "$data_processed/`country'"
}

mkdir "$data_processed/eusilc"


*** US - PSID ***

mkdir "$data_processed/USA"
