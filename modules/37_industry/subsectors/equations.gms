*** |  (C) 2006-2023 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/37_industry/subsectors/equations.gms

*** ---------------------------------------------------------------------------
***        1. CES-Based (mostly)
*** ---------------------------------------------------------------------------

***------------------------------------------------------
*' Industry final energy balance
***------------------------------------------------------
q37_demFeIndst(t,regi,entyFe,emiMkt)$( entyFe2Sector(entyFe,"indst") ) ..
  sum(se2fe(entySe,entyFe,te),
    vm_demFeSector_afterTax(t,regi,entySe,entyFe,"indst",emiMkt)
  )
  =e=
  sum(fe2ppfEn(entyFe,ppfen_industry_dyn37(in)),
    sum((secInd37_emiMkt(secInd37,emiMkt),secInd37_2_pf(secInd37,in)),
      (
          vm_cesIO(t,regi,in)
        + pm_cesdata(t,regi,in,"offset_quantity")
      )
    )
  )
;

***------------------------------------------------------
*' Thermodynamic limits on subsector energy demand
***------------------------------------------------------
$ifthen.no_calibration "%CES_parameters%" == "load"   !! CES_parameters
q37_energy_limits(t,regi,industry_ue_calibration_target_dyn37(out))$(
                                        t.val gt 2020
                                    AND p37_energy_limit_slope(t,regi,out) ) ..
  sum(ces_eff_target_dyn37(out,in), vm_cesIO(t,regi,in))
  =g=
    vm_cesIO(t,regi,out)
  * p37_energy_limit_slope(t,regi,out)
;
$endif.no_calibration

***------------------------------------------------------
*' Limit the share of secondary steel to historic values, fading to 90 % in 2050
***------------------------------------------------------
q37_limit_secondary_steel_share(t,regi)$(
         YES
$ifthen.fixed_production "%cm_import_EU%" == "bal"   !! cm_import_EU
         !! do not limit steel production shares for fixed production
     AND p37_industry_quantity_targets(t,regi,"ue_steel_secondary") eq 0
$endif.fixed_production
$ifthen.exogDem_scen NOT "%cm_exogDem_scen%" == "off"
         !! do not limit steel production shares for fixed production
     AND pm_exogDemScen(t,regi,"%cm_exogDem_scen%","ue_steel_secondary") eq 0
$endif.exogDem_scen
                                                                            ) ..
  vm_cesIO(t,regi,"ue_steel_secondary")
  =l=
    ( vm_cesIO(t,regi,"ue_steel_primary")
    + vm_cesIO(t,regi,"ue_steel_secondary")
    )
  * p37_steel_secondary_max_share(t,regi)
;

***------------------------------------------------------
*' Compute gross local industry emissions before CCS by multiplying sub-sector energy
*' use with fuel-specific emission factors. (Local means from a hypothetical purely fossil
*' energy mix, as that is what can be captured); vm_emiIndBase itself is not used for emission
*' accounting, just as a CCS baseline.
***------------------------------------------------------
q37_emiIndBase(t,regi,enty,secInd37) ..
    vm_emiIndBase(t,regi,enty,secInd37)
  =e=
    sum((secInd37_2_pf(secInd37,ppfen_industry_dyn37(in)),fe2ppfEn(entyFeCC37(enty),in)),
      ( vm_cesIO(t,regi,in)
      - ( p37_chemicals_feedstock_share(t,regi)
        * vm_cesIO(t,regi,in)
	)$( in_chemicals_feedstock_37(in) )
      )
        *
        sum(se2fe(entySeFos,enty,te),
            pm_emifac(t,regi,entySeFos,enty,te,"co2")
        )
    ) !!$(entyFe(enty)) condition should be fulfilled by summation over entyFeCC37 above
    +
    (s37_clinker_process_CO2
    * p37_clinker_cement_ratio(t,regi)
    * vm_cesIO(t,regi,"ue_cement")
    / sm_c_2_co2)$(sameas(enty,"co2cement_process") AND sameas(secInd37,"cement"))
;


***------------------------------------------------------
*' Fix cement fuel and cement process emissions to the same abatement level.
***------------------------------------------------------
q37_cementCCS(t,regi)$(cm_CCS_cement eq 1 AND cm_IndCCSscen eq 1) ..
    vm_emiIndCCS(t,regi,"co2cement")
  * vm_emiIndBase(t,regi,"co2cement_process","cement")
  =e=
    vm_emiIndCCS(t,regi,"co2cement_process")
  * sum(entyFeCC37(entyFe),
      vm_emiIndBase(t,regi,entyFe,"cement")
    )
