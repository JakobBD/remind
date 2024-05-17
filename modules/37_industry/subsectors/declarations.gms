*** |  (C) 2006-2023 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/37_industry/subsectors/declarations.gms

Scalar
  s37_clinker_process_CO2   "CO2 emissions per unit of clinker production"
  s37_plasticsShare         "share of carbon cointained in feedstocks for the chemicals subsector that goes to plastics"
;

Parameters
  pm_energy_limit(all_in)                                                      "thermodynamic/technical limits of subsector energy use [GJ/t product]"
  p37_energy_limit_slope(tall,all_regi,all_in)                                 "limit for subsector specific energy demand that converges towards the thermodynamic/technical limit [GJ/t product]"
  p37_clinker_cement_ratio(ttot,all_regi)                                      "clinker content per unit cement used"
  pm_ue_eff_target(all_in)                                                     "energy efficiency target trajectories [% p.a.]"
  pm_IndstCO2Captured(ttot,all_regi,all_enty,all_enty,secInd37,all_emiMkt)     "Captured CO2 in industry by energy carrier, subsector and emissions market [GtC/a]"
  p37_CESMkup(ttot,all_regi,all_in)                                            "parameter for those CES markup cost accounted as investment cost in the budget [trUSD/CES input]"
  p37_cesIO_up_steel_secondary(tall,all_regi,all_GDPscen)                      "upper limit to secondary steel production based on scrap availability"
  p37_steel_secondary_max_share(tall,all_regi)                                 "maximum share of secondary steel production"
  p37_BAU_industry_ETS_solids(tall,all_regi)                                   "industry solids demand in baseline scenario"
  p37_cesIO_baseline(tall,all_regi,all_in)                                     "vm_cesIO from the baseline scenario"

  p37_captureRate(all_te)                                                      "Capture rate of CCS technology"

  p37_chemicals_feedstock_share(ttot,all_regi)               "minimum share of feso/feli/fega in total chemicals FE input [0-1]"
  p37_FeedstockCarbonContent(ttot,all_regi,all_enty)         "carbon content of feedstocks [GtC/TWa]"
  p37_FE_noNonEn(ttot,all_regi,all_enty,all_enty2,emiMkt)    "testing parameter for FE without non-energy use"
  p37_Emi_ChemProcess(ttot,all_regi,all_enty,emiMkt)         "testing parameter for process emissions from chemical feedstocks"
  p37_CarbonFeed_CDR(ttot,all_regi,all_emiMkt)               "testing parameter for carbon in feedstocks from biogenic and synthetic sources"
  p37_IndFeBal_FeedStock_LH(ttot,all_regi,all_enty,emiMkt)   "testing parameter Ind FE Balance left-hand side feedstock term"
  p37_IndFeBal_FeedStock_RH(ttot,all_regi,all_enty,emiMkt)   "testing parameter Ind FE Balance right-hand side feedstock term"
  p37_EmiEnDemand_NonEnCorr(ttot,all_regi)                   "energy demand co2 emissions with non-energy correction"
  p37_EmiEnDemand(ttot,all_regi)                             "energy demand co2 emissions without non-energy correction"

*** output parameters only for reporting
  o37_cementProcessEmissions(ttot,all_regi,all_enty)                     "cement process emissions [GtC/a]"
  o37_demFeIndSub(ttot,all_regi,all_enty,all_enty,secInd37,all_emiMkt)   "FE demand per industry subsector"

  p37_CESMkup_input(all_in)  "markup cost parameter read in from config for CES levels in industry to influence demand-side cost and efficiencies in CES tree [trUSD/CES input]"
  /
$ifthen.CESMkup "%cm_CESMkup_ind%" == "manual"
    %cm_CESMkup_ind_data%
$endif.CESMkup
  /

$ifthen.sec_steel_scen NOT "%cm_steel_secondary_max_share_scenario%" == "off"   !! cm_steel_secondary_max_share_scenario
  p37_steel_secondary_max_share_scenario(tall,all_regi)   "scenario limits on share of secondary steel production"
  / %cm_steel_secondary_max_share_scenario% /
$endif.sec_steel_scen

  p37_regionalWasteIncinerationCCSshare(ttot,all_regi)    "regional proportion of waste incineration that is captured [%]"
$ifthen.cm_wasteIncinerationCCSshare not "%cm_wasteIncinerationCCSshare%" == "off"
  p37_wasteIncinerationCCSshare(ttot,ext_regi)            "switch values for proportion of waste incineration that is captured [%]"
  / %cm_wasteIncinerationCCSshare% /
