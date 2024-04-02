*** |  (C) 2006-2023 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/37_industry/subsectors/postsolve.gms

*** calculation of FE Industry Prices (useful for internal use and reporting
*** purposes)
pm_FEPrice(ttot,regi,entyFe,"indst",emiMkt)$(
          abs(qm_budget.m(ttot,regi)) gt sm_eps
      AND sum(sefe(entySe,entyFe),
            vm_demFeSector_afterTax.l(ttot,regi,entySe,entyFe,"indst",emiMkt)
          )                                                                   )
  = sum(sefe(entySe,entyFe),
      q37_demFeIndst.m(ttot,regi,entySe,entyFe,emiMkt)
    / qm_budget.m(ttot,regi)
    * vm_demFeSector_afterTax.l(ttot,regi,entySe,entyFe,"indst",emiMkt)
    )
  / sum(sefe(entySe,entyFe),
      vm_demFeSector_afterTax.l(ttot,regi,entySe,entyFe,"indst",emiMkt)
    );

*** FE per subsector and energy carriers
o37_demFeIndSub(ttot,regi,entySe,entyFe,secInd37,emiMkt)$(
                                             sefe(entySe,entyFe)
                                         AND secInd37_emiMkt(secInd37,emiMkt) )
  = sum((secInd37_2_pf(secInd37,out),
         ue_industry_dyn37(out)),
      v37_demFeIndst.l(ttot,regi,entySe,entyFe,out,emiMkt)
    );

*** industry captured fuel CO2
pm_IndstCO2Captured(ttot,regi,entySe,entyFe(entyFeCC37),secInd37,emiMkt)$(
                     emiInd37_fe2sec(entyFe,secInd37)
                 AND sum(entyFE2, vm_emiIndBase.l(ttot,regi,entyFE2,secInd37)) )
  = ( o37_demFeIndSub(ttot,regi,entySe,entyFe,secInd37,emiMkt)
    * sum(se2fe(entySE2,entyFe,te),
        !! collapse entySe dimension, so emission factors apply to all entyFe
        !! regardless or origin, and therefore entySEbio and entySEsyn have
        !! non-zero emission factors
        pm_emifac(ttot,regi,entySE2,entyFe,te,"co2")
      )
    ) !! subsector emissions (smokestack, i.e. including biomass & synfuels)

  * ( sum(secInd37_2_emiInd37(secInd37,emiInd37(emiInd37_fuel)),
      vm_emiIndCCS.l(ttot,regi,emiInd37)
      ) !! subsector captured energy emissions

    / sum(entyFE2,
        vm_emiIndBase.l(ttot,regi,entyFE2,secInd37)
      ) !! subsector total energy emissions
    ) !! subsector capture share
;


*** EOF ./modules/37_industry/subsectors/postsolve.gms