;

***------------------------------------------------------
*' Definition of capacity constraints
***------------------------------------------------------
q37_limitCapCC(t,regi,teCCInd) ..
      vm_captureVol(t,regi,teCCInd)
    =l=
    sum(teCCInd2rlf(teCCInd,rlf),
      vm_capFac(t,regi,teCCInd)
    * vm_cap(t,regi,teCCInd,rlf)
    )
;

***------------------------------------------------------
*' Carbon capture processes can only capture as much co2 as the base process emits
***------------------------------------------------------
q37_limitOutflowCC(t,regi,secInd37) ..
    sum(emiInd37_fe2sec(enty,secInd37),
      vm_emiIndBase(t,regi,enty,secInd37)
      )
  =g=
    sum(secInd37_teCCInd(secInd37,teCCInd),
      1. / p37_captureRate(teCCInd)
      *
      vm_captureVol(t,regi,teCCInd)
    )
;

***------------------------------------------------------
*' Emission captured from process based industry sector
***------------------------------------------------------
q37_emiIndCC(t,regi,secInd37) ..
    sum(secInd37_2_emiInd37(secInd37,emiInd37),
      vm_emiIndCCS(t,regi,emiInd37))
  =e=
    sum(secInd37_teCCInd(secInd37,teCCInd),
      vm_captureVol(t,regi,teCCInd)
    )
;

***------------------------------------------------------
*'  CES markup cost that are accounted in the budget (GDP) to represent sector-specific demand-side transformation cost in industry
***------------------------------------------------------
q37_costCESmarkup(t,regi,in)$(ppfen_industry_dyn37(in))..
  vm_costCESMkup(t,regi,in)
  =e=
    p37_CESMkup(t,regi,in)
  * (vm_cesIO(t,regi,in) + pm_cesdata(t,regi,in,"offset_quantity"))
;

***--------------------------------------------------------------------------
*'  Feedstock balances
***--------------------------------------------------------------------------

*' Lower bound on feso/feli/fega in chemicals FE input for feedstocks
q37_chemicals_feedstocks_limit(t,regi) ..
  sum(in_chemicals_feedstock_37(in), vm_cesIO(t,regi,in))
  =g=
    sum(ces_eff_target_dyn37("ue_chemicals",in), vm_cesIO(t,regi,in))
  * p37_chemicals_feedstock_share(t,regi)
;

*' Define the flow of non-energy feedstocks. It is used for emissions accounting and calculating plastics production
q37_demFeFeedstockChemIndst(t,regi,entyFe,emiMkt)$(
                         entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt) ) ..
  sum(se2fe(entySe,entyFe,te),
    vm_demFENonEnergySector(t,regi,entySe,entyFe,"indst",emiMkt)
  )
  =e=
  sum((fe2ppfEn(entyFe,ppfen_industry_dyn37(in)),
       secInd37_emiMkt(secInd37,emiMkt),
       secInd37_2_pf(secInd37,in_chemicals_feedstock_37(in))),
    ( vm_cesIO(t,regi,in)
    + pm_cesdata(t,regi,in,"offset_quantity")
    )
  * p37_chemicals_feedstock_share(t,regi)
  )
;

*' Feedstocks flow has to be lower than total energy flow into the industry
q37_feedstocksLimit(t,regi,entySe,entyFe,emiMkt)$(
                                             sefe(entySe,entyFe)
                                         AND sector2emiMkt("indst",emiMkt)
                                         AND entyFe2Sector(entyFe,"indst")
                                         AND entyFeCC37(entyFe)            ) ..
  vm_demFeSector(t,regi,entySe,entyFe,"indst",emiMkt)
  =g=
  vm_demFENonEnergySector(t,regi,entySe,entyFe,"indst",emiMkt)
;

*' Feedstocks have identical fossil/biomass/synfuel shares as industry FE
q37_feedstocksShares(t,regi,entySe,entyFe,emiMkt)$(
                         sum(te, se2fe(entySe,entyFe,te))
                     AND entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt)
                     AND cm_emiscen ne 1                                   ) ..
    vm_demFeSector_afterTax(t,regi,entySe,entyFe,"indst",emiMkt)
  * sum(se2fe(entySe2,entyFe,te),
      vm_demFENonEnergySector(t,regi,entySe2,entyFe,"indst",emiMkt)
    )
  =e=
    vm_demFENonEnergySector(t,regi,entySe,entyFe,"indst",emiMkt)
  * sum(se2fe2(entySe2,entyFe,te),
      vm_demFeSector_afterTax(t,regi,entySe2,entyFe,"indst",emiMkt)
    )