$endIf.cm_wasteIncinerationCCSshare
;

Positive Variables
  vm_emiIndBase(ttot,all_regi,all_enty,secInd37)                            "industry CCS baseline emissions [GtC/a]; Not used for emission accounting outside CCS"
  vm_emiIndCCS(ttot,all_regi,all_enty)                                      "industry CCS emissions [GtC/a]"
  v37_FeedstocksCarbon(ttot,all_regi,all_enty,all_enty,all_emiMkt)          "Carbon flow: carbon contained in chemical feedstocks [GtC]"
  v37_plasticsCarbon(ttot,all_regi,all_enty,all_enty,all_emiMkt)            "Carbon flow: carbon contained in plastics [GtC]"
  v37_plasticWaste(ttot,all_regi,all_enty,all_enty,all_emiMkt)              "Carbon flow: carbon contained in plastic waste [GtC]"
  v37_demFeIndst(ttot,all_regi,all_enty,all_enty,all_in,all_emiMkt)         "FE demand of industry sector by SE origin, industry subsector, and emission market. [TWa]"
  !! process-based implementation
  vm_captureVol(tall,all_regi,all_te)                               "Production volume of processes in process-based model [Gt/a]"
;

Equations
$ifthen.no_calibration "%CES_parameters%" == "load"   !! CES_parameters
  q37_energy_limits(ttot,all_regi,all_in)                                           "thermodynamic/technical limit of energy use"
$endif.no_calibration
  q37_limit_secondary_steel_share(ttot,all_regi)                                    "no more than 90% of steel from seconday production"
  q37_emiIndBase(ttot,all_regi,all_enty,secInd37)                                   "gross industry emissions before CCS"
  q37_cementCCS(ttot,all_regi)                                                      "link cement fuel and process abatement"
  q37_demFeIndst(ttot,all_regi,all_enty,all_enty,all_emiMkt)                        "industry final energy demand (per emission market)"
  q37_demFeIndst_intermediate(ttot,all_regi,all_enty,all_in,secInd37,all_emiMkt)    "industry final energy demand (per emission market)"
  q37_costCESmarkup(ttot,all_regi,all_in)                                           "calculation of additional CES markup cost to represent demand-side technology cost of end-use transformation, for example, cost of heat pumps etc."
  q37_chemicals_feedstocks_limit(ttot,all_regi)                                     "lower bound on feso/feli/fega in chemicals FE input for feedstocks"
  q37_demFeFeedstockChemIndst(ttot,all_regi,all_enty,all_emiMkt)                    "defines energy flow of non-energy feedstocks for the chemicals industry. It is used for emissions accounting"
  q37_FossilFeedstock_Base(ttot,all_regi,all_enty,all_emiMkt)                       "in baseline runs feedstocks only come from fossil energy carriers"
  q37_FeedstocksCarbon(ttot,all_regi,all_enty,all_enty,all_emiMkt)                  "calculate carbon contained in feedstocks [GtC]"
  q37_plasticsCarbon(ttot,all_regi,all_enty,all_enty,all_emiMkt)                    "calculate carbon contained in plastics [GtC]"
  q37_plasticWaste(ttot,all_regi,all_enty,all_enty,all_emiMkt)                      "calculate carbon contained in plastic waste [GtC]"
  q37_incinerationEmi(ttot,all_regi,all_enty,all_enty,all_emiMkt)                   "calculate carbon contained in plastics that are incinerated [GtC]"
  q37_nonIncineratedPlastics(ttot,all_regi,all_enty,all_enty,all_emiMkt)            "calculate carbon contained in plastics that are not incinerated [GtC]"
  q37_feedstockEmiUnknownFate(ttot,all_regi,all_enty,all_enty,all_emiMkt)           "calculate carbon contained in chemical feedstock with unknown fate [GtC]"
  q37_feedstocksLimit(ttot,all_regi,all_enty,all_enty,all_in,all_emiMkt)            "restrict feedstocks flow to total energy flows into industry"

  !! process-based carbon capture
  q37_limitCapCC(tall,all_regi,all_te)                                              "carbon capture volume is limited by capacities"
  q37_emiIndCC(tall,all_regi,secInd37)                                              "Captured emissions from CCS"
  q37_limitOutflowCC(tall,all_regi,secInd37)                                        "Carbon capture processes can only capture as much co2 as the base process emits"
;

*** EOF ./modules/37_industry/subsectors/declarations.gms
