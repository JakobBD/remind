*** |  (C) 2006-2024 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/37_industry/module.gms

*' @title Industry
*'
*' @description This module models final energy use in the industry sector and 
*' its subsectors, as well as the emissions generated by them.
*'
*' @authors Michaja Pehl


*###################### R SECTION START (MODULETYPES) ##########################
$Ifi "%industry%" == "fixed_shares" $include "./modules/37_industry/fixed_shares/realization.gms"
$Ifi "%industry%" == "subsectors" $include "./modules/37_industry/subsectors/realization.gms"
*###################### R SECTION END (MODULETYPES) ############################
*** EOF ./modules/37_industry/module.gms