;


*' Calculate mass of carbon contained in chemical feedstocks
q37_FeedstocksCarbon(t,regi,sefe(entySe,entyFe),emiMkt)$(
                         entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt) ) ..
  v37_FeedstocksCarbon(t,regi,entySe,entyFe,emiMkt)
  =e=
    vm_demFENonEnergySector(t,regi,entySe,entyFe,"indst",emiMkt)
  * p37_FeedstockCarbonContent(t,regi,entyFe)
;

*' Calculate carbon contained in plastics as a share of carbon in feedstock [GtC]
q37_plasticsCarbon(t,regi,sefe(entySe,entyFe),emiMkt)$(
                         entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt) ) ..
  v37_plasticsCarbon(t,regi,entySe,entyFe,emiMkt)
  =e=
    v37_FeedstocksCarbon(t,regi,entySe,entyFe,emiMkt)
  * s37_plasticsShare
;

*' calculate plastic waste generation, shifted by mean lifetime of plastic products
*' shift by 2 time steps when we have 5-year steps and 1 when we have 10-year steps
*' allocate averge of 2055 and 2060 to 2070
q37_plasticWaste(ttot,regi,sefe(entySe,entyFe),emiMkt)$(
                         entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt)
                     AND ttot.val ge max(2015, cm_startyear)               ) ..
  v37_plasticWaste(ttot,regi,entySe,entyFe,emiMkt)
  =e=
    v37_plasticsCarbon(ttot-2,regi,entySe,entyFe,emiMkt)$( ttot.val lt 2070 )
  + ( ( v37_plasticsCarbon(ttot-2,regi,entySe,entyFe,emiMkt)
      + v37_plasticsCarbon(ttot-1,regi,entySe,entyFe,emiMkt)
      )
    / 2
    )$( ttot.val eq 2070 )
  + v37_plasticsCarbon(ttot-1,regi,entySe,entyFe,emiMkt)$( ttot.val gt 2070 )
  ;

*' emissions from plastics incineration as a share of total plastic waste
q37_incinerationEmi(t,regi,sefe(entySe,entyFe),emiMkt)$(
                         entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt)) ..
  vm_incinerationEmi(t,regi,entySe,entyFe,emiMkt)
  =e=
    v37_plasticWaste(t,regi,entySe,entyFe,emiMkt)
  * pm_incinerationRate(t,regi)
;

*' calculate carbon contained in non-incinerated plastics
*' this is used in emissions accounting to subtract the carbon that gets
*' sequestered in plastic products
q37_nonIncineratedPlastics(t,regi,sefe(entySe,entyFe),emiMkt)$(
                         entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt) ) ..
  vm_nonIncineratedPlastics(t,regi,entySe,entyFe,emiMkt)
  =e=
    v37_plasticWaste(t,regi,entySe,entyFe,emiMkt)
  * (1 - pm_incinerationRate(t,regi))
  ;

*' calculate flow of carbon contained in chemical feedstock with unknown fate
*' it is assumed that this carbon is re-emitted in the same timestep
q37_feedstockEmiUnknownFate(t,regi,sefe(entySe,entyFe),emiMkt)$(
                         entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt) ) ..
  vm_feedstockEmiUnknownFate(t,regi,entySe,entyFe,emiMkt)
  =e=
    v37_FeedstocksCarbon(t,regi,entySe,entyFe,emiMkt)
  * (1 - s37_plasticsShare)
;

*' in baseline runs, all industrial feedstocks should come from fossil energy
*' carriers, no biofuels or synfuels
q37_FossilFeedstock_Base(t,regi,entyFe,emiMkt)$(
                         entyFE2sector2emiMkt_NonEn(entyFe,"indst",emiMkt)
                     AND cm_emiscen eq 1                                   ) ..
  sum(entySe, vm_demFENonEnergySector(t,regi,entySe,entyFe,"indst",emiMkt))
  =e=
  sum(entySeFos,
    vm_demFENonEnergySector(t,regi,entySeFos,entyFe,"indst",emiMkt)
  )
;


*** EOF ./modules/37_industry/subsectors/equations.gms
