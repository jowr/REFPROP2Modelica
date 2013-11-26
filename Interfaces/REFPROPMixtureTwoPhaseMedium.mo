within REFPROP2Modelica.Interfaces;
partial package REFPROPMixtureTwoPhaseMedium
  "Two-phase mixture medium (properties supplied by REFPROP library)"
    extends REFPROP2Modelica.Interfaces.PartialMixtureTwoPhaseMedium(
    mediumName="REFPROP Medium",
    final reducedX=true,
    final singleState=false,
    final smoothModel=true,
    reference_X=cat(
        1,
        fill(0, nX - 1),
        {1}),
    fluidConstants=rpConstants);

  final constant String fluidnames=StrJoin(substanceNames, "|")
    "Merge all substance names to one string for refprop library";
      constant Boolean debugmode=false
    "print messages in functions and wrapper library if run from command line";
  constant FluidConstants[nS] rpConstants(
    each chemicalFormula="REFPROP Medium",
    each structureFormula="REFPROP Medium",
    each casRegistryNumber="007",
    each iupacName="REFPROP Medium",
    each molarMass=0.1,
    each criticalTemperature=600,
    each criticalPressure=300e5,
    each criticalMolarVolume=1,
    each acentricFactor=1,
    each triplePointTemperature=273.15,
    each triplePointPressure=1e5,
    each meltingPoint=1,
    each normalBoilingPoint=1,
    each dipoleMoment=1);

//import REFPROP2Modelica.Interfaces.MixtureInputChoice;
//constant MixtureInputChoice explicitVars = InputChoice.phX
//    "set of variables the model is explicit for, may be set to all combinations of p,h,T,d,s,d, REFPROP works internally with dT";

//   inputChoice = explicitVars,
//"mediumName is being checked for consistency at flowports"
  partial function partialREFPROP "Declaration of array props"
  //used by getSatProp_REFPROP_check() and getProp_REFPROP_check()
    extends Modelica.Icons.Function;
  protected
    Real[16 + 2*nX] props;
    Real[21] ders;
    Real[3] trns;
    String errormsg=StrJoin(fill("xxxx", 64), "")
      "Allocating memory, string will be written by C function, doesn't work for strings longer than 40 bytes";
  // initial algorithm
  //   props :=fill(1, (16 + 2*nX));
  //   ders  :=fill(1, 19);
  //   trns  :=fill(1, 3);

  end partialREFPROP;

  function getProp_REFPROP
    "calls C function with property identifier & returns single property"
    input String what2calc;
    input String statevars;
    input String fluidnames;
    input Real[:] ders;
    input Real[:] trns;
    input Real[:] props;
    input Real statevar1;
    input Real statevar2;
    input MassFraction X[:] "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    input String errormsg;
  //    input Integer debug=1;
    output Real val;
  external "C" val=  props_REFPROP(
        what2calc,
        statevars,
        fluidnames,
        ders,
        trns,
        props,
        statevar1,
        statevar2,
        X,
        phase,
        REFPROP_PATH,
        errormsg,
        debugmode);
    annotation (Include="#include <refprop_wrapper.h>", Library="refprop_wrapper");
  end getProp_REFPROP;

  function getProp_REFPROP_check
    "wrapper for getProp_REFPROP returning 1 property value with error check"
    extends partialREFPROP;
    input String what2calc;
    input String statevars;
  //    input String fluidnames;
    input Real statevar1;
    input Real statevar2;
    input MassFraction X[:] "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Real val;
  algorithm
    assert(size(X, 1) > 0, "The mass fraction vector must have at least 1 element.");
  //   Modelica.Utilities.Streams.print("Calc "+what2calc);

    val := getProp_REFPROP(
        what2calc,
        statevars,
        fluidnames,
        ders,
        trns,
        props,
        statevar1,
        statevar2,
        X,
        phase,
        errormsg) "just passing through";

  //   Modelica.Utilities.Streams.print("ERR("+String(props[1])+"):"+errormsg);
    assert(props[1] == 0, "Errorcode " + String(props[1]) + " in REFPROP wrapper function:\n"
       + errormsg + "\n");
  end getProp_REFPROP_check;

  function getSatProp_REFPROP
    "calls C function with property identifier & returns single property"
    input String what2calc;
    input String statevar;
    input String fluidnames;
    input Real[:] ders;
    input Real[:] trns;
    input Real[:] props;
    input Real statevarval;
    input MassFraction X[:] "mass fraction m_NaCl/m_Sol";
    input String errormsg;
    output Real val;
  //   input Integer debugmode=1;
  external"C" val=  satprops_REFPROP(
        what2calc,
        statevar,
        fluidnames,
        ders,
        trns,
        props,
        statevarval,
        X,
        REFPROP_PATH,
        errormsg,
        debugmode);
    annotation (Include="#include <refprop_wrapper.h>", Library="refprop_wrapper");
  end getSatProp_REFPROP;

  function getSatProp_REFPROP_check
    "wrapper for getSatProp_REFPROP returning 1 property value with error check"
    extends partialREFPROP;
    input String what2calc;
    input String statevar;
  //   input String fluidnames;
    input Real statevarval;
    input MassFraction X[:] "mass fraction m_NaCl/m_Sol";
    output Real val;
  algorithm
    assert(size(X, 1) > 0, "The mass fraction vector must have at least 1 element.");
    val := getSatProp_REFPROP(
        what2calc,
        statevar,
        fluidnames,
        ders,
        trns,
        props,
        statevarval,
        X,
        errormsg) "just passing through";
  //Error string decoding in wrapper-c-function
    assert(props[1] == 0 or props[1] == 141, "Errorcode " + String(props[1]) + " in REFPROP wrapper function:\n"
       + errormsg + "\n");
    if props[1] == 141 then
      Modelica.Utilities.Streams.print("Saturation properties cannot be calculated, because P > p_crit!...");
      val := -999;
    end if;
  end getSatProp_REFPROP_check;

redeclare record extends ThermodynamicState
    "Adapt this record to the returned values from one REFPROP call."

//  Density d_l "density of liquid phase";
//  Density d_g "density of gaseous phase";
//  MassFraction x "void fraction";
// SpecificInternalEnergy u "Specific energy";

// MolarMass MM_l "Molar Mass of liquid phase";
//  MolarMass MM_g "Molar Mass of gas phase";
//  MassFraction X_l[nX]
//    "Composition of liquid phase (Mass fractions  in kg/kg)";
//  MassFraction X_g[nX] "Composition of gas phase (Mass fractions  in kg/kg)";
//    DerDensityByEnthalpy ddhp
//    "derivative of density wrt enthalpy at constant pressure";
//    DerDensityByPressure ddph
//    "derivative of density wrt pressure at constant enthalpy";

  Real hjt "isenthalpic Joule-Thompson coefficient [K/Pa]";
  Modelica.SIunits.SpecificHelmholtzFreeEnergy a "Helmholtz energy";
  Modelica.SIunits.SpecificGibbsFreeEnergy f "Gibbs free energy";
  Modelica.SIunits.IsothermalCompressibility kappa "isothermal compressibility";
  IsobaricExpansionCoefficient beta
      "volume expansivity (= 1/V dV/dT = -1/rho dD/dT)";

  DerPressureByDensity dpdrho_T;
  DerDerPressureByDensityByDensity d2pdrho2_T;
  DerPressureByTemperature dpdT_rho;
  DerDensityByTemperature drhodT_p;
  DerDensityByPressure drhodp_T;
  DerDerPressureByTemperatureByTemperature d2pdT2_rho;
  DerDerPressureByTemperatureByDensity d2pdTdrho;
  DerEnthalpyByTemperature dhdT_rho "dH/dT at constant density";
  DerEnthalpyByTemperature dhdT_p "dH/dT at constant pressure";
  DerEnthalpyByDensity dhdrho_T "dH/drho at constant temperature";
  DerEnthalpyByDensity dhdrho_p "dH/drho at constant pressure";
  DerEnthalpyByPressure dhdp_T "dH/dP at constant temperature";
  DerEnthalpyByPressure dhdp_rho "dH/dP at constant density";

  DerDensityByEnthalpy drhodh_p "drho/dh at constant pressure";
  DerDensityByPressure drhodp_h "drho/dp at constant enthalpy";

  DynamicViscosity eta "dynamic viscosity";
  ThermalConductivity lambda "thermal conductivity";

end ThermodynamicState;

// redeclare record extends ThermodynamicState
//     "a selection of variables that uniquely defines the thermodynamic state"
// /*  AbsolutePressure p "Absolute pressure of medium";
//   Temperature T "Temperature of medium";
//   MassFraction X[nX] "Composition (Mass fractions  in kg/kg)";*/
//   MolarMass MM "Molar Mass of the whole mixture";
//   Density d(start=300) "density";
//   SpecificEnergy u "Specific energy";
//   SpecificEnthalpy h "Specific enthalpy";
//   SpecificEntropy s "Specific entropy";
//   Modelica.SIunits.SpecificHeatCapacityAtConstantPressure cp;
//   Modelica.SIunits.SpecificHeatCapacityAtConstantVolume cv;
//   VelocityOfSound c;
//   MolarMass MM_l "Molar Mass of liquid phase";
//   MolarMass MM_g "Molar Mass of gas phase";
//   MassFraction X_l[nX] "Composition of liquid phase (Mass fractions  in kg/kg)";
//   MassFraction X_g[nX] "Composition of gas phase (Mass fractions  in kg/kg)";
// //  Real GVF "Gas Void Fraction";
// end ThermodynamicState;

//   redeclare model extends BaseProperties "Base properties of medium"
//   equation
//     u = h - p/d
//       "state.u - calculated anyway by REFPROP, but this way the expression can be derived symbolically";
//     MM = state.molarMass;
//     R  = Modelica.Constants.R/MM;
//   //ph-explicit
//   if explicitVars=="ph" or explicitVars=="hp" then
//     state = setState_phX(p,h,X,0) " ,fluidnames)";
//     T = temperature_phX(p,h,X)
//         "double calculation, but necessary if T is given";
//   //  T = state.T "can be used instead";
//     s = specificEntropy_phX(p,h,X)
//         "double calculation, but necessary if s is given";
//   //  s = state.s "can be used instead";
//     d = density_phX(p,h,X) "double calculation, but necessary if d is given";
//     //d = state.d "can be used instead";
//   elseif explicitVars=="pT" or explicitVars=="Tp" then
//   //pT-explicit
//     state = setState_pTX(p,T,X,0) ",fluidnames)";
//     h = specificEnthalpy_pTX(p,T,X)
//         "double calculation, but necessary if s is given";
//     //h = state.h "can be used instead";
//     s = specificEntropy_pTX(p,T,X)
//         "state.s double calculation, but necessary if s is given";
//   //  s = state.s "can be used instead";
//     d = density_pTX(p,T,X)
//         "state.d double calculation, but necessary if d is given";
//     //d = state.d "can be used instead";
//   elseif explicitVars=="dT" or explicitVars=="Td" then
//     //Td-explicit
//     state = setState_dTX(d,T,X,0) ",fluidnames)";
//     h = specificEnthalpy_dTX(d,T,X)
//         "double calculation, but necessary if s is given";
//     //h = state.h "can be used instead";
//     s = specificEntropy_dTX(d,T,X)
//         "state.s double calculation, but necessary if s is given";
//   //  s = state.s "can be used instead";
//     p = pressure_dTX(d,T,X)
//         "state.d double calculation, but necessary if d is given";
//   //  p = state.p "can be used instead";
//   elseif explicitVars=="ps" or explicitVars=="ps" then
//     state = setState_psX(p,s,X,0) ",fluidnames)";
//     T = temperature_psX(p,s,X);
//     h = specificEnthalpy_psX(p,s,X);
//     d = density_psX(p,s,X);
//   elseif explicitVars=="pd" or explicitVars=="pd" then
//     state = setState_pdX(p,d,X,0) ",fluidnames)";
//     T = temperature_pdX(p,d,X);
//     h = specificEnthalpy_pdX(p,d,X);
//     s = specificEntropy_pdX(p,d,X);
//   elseif explicitVars=="hT" or explicitVars=="Th" then
//     state = setState_ThX(T,h,X,0) ",fluidnames)";
//     p = pressure_ThX(T,h,X);
//     s = specificEntropy_ThX(T,h,X);
//     d = density_ThX(T,h,X);
//   elseif explicitVars=="sT" or explicitVars=="Ts" then
//     state = setState_TsX(T,s,X,0) ",fluidnames)";
//     p = pressure_TsX(T,s,X);
//     h = specificEnthalpy_TsX(T,s,X);
//     d = density_TsX(T,s,X);
//   elseif explicitVars=="hd" or explicitVars=="hd" then
//     state = setState_hdX(h,d,X,0) ",fluidnames)";
//     p = pressure_hdX(h,d,X);
//     s = specificEntropy_hdX(h,d,X);
//     T = temperature_hdX(h,d,X);
//   elseif explicitVars=="hs" or explicitVars=="sh" then
//     state = setState_hsX(h,s,X,0) ",fluidnames)";
//     p = pressure_hsX(h,s,X);
//     T = temperature_hsX(h,s,X);
//     d = density_hsX(h,s,X);
//   elseif explicitVars=="sd" or explicitVars=="ds" then
//     state = setState_dsX(d,s,X,0) ",fluidnames)";
//     p = pressure_dsX(d,s,X);
//     h = specificEnthalpy_dsX(d,s,X);
//     T = temperature_dsX(d,s,X);
//   end if;
//     sat.psat = p;
//     sat.Tsat = saturationTemperature(p,X);
//     sat.X = X;
//    annotation (Documentation(info="
//  <html>
//  The baseproperties model is explicit for one set of 2 variables, which can be chosen to be ph, pT, ps, pd, Th, dT, Ts, hd, hs, ds (set explicitVars when calling this package or in package).<br/>
//  That means, that if only one of these variables is explicitly given, the other one is calculated by inverting its property function.<br/>
//  Then alle state variables are calculated using the corresponding setstate_XX function.<br/>
//  In order to avoid numerical inversion by the solver, 3 state variables are set explicitly using their respective property function, which has its inverses defined.<br/>
//  Example: So for p and h as explicit variables a state given by p and T is calculated by first calculating h with specificEnthalpy_pTX (inverse function of temperature_phX),
//  then calculating the other variables using setState_phX. s and d, however, are then calculated, although they are already known in the state variable.<br/>
//  Knowing this, the baseproperty model can be adapted to your calculation needs to decrease computation time:
//  <ul>
//  <li>Choose the explicitVars to the combination occurring most often in your model. (The combination dT might be favorable, because it is used by REFPROP's internal algorithm.)</li>
//  <li>if you are sure, that it won't be needed, in BaseProperties replace explicit calculation of T/s/d/h with definition as state (commented line)</li>
//  </ul>
//  </html>"));
//   end BaseProperties;

  function setState "Calculates medium properties"
    extends partialREFPROP;
    input String statevars;
    input Real statevar1;
    input Real statevar2;
    input Modelica.SIunits.MassFraction X[:]=reference_X "Mass fractions";
    input FixedPhase phase "2 for two-phase, 1 for one-phase, 0 if not known";
  //  input String fluidnames;
    output ThermodynamicState state "thermodynamic state record";
  //  Real[:] props=getProps_REFPROP_check(statevars, fluidnames,statevar1, statevar2, X, phase);
  /*protected 
  Real[16+2*nX] props;
  String errormsg=StrJoin(fill("xxxx",64),"") 
    "Allocating memory, string will be written by C function";*/
  algorithm
    assert(size(X, 1) > 0, "The mass fraction vector must have at least 1 element.");
    getProp_REFPROP(
        "u",
        statevars,
        fluidnames,
        ders,
        trns,
        props,
        statevar1,
        statevar2,
        X,
        phase,
        errormsg);
    assert(props[1] == 0, "Error in REFPROP wrapper function: " + errormsg + "\n");
  /*  If q = 990 Then Modelica.Utilities.Streams.print(msg+String(z)) end if;

  If q = 998 Then Quality = Trim2("Superheated vapor with T>Tc")
  If q = 999 Then Quality = Trim2("Supercritical state (T>Tc, p>pc)")
  If q = -998 Then Quality = Trim2("Subcooled liquid with p>pc")*/
    state := ThermodynamicState(
        p=props[2],
        T=props[3],
        X=X,
        molarMass=props[4],
        d=props[5],
        h=props[10],
        s=props[11],
        cv=props[12],
        cp=props[13],
        w=props[14],
        phase=if (props[8] > 0 and props[8] < 1) then 2 else 1,
        hjt=ders[2],
        a=ders[3],
        f=ders[4],
        kappa=ders[5],
        beta=ders[6],
        dpdrho_T=ders[7],
        d2pdrho2_T=ders[8],
        dpdT_rho=ders[9],
        drhodT_p=ders[10],
        drhodp_T=ders[11],
        d2pdT2_rho=ders[12],
        d2pdTdrho=ders[13],
        dhdT_rho=ders[14],
        dhdT_p=ders[15],
        dhdrho_T=ders[16],
        dhdrho_p=ders[17],
        dhdp_T=ders[18],
        dhdp_rho=ders[19],
        drhodh_p=ders[20],
        drhodp_h=ders[21],
        eta=trns[2],
        lambda=trns[3]);

    if debugmode then
      Modelica.Utilities.Streams.print("Running state set to p,T,d,h,s ("
      + String(state.p) + "," + String(state.T) + "," + String(state.d) + "," + String(state.h) + "," + String(state.s) + ")");
    end if;

  end setState;

  function setState_dsX "Calculates medium properties from d,s,X"
    extends Modelica.Icons.Function;
    input Density d "Temperature";
    input SpecificEntropy s "Entropy";
    input MassFraction X[:]=reference_X "Mass fractions";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
  //  input String fluidnames;
    output ThermodynamicState state "thermodynamic state record";
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_dsX(" + String(d) + ","
         + String(s) + ",X)...");
    end if;
    state := setState(
        "ds",
        d,
        s,
        X,
        phase) ",fluidnames)";
  end setState_dsX;

  redeclare replaceable function extends setState_dTX
  //      input String fluidnames;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_dTX(" + String(d) + ","
         + String(T) + ",X)...");
    end if;
    state := setState(
        "dT",
        d,
        T,
        X,
        phase) ",fluidnames)";
  end setState_dTX;

  function setState_hsX "Calculates medium properties from h,s,X"
    extends Modelica.Icons.Function;
    input SpecificEnthalpy h "Enthalpy";
    input SpecificEntropy s "Entropy";
    input MassFraction X[:]=reference_X "Mass fractions";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
  //  input String fluidnames;
    output ThermodynamicState state "thermodynamic state record";
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running (" + String(h) + "," + String(s)
         + ",X)...");
    end if;
    state := setState(
        "hs",
        h,
        s,
        X,
        phase) ",fluidnames)";
  end setState_hsX;

  function setState_hdX "Calculates medium properties from h,d,X"
    extends Modelica.Icons.Function;
    input SpecificEnthalpy h "Enthalpy";
    input Density d "Temperature";
    input MassFraction X[:]=reference_X "Mass fractions";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
  //  input String fluidnames;
    output ThermodynamicState state "thermodynamic state record";
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_hdX(" + String(h) + ","
         + String(d) + ",X)...");
    end if;
    state := setState(
        "hd",
        h,
        d,
        X,
        phase) ",fluidnames)";
  end setState_hdX;

  function setState_pdX "Calculates medium properties from p,d,X"
    extends Modelica.Icons.Function;
    input AbsolutePressure p "Pressure";
    input Density d "Density";
    input MassFraction X[:]=reference_X "Mass fractions";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
  //  input String fluidnames;
    output ThermodynamicState state "thermodynamic state record";
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_pdX(" + String(p) + ","
         + String(d) + ",X)...");
    end if;
    state := setState(
        "pd",
        p,
        d,
        X,
        phase) ",fluidnames)";
  end setState_pdX;

  redeclare replaceable function extends setState_phX
    "Calculates medium properties from p,h,X"
  //      input String fluidnames;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_phX(" + String(p) + ","
         + String(h) + ",X)...");
    end if;
    state := setState(
        "ph",
        p,
        h,
        X,
        phase) ",fluidnames)";
  end setState_phX;

  redeclare function extends setBubbleState
    "set the thermodynamic state on the bubble line"
  algorithm
      if debugmode then
        Modelica.Utilities.Streams.print("Running setState_phX(" + String(sat.psat) + ","
           + String(bubbleEnthalpy(sat)) + ",X)...");
      end if;
      state := setState(
          "pq",
          sat.psat,
          0,
          sat.X,
          phase) ",fluidnames)";
  end setBubbleState;

  redeclare function extends setDewState
    "set the thermodynamic state on the bubble line"
  algorithm
      if debugmode then
        Modelica.Utilities.Streams.print("Running setState_phX(" + String(sat.psat) + ","
           + String(dewEnthalpy(sat)) + ",X)...");
      end if;
      state := setState(
          "pq",
          sat.psat,
          1,
          sat.X,
          phase) ",fluidnames)";
  end setDewState;

  function setState_pqX "Calculates medium properties from p,q,X"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.AbsolutePressure p "Pressure";
    input Modelica.SIunits.MassFraction q "quality (vapor mass fraction)";
    input Modelica.SIunits.MassFraction X[:]=reference_X "Mass fractions";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
  //  input String fluidnames;
    output ThermodynamicState state "thermodynamic state record";
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_pqX(" + String(p) + ","
         + String(q) + ",X)...");
    end if;
    state := setState(
        "pq",
        p,
        q,
        X,
        phase) ",fluidnames)";
  end setState_pqX;

  redeclare replaceable partial function extends setState_psX
    "Calculates medium properties from p,s,X"
  //      input String fluidnames;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_psX(" + String(p) + ","
         + String(s) + ",X)...");
    end if;
    state := setState(
        "ps",
        p,
        s,
        X,
        phase) ",fluidnames)";
  end setState_psX;

  redeclare replaceable partial function extends setState_pTX
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_pTX(" + String(p) + ","
         + String(T) + ",X)...");
    end if;
    state := setState(
        "pT",
        p,
        T,
        X,
        phase) ",fluidnames)";
  end setState_pTX;

  function setState_ThX "Calculates medium properties from T,h,X"
    extends Modelica.Icons.Function;
    input Temperature T "Temperature";
    input SpecificEnthalpy h "Enthalpy";
    input MassFraction X[:]=reference_X "Mass fractions";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
  //  input String fluidnames;
    output ThermodynamicState state "thermodynamic state record";
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_ThX(" + String(T) + ","
         + String(h) + ",X)...");
    end if;
    state := setState(
        "Th",
        T,
        h,
        X,
        phase) ",fluidnames)";
  end setState_ThX;

  function setState_TsX "Calculates medium properties from T,s,X"
    extends Modelica.Icons.Function;
    input Temperature T "Temperature";
    input SpecificEntropy s "Entropy";
    input MassFraction X[:]=reference_X "Mass fractions";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
  //  input String fluidnames;
    output ThermodynamicState state "thermodynamic state record";
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running setState_TsX(" + String(T) + ","
         + String(s) + ",X)...");
    end if;
    state := setState(
        "Ts",
        T,
        s,
        X,
        phase) ",fluidnames)";
  end setState_TsX;

  redeclare function extends saturationPressure
  algorithm
    p := getSatProp_REFPROP_check(
        "p",
        "T",
        T,
        X);
  end saturationPressure;

  redeclare function extends saturationTemperature
  algorithm
    T := getSatProp_REFPROP_check(
        "T",
        "p",
        p,
        X);
  end saturationTemperature;

//  redeclare function extends specificEntropy
//     "Return specific entropy  - seems useless, but good for compatibility between PartialMedium and PartialMixedMediumTwoPhase"
//  algorithm
//   s := state.s;
//  end specificEntropy;

//   redeclare replaceable function extends density
//     "returns density from state - seems useless, but good for compatibility between PartialMedium and PartialMixedMediumTwoPhase"
//   algorithm
//     d := state.d;
//   end density;

  redeclare function extends dewEnthalpy "dew curve specific enthalpy"
    extends Modelica.Icons.Function;
  //algorithm
  //  hv := getProp_REFPROP_check(
  //      "h",
  //      "pq",
  //      sat.psat,
  //      1,
  //      sat.X,
  //      0);
    extends partialREFPROP;

  algorithm
    assert(size(sat.X, 1) > 0, "The mass fraction vector must have at least 1 element.");
    getProp_REFPROP(
        "u",
        "pq",
        fluidnames,
        ders,
        trns,
        props,
        sat.psat,
        1,
        sat.X,
        1,
        errormsg);
    assert(props[1] == 0, "Error in REFPROP wrapper function: " + errormsg + "\n");

    hv :=props[10];

  end dewEnthalpy;

  redeclare function extends dewEntropy "dew curve specific entropy"
    extends Modelica.Icons.Function;
  algorithm
    sv := getProp_REFPROP_check(
      "s",
      "pq",
      sat.psat,
      1,
      sat.X,
      1);
  end dewEntropy;

  redeclare function extends dewDensity "dew curve specific density"
    extends Modelica.Icons.Function;
  //algorithm
  //  dv := getProp_REFPROP_check(
  //    "d",
  //    "pq",
  //    sat.psat,
  //    1,
  //    sat.X,
  //    1);
    extends partialREFPROP;

  algorithm
    assert(size(sat.X, 1) > 0, "The mass fraction vector must have at least 1 element.");
    getProp_REFPROP(
        "u",
        "pq",
        fluidnames,
        ders,
        trns,
        props,
        sat.psat,
        1,
        sat.X,
        1,
        errormsg);
    assert(props[1] == 0, "Error in REFPROP wrapper function: " + errormsg + "\n");

    dv :=props[5];

  end dewDensity;

  redeclare function extends bubbleEnthalpy "boiling curve specific enthalpy"
    extends Modelica.Icons.Function;
  //algorithm
  //  hl := getProp_REFPROP_check(
  //    "h",
  //    "pq",
  //    sat.psat,
  //    0,
  //    sat.X,
  //    0);
    extends partialREFPROP;

  algorithm
    assert(size(sat.X, 1) > 0, "The mass fraction vector must have at least 1 element.");
    getProp_REFPROP(
        "u",
        "pq",
        fluidnames,
        ders,
        trns,
        props,
        sat.psat,
        0,
        sat.X,
        1,
        errormsg);
    assert(props[1] == 0, "Error in REFPROP wrapper function: " + errormsg + "\n");

    hl :=props[10];

  end bubbleEnthalpy;

  redeclare function extends bubbleEntropy "boiling curve specific entropy"
    extends Modelica.Icons.Function;
  algorithm
    sl := getProp_REFPROP_check(
      "s",
      "pq",
      sat.psat,
      0,
      sat.X,
      1);
  end bubbleEntropy;

  redeclare function extends bubbleDensity "boiling curve specific density"
    extends Modelica.Icons.Function;
  //algorithm
  //  dl := getProp_REFPROP_check(
  //    "d",
  //    "pq",
  //    sat.psat,
  //    0,
  //    sat.X,
  //    1);

    extends partialREFPROP;

  algorithm
    assert(size(sat.X, 1) > 0, "The mass fraction vector must have at least 1 element.");
    getProp_REFPROP(
        "u",
        "pq",
        fluidnames,
        ders,
        trns,
        props,
        sat.psat,
        0,
        sat.X,
        1,
        errormsg);
    assert(props[1] == 0, "Error in REFPROP wrapper function: " + errormsg + "\n");

    dl :=props[5];

  end bubbleDensity;

  redeclare replaceable function extends molarMass
    "Return the molar mass of the mixture"
    extends Modelica.Icons.Function;
  algorithm
    MM := state.molarMass;
  end molarMass;

//    redeclare function density_phX
//     "calls REFPROP-Wrapper, returns density"
//    extends Modelica.Icons.Function;
//      input Modelica.SIunits.Pressure p;
//      input Modelica.SIunits.SpecificEnthalpy h;
//      input MassFraction X[:]=reference_X
//       "composition defined by mass fractions";
//      input FixedPhase phase=0
//       "2 for two-phase, 1 for one-phase, 0 if not known";
//      output Modelica.SIunits.Density d;
//    algorithm
//      if debugmode then
//        Modelica.Utilities.Streams.print("Running density_phX("+String(p)+","+String(h)+",X)");
//      end if;
//        // p="+String(p)+",h="+String(h)+", X={"+String(X[1])+","+String(X[2])+"}");
//        d :=getProp_REFPROP_check("d", "ph",p,h,X,phase);
//      annotation(LateInline=true,inverse(h=specificEnthalpy_pdX(p,d,X,phase),
//                                         p=pressure_hdX(h,d,X,phase)));
//    end density_phX;

//    redeclare function temperature_phX
//     "calls REFPROP-Wrapper, returns temperature"
//    extends Modelica.Icons.Function;
//        input Modelica.SIunits.Pressure p;
//        input Modelica.SIunits.SpecificEnthalpy h;
//        input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
//        input FixedPhase phase=0
//       "2 for two-phase, 1 for one-phase, 0 if not known";
//      output Modelica.SIunits.Temperature T;
//    algorithm
//    if debugmode then
//       Modelica.Utilities.Streams.print("Running temperature_phX("+String(p)+","+String(h)+",X)");
//    end if;
//        T :=getProp_REFPROP_check("T", "ph",p,h,X,phase);
//      annotation(LateInline=true,inverse(h=specificEnthalpy_pTX(p,T,X,phase),
//                                         p=pressure_ThX(T,h,X,phase)));
//    end temperature_phX;

  function density_hsX "calls REFPROP-Wrapper, returns density"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.SpecificEnthalpy h;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Density d;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running density_hsX(" + String(h) + "," +
        String(s) + ",X)");
    end if;
    d := getProp_REFPROP_check(
        "d",
        "hs",
        h,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_hdX(
              h,
              d,
              X,
              phase), h=specificEnthalpy_dsX(
              d,
              s,
              X,
              phase)));
  end density_hsX;

  function density_pqX "calls REFPROP-Wrapper, returns specific density"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Real q;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Density d;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running density_pqX(" + String(p) + "," +
        String(q) + ",X)");
    end if;
    d := getProp_REFPROP_check(
        "d",
        "pq",
        p,
        q,
        X,
        phase);
  /*  annotation(LateInline=true,inverse(p=pressure_dqX(d,q,X,phase),
                                     q=quality_pdX(p,d,X,phase)));*/
  end density_pqX;

  redeclare function density_psX "calls REFPROP-Wrapper, returns density"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Density d;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running density_psX(" + String(p) + "," +
        String(s) + ",X)");
    end if;
    d := getProp_REFPROP_check(
        "d",
        "ps",
        p,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_pdX(
              p,
              d,
              X,
              phase), p=pressure_dsX(
              d,
              s,
              X,
              phase)));
  end density_psX;

  redeclare function density_pTX "calls REFPROP-Wrapper, returns density"
    extends Modelica.Icons.Function;
   //    input String fluidnames;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.Temperature T;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Density d;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running density_pTX(" + String(p) + "," +
        String(T) + ",X)...");
    end if;
    d := getProp_REFPROP_check(
        "d",
        "pT",
        p,
        T,
        X,
        phase);
    annotation (LateInline=true, inverse(T=temperature_pdX(
              p,
              d,
              X,
              phase), p=pressure_dTX(
              d,
              T,
              X,
              phase)));
  end density_pTX;

  function density_ThX "calls REFPROP-Wrapper, returns density"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Temperature T;
    input Modelica.SIunits.SpecificEnthalpy h;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Density d;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running density_ThX(" + String(T) + "," +
        String(h) + ",X)");
    end if;
    d := getProp_REFPROP_check(
        "d",
        "Th",
        T,
        h,
        X,
        phase);
    annotation (LateInline=true, inverse(h=specificEnthalpy_dTX(
              d,
              T,
              X,
              phase), T=temperature_hdX(
              h,
              d,
              X,
              phase)));
  end density_ThX;

  function density_TsX "calls REFPROP-Wrapper, returns density"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Temperature T;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Density d;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running density_TsX(" + String(T) + "," +
        String(s) + ",X)");
    end if;
    d := getProp_REFPROP_check(
        "d",
        "Ts",
        T,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_dTX(
              d,
              T,
              X,
              phase), T=temperature_dsX(
              d,
              s,
              X,
              phase)));
  end density_TsX;

  // explicit derivative functions for finite element models
  redeclare function density_derp_h
    "Return density derivative w.r.t. pressure at const specific enthalpy"
    extends Modelica.Icons.Function;
    input ThermodynamicState state "thermodynamic state record";
    output DerDensityByPressure ddph "Density derivative w.r.t. pressure";
  algorithm
  ddph := state.drhodp_h;
  end density_derp_h;

  redeclare function density_derh_p
    "Return density derivative w.r.t. specific enthalpy at constant pressure"
    extends Modelica.Icons.Function;
    input ThermodynamicState state "thermodynamic state record";
    output DerDensityByEnthalpy ddhp
      "Density derivative w.r.t. specific enthalpy";
  algorithm
  ddhp := state.drhodh_p;
  end density_derh_p;

  redeclare function density_derp_T
    "Return density derivative w.r.t. pressure at const temperature"
    extends Modelica.Icons.Function;
    input ThermodynamicState state "thermodynamic state record";
    output DerDensityByPressure ddpT "Density derivative w.r.t. pressure";
  algorithm
  ddpT := state.drhodp_T;
  end density_derp_T;

  redeclare function density_derT_p
    "Return density derivative w.r.t. temperature at constant pressure"
    extends Modelica.Icons.Function;
    input ThermodynamicState state "thermodynamic state record";
    output DerDensityByTemperature ddTp "Density derivative w.r.t. temperature";
  algorithm
  ddTp := state.drhodT_p;
  end density_derT_p;

//   redeclare function density_derX
//     "Return density derivative w.r.t. mass fraction"
//     extends Modelica.Icons.Function;
//     input ThermodynamicState state "thermodynamic state record";
//     output Density[nX] dddX "Derivative of density w.r.t. mass fraction";
// algorithm
//   dddX :=
//   end density_derX;

  function pressure_dsX "calls REFPROP-Wrapper, returns pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Density d;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Pressure p;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running pressure_dsX(" + String(d) + ","
         + String(s) + ",X)");
    end if;
    p := getProp_REFPROP_check(
        "p",
        "ds",
        d,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_pdX(
              p,
              d,
              X,
              phase), d=density_psX(
              p,
              s,
              X,
              phase)));
  end pressure_dsX;

  function pressure_dTX "calls REFPROP-Wrapper, returns pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Density d;
    input Modelica.SIunits.Temperature T;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Pressure p;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running pressure_dTX(" + String(d) + ","
         + String(T) + ",X)");
    end if;
    p := getProp_REFPROP_check(
        "p",
        "dT",
        d,
        T,
        X,
        phase);
    annotation (LateInline=true, inverse(d=density_pTX(
              p,
              T,
              X,
              phase), T=temperature_pdX(
              p,
              d,
              X,
              phase)));
  end pressure_dTX;

  function pressure_hdX "calls REFPROP-Wrapper, returns pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.SpecificEnthalpy h;
    input Modelica.SIunits.Density d;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Pressure p;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running pressure_hdX(" + String(h) + ","
         + String(d) + ",X)");
    end if;
    p := getProp_REFPROP_check(
        "p",
        "hd",
        h,
        d,
        X,
        phase);
    annotation (LateInline=true, inverse(h=specificEnthalpy_pdX(
              p,
              d,
              X,
              phase),d=density_phX(
              p,
              h,
              X,
              phase)));
  end pressure_hdX;

  function pressure_hsX "calls REFPROP-Wrapper, returns pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.SpecificEnthalpy h;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Pressure p;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running pressure_hsX(" + String(h) + ","
         + String(s) + ",X)");
    end if;
    p := getProp_REFPROP_check(
        "p",
        "hs",
        h,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_phX(
              p,
              h,
              X,
              phase), h=specificEnthalpy_psX(
              p,
              s,
              X,
              phase)));
  end pressure_hsX;

  function pressure_ThX "calls REFPROP-Wrapper, returns pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Temperature T;
    input Modelica.SIunits.SpecificEnthalpy h;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Pressure p;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running pressure_ThX(" + String(T) + ","
         + String(h) + ",X)...");
    end if;
    p := getProp_REFPROP_check(
        "p",
        "Th",
        T,
        h,
        X,
        phase);
    annotation (LateInline=true, inverse(h=specificEnthalpy_pTX(
              p,
              T,
              X,
              phase), T=temperature_phX(
              p,
              h,
              X,
              phase)));
  end pressure_ThX;

  function pressure_TqX "calls REFPROP-Wrapper, returns pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Temperature T;
    input Real q;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Pressure p;
    //T=quality_pTX(p,T,X,phase)
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running pressure_TqX(" + String(T) + ","
         + String(q) + ",X)");
    end if;
    p := getProp_REFPROP_check(
        "p",
        "Tq",
        T,
        q,
        X,
        phase);
    annotation (LateInline=true, inverse(T=temperature_pqX(
              p,
              q,
              X,
              phase)));
  end pressure_TqX;

  function pressure_TsX "calls REFPROP-Wrapper, returns pressure"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Temperature T;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Pressure p;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running pressure_TsX(" + String(T) + ","
         + String(s) + ",X)...");
    end if;
    p := getProp_REFPROP_check(
        "p",
        "Ts",
        T,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_pTX(
              p,
              T,
              X,
              phase), T=temperature_psX(
              p,
              s,
              X,
              phase)));
  end pressure_TsX;

  function specificEnthalpy_dsX
    "calls REFPROP-Wrapper, returns specific enthalpy"
    //does not extend existing function from PartialMedium because there the algorithm is already defined
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Density d;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
  //  input String fluidnames;
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEnthalpy h;
  /*protected 
   Real[14+2*nX] props;
   String errormsg=StrJoin(fill("xxxx",10),"");*/
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEnthalpy_dsX(" + String(
         d) + "," + String(s) + ",X)");
    end if;
  //    h :=getProp_REFPROP_check("h", "ds", fluidnames,d,s,X,phase);
    h := getProp_REFPROP_check(
        "h",
        "ds",
        d,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_hdX(
              h,
              d,
              X,
              phase), d=density_hsX(
              h,
              s,
              X,
              phase)));
  end specificEnthalpy_dsX;

  redeclare function specificEnthalpy_dTX
    "calls REFPROP-Wrapper, returns specific enthalpy"
    //does not extend existing function from PartialMedium because there the algorithm is already defined
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Density d;
    input Modelica.SIunits.Temperature T;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
  //  input String fluidnames;
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEnthalpy h;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEnthalpy_dTX(" + String(
         d) + "," + String(T) + ",X)");
    end if;
  //    h :=getProp_REFPROP_check("h", "dT", fluidnames,d,T,X,phase);
    h := getProp_REFPROP_check(
        "h",
        "dT",
        d,
        T,
        X,
        phase);
    annotation (LateInline=true, inverse(d=density_ThX(
              T,
              h,
              X,
              phase), T=temperature_hdX(
              h,
              d,
              X,
              phase)));
  end specificEnthalpy_dTX;

  function specificEnthalpy_pdX
    "calls REFPROP-Wrapper, returns specific enthalpy"
    //does not extend existing function from PartialMedium because there the algorithm is already defined
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.Density d;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEnthalpy h;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEnthalpy_pdX(" + String(
         p) + "," + String(d) + ",X)...");
    end if;
  //  h :=getProp_REFPROP_check("h", "pd", fluidnames,p,d,X,phase);
    h := getProp_REFPROP_check(
        "h",
        "pd",
        p,
        d,
        X,
        phase);
    annotation (LateInline=true, inverse(d=density_phX(
              p,
              h,
              X,
              phase), p=pressure_hdX(
              h,
              d,
              X,
              phase)));
  end specificEnthalpy_pdX;

  function specificEnthalpy_pqX
    "calls REFPROP-Wrapper, returns specific enthalpy"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Real q;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEnthalpy h;
  //  annotation(LateInline=true,inverse(p = pressure_hqX(h,q,X,phase),quality_phX(p,h,X,phase)));
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEnthalpy_pqX(" + String(
         p) + "," + String(q) + ",X)");
    end if;
  //  h :=getProp_REFPROP_check("h", "pq", fluidnames,p,q,X,phase);
    h := getProp_REFPROP_check(
        "h",
        "pq",
        p,
        q,
        X,
        phase);
  end specificEnthalpy_pqX;

  redeclare function specificEnthalpy_psX
    "calls REFPROP-Wrapper, returns specific enthalpy"
    //does not extend existing function from PartialMedium because there the algorithm is already defined
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
  //  input String fluidnames;
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEnthalpy h;
  /*protected 
   Real[14+2*nX] props;
   String errormsg=StrJoin(fill("xxxx",10),"");*/
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEnthalpy_psX(" + String(
         p) + "," + String(s) + ",X)...");
    end if;
    h := getProp_REFPROP_check(
        "h",
        "ps",
        p,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_phX(
              p,
              h,
              X,
              phase), p=pressure_hsX(
              h,
              s,
              X,
              phase)));
  end specificEnthalpy_psX;

  redeclare function specificEnthalpy_pTX
    "calls REFPROP-Wrapper, returns specific enthalpy"
    //does not extend existing function from PartialMedium because there the algorithm is already defined
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.Temp_K T;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
  //  input String fluidnames;
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEnthalpy h;
  /*protected 
   Real[14+2*nX] props;
   String errormsg=StrJoin(fill("xxxx",10),"");*/
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEnthalpy_pTX(" + String(
         p) + "," + String(T) + ",X)...");
    end if;
      // p="+String(p)+",T="+String(T)+", X={"+String(X[1])+","+String(X[2])+"}");
    h := getProp_REFPROP_check(
        "h",
        "pT",
        p,
        T,
        X,
        phase);
    annotation (LateInline=true, inverse(T=temperature_phX(
              p,
              h,
              X,
              phase), p=pressure_ThX(
              T,
              h,
              X,
              phase)));
  end specificEnthalpy_pTX;

  function specificEnthalpy_TsX
    "calls REFPROP-Wrapper, returns specific enthalpy"
    //does not extend existing function from PartialMedium because there the algorithm is already defined
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Temperature T;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
  //  input String fluidnames;
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEnthalpy h;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEnthalpy_TsX(" + String(
         T) + "," + String(s) + ",X)");
    end if;
    h := getProp_REFPROP_check(
        "h",
        "Ts",
        T,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_ThX(
              T,
              h,
              X,
              phase), T=temperature_hsX(
              h,
              s,
              X,
              phase)));
  end specificEnthalpy_TsX;

  function specificEntropy_dTX
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Density d;
    input Modelica.SIunits.Temperature T;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
  //  input String fluidnames;
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEntropy s;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEntropy_dTX(" + String(
        d) + "," + String(T) + ",X)");
    end if;
    s := getProp_REFPROP_check(
        "s",
        "dT",
        d,
        T,
        X,
        phase);
    annotation (LateInline=true, inverse(d=density_TsX(
              T,
              s,
              X,
              phase), T=temperature_dsX(
              d,
              s,
              X,
              phase)));
  end specificEntropy_dTX;

  function specificEntropy_hdX
    extends Modelica.Icons.Function;
    input Modelica.SIunits.SpecificEnthalpy h;
    input Modelica.SIunits.Density d;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEntropy s;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEntropy_hdX(" + String(
        h) + "," + String(d) + ",X)");
    end if;
    s := getProp_REFPROP_check(
        "s",
        "hd",
        h,
        d,
        X,
        phase);
    annotation (LateInline=true, inverse(d=density_hsX(
              h,
              s,
              X,
              phase), h=specificEnthalpy_dsX(
              d,
              s,
              X,
              phase)));
  end specificEntropy_hdX;

  function specificEntropy_pdX
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.Density d;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEntropy s;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEntropy_pdX(" + String(
        p) + "," + String(d) + ",X)");
    end if;
    s := getProp_REFPROP_check(
        "s",
        "pd",
        p,
        d,
        X,
        phase);
    annotation (LateInline=true, inverse(d=density_psX(
              p,
              s,
              X,
              phase), p=pressure_dsX(
              d,
              s,
              X,
              phase)));
  end specificEntropy_pdX;

//   function specificEntropy_phX
//     extends Modelica.Icons.Function;
//     input Modelica.SIunits.Pressure p;
//     input Modelica.SIunits.SpecificEnthalpy h;
//     input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
//   //  input String fluidnames;
//     input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
//     output Modelica.SIunits.SpecificEntropy s;
//   /*protected
//    Real[14+2*nX] props;
//    String errormsg=StrJoin(fill("xxxx",10),"");*/
//   algorithm
//     if debugmode then
//       Modelica.Utilities.Streams.print("Running specificEntropy_phX(" + String(
//         p) + "," + String(h) + ",X)...");
//       // p="+String(p)+",h="+String(h)+", X={"+String(X[1])+","+String(X[2])+"}");
//     end if;
//     s := getProp_REFPROP_check(
//         "s",
//         "ph",
//         p,
//         h,
//         X,
//         phase);
//     annotation (LateInline=true, inverse(h=specificEnthalpy_psX(
//               p,
//               s,
//               X,
//               phase), p=pressure_hsX(
//               h,
//               s,
//               X,
//               phase)));
//   end specificEntropy_phX;

  function specificEntropy_pqX
    "calls REFPROP-Wrapper, returns specific entropy"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Real q;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEntropy s;
  //  annotation(LateInline=true,inverse(p = pressure_sqX(s,q,X,phase),q=quality_psX(p,s,X,phase));
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEntropy_pqX(" + String(
        p) + "," + String(q) + ",X)");
    end if;
    s := getProp_REFPROP_check(
        "s",
        "pq",
        p,
        q,
        X,
        phase);
  end specificEntropy_pqX;

  redeclare function specificEntropy_pTX
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.Temp_K T;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEntropy s;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEntropy_pTX(" + String(
        p) + "," + String(T) + ",X)");
    end if;
    s := getProp_REFPROP_check(
        "s",
        "pT",
        p,
        T,
        X,
        phase);
    annotation (LateInline=true, inverse(T=temperature_psX(
              p,
              s,
              X,
              phase), p=pressure_TsX(
              T,
              s,
              X,
              phase)));
  end specificEntropy_pTX;

  function specificEntropy_ThX
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Temperature T;
    input Modelica.SIunits.SpecificEnthalpy h;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
  //  input String fluidnames;
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.SpecificEntropy s;
  /*protected 
   Real[14+2*nX] props;
   String errormsg=StrJoin(fill("xxxx",10),"");*/
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running specificEntropy_ThX(" + String(
        T) + "," + String(h) + ",X)");
    end if;
    s := getProp_REFPROP_check(
        "s",
        "Th",
        T,
        h,
        X,
        phase);
    annotation (LateInline=true, inverse(h=specificEnthalpy_TsX(
              T,
              s,
              X,
              phase), T=temperature_hsX(
              h,
              s,
              X,
              phase)));
  end specificEntropy_ThX;

  function temperature_dsX "calls REFPROP-Wrapper, returns temperature"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Density d;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Temperature T;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running temperature_dsX(" + String(d) + ","
         + String(s) + ",X)");
    end if;
    T := getProp_REFPROP_check(
        "T",
        "ds",
        d,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_dTX(
              d,
              T,
              X,
              phase), d=density_TsX(
              T,
              s,
              X,
              phase)));
  end temperature_dsX;

  function temperature_hdX "calls REFPROP-Wrapper, returns temperature"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.SpecificEnthalpy h;
    input Modelica.SIunits.Density d;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Temperature T;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running temperature_hdX(" + String(h) + ","
         + String(d) + ",X)");
    end if;
    T := getProp_REFPROP_check(
        "T",
        "hd",
        h,
        d,
        X,
        phase);
    annotation (LateInline=true, inverse(d=density_ThX(
              T,
              h,
              X,
              phase), h=specificEnthalpy_dTX(
              d,
              T,
              X,
              phase)));
  end temperature_hdX;

  function temperature_hsX "calls REFPROP-Wrapper, returns temperature"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.SpecificEnthalpy h;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Temperature T;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running temperature_hsX(" + String(h) + ","
         + String(s) + ",X)");
    end if;
    T := getProp_REFPROP_check(
        "T",
        "hs",
        h,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_ThX(
              T,
              h,
              X,
              phase), h=specificEnthalpy_TsX(
              T,
              s,
              X,
              phase)));
  end temperature_hsX;

  function temperature_pdX "calls REFPROP-Wrapper, returns temperature"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.Density d;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Temperature T;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running temperature_psX(" + String(p) + ","
         + String(d) + ",X)...");
    end if;
    T := getProp_REFPROP_check(
        "T",
        "pd",
        p,
        d,
        X,
        phase);
    annotation (LateInline=true, inverse(d=density_pTX(
              p,
              T,
              X,
              phase), p=pressure_dTX(
              d,
              T,
              X,
              phase)));
  end temperature_pdX;

  function temperature_pqX
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input MassFraction q;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Temperature T;
  //  annotation(LateInline=true,inverse(p = pressure_TqX(T,q,X,phase),q=quality_pTX(p,T,X,phase));
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running temperature_pqX(" + String(p) + ","
         + String(q) + ",X)");
    end if;
    T := getProp_REFPROP_check(
        "T",
        "pq",
        p,
        q,
        X,
        phase);
  end temperature_pqX;

  redeclare function temperature_psX
    "calls REFPROP-Wrapper, returns temperature"
    extends Modelica.Icons.Function;
    input Modelica.SIunits.Pressure p;
    input Modelica.SIunits.SpecificEntropy s;
    input MassFraction X[:]=reference_X "mass fraction m_NaCl/m_Sol";
    input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Modelica.SIunits.Temperature T;
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running temperature_psX(" + String(p) + ","
         + String(s) + ",X)...");
    end if;
    T := getProp_REFPROP_check(
        "T",
        "ps",
        p,
        s,
        X,
        phase);
    annotation (LateInline=true, inverse(s=specificEntropy_pTX(
              p,
              T,
              X,
              phase), p=pressure_TsX(
              T,
              s,
              X,
              phase)));
  end temperature_psX;

//   redeclare function vapourQuality "Return vapour quality"
//     input ThermodynamicState state "Thermodynamic state record";
//     output MassFraction x "Vapour quality";
//   algorithm
//     x := state.x;
//     annotation (Documentation(info="<html></html>"));
//   end vapourQuality;

  redeclare function extends specificHeatCapacityCp
  algorithm
    cp := state.cp;
  end specificHeatCapacityCp;

  redeclare function extends specificHeatCapacityCv
  algorithm
    cv := state.cv;
  end specificHeatCapacityCv;

  redeclare function extends thermalConductivity
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running thermalConductivity");
    end if;
    lambda := state.lambda;
  end thermalConductivity;

  redeclare function extends dynamicViscosity
  algorithm
    if debugmode then
      Modelica.Utilities.Streams.print("Running dynamicViscosity");
    end if;
    eta := state.eta;
  end dynamicViscosity;

  function StrJoin "Converts an Array of Strings into a string separated by |"
    input String[:] s_in;
    input String delimiter;
    output String s_out;
  algorithm
    s_out := s_in[1];
    for i in 2:size(s_in, 1) loop
      s_out := s_out + delimiter + s_in[i];
    end for;
  end StrJoin;
  annotation (Documentation(info="<html>
<p>
<b>REFPROPMedium</b> is a package that delivers <b>REFPROP</b> data to a model based on and largely compatible to the Modelica.Media library.
It can be used to model two-phase mixtures of all fluids whose data is delivered with REFPROP. It has been developed and tested only in Dymola up to 2012 FD01.
</p>
<p>
All files in this library, including the C source files are released under the Modelica License 2.
</p>
<h2>Installation</h2>
The installation basically consists in copying 2 files and changing one line in this package:
<ul>
  <li>We need access to the REFPROP.DLL and to the Fluid-Data directory in the REFPROP directory. 
  So you need to set the path to the REFPROP program directory with the constant String REFPROP_PATH (at the beginning of this parent package).
  Make sure you mask the backslashes. It should look something like
   <pre>constant String REFPROP_PATH = \"C:\\\\Program Files\\\\REFPROP\\\\\";</pre></li>
  <li>We need REFPROP_WRAPPER.LIB in %DYMOLADIR%\\BIN\\LIB\ and REFPROP_WRAPPER.H in %DYMOLADIR%\\SOURCE\\ (%DYMOLADIR% is DYMOLA's program directory)</li>
</ul>
This package needs the package PartialMixtureMediumTwoPhase which should be included in the parent package.

</p>
<h2>Usage</h2>
As it is based on Modelica.Media, the usage is little different from the usage of the two-phase water model:<br/>
Create an instance of REFPROPMedium and specify the mixture by passing the names of the medium components (medium names are the names of the .fld files in the
%REFPROP%\\fluids directory):
<pre>
  package Medium = REFPROPMedium (final substanceNames={\"nitrogen\",\"argon\"});
</pre>
Create an Instance of REFPROPMedium.Baseproperties:
<pre>
  Medium.BaseProperties props;
</pre>
You can then use the BaseProperties model to define the actual medium composition (via Xi or X), to define the thermodynamic state and calculate the corresponding properties.
<pre>
  props.p = 1e5;
  props.T = 300;
  props.Xi = {.8};
  d = props.d;
  h = props.h;
</pre>
<p>Any combination of the pressure, temperature, specific enthalpy, specific entropy and density (p,T,h,s,d) can be used to define a 
thermodynamic state. Explicit functions for all combinations exist in REFPROP and likewise in the REFPROPMedium package.
The calculation of all variables of a thermodynamic state, however, is by default done by setState_phX, so p and h have to be 
calculated from the given combination of two variables first. Actually, by doing this, REFPROP already calculates all variables 
of the thermodynamic state, but they cannot be used directly. This is a limitation of DYMOLA, as it is not able to invert a function 
returning an array.
You can change the set of variables the property model is explicit for by setting the string variable explicitVars e.g. to \"pT\" or \"dT\":
<pre>
package Medium = REFPROPMedium(final substanceNames={\"water\"}, final explicitVars = \"pT\");
</pre>
</p>
<p>All calculated values are returned in SI-Units and are mass based.
</p>
<p>Verbose mode can be switched on globally by setting the variable <i>debugmode</i> to <i>true</i>. This leads to many status messages from the modelica functions
  as well as from the compiled library. The latter only appear are only seen in only seen when the dymola.exe is run directly in the command window.


<h2>Details</h2>
  In order to take advantage of REFPROP's capability of calculating two-phase mixtures a new Medium template had to be created by merging
  Modelica.Media.Interfaces.PartialMixtureMedium and Modelica.Media.Interfaces.PartialTwoPhaseMedium of the Modelica Standard Library 3.1.
  Alternatively, there is a version of this package limited to single-substance fluids (REFPROPMediumPureSubstance) which uses the standard 
  template Modelica.Media.Interfaces.PartialTwoPhaseMedium.
  All property functions contain a definition of their inverses. So, in many cases no numerical inversion by the solver is needed because
  explicit REFPROP functions are used (meaning, numerical inversion happens in REFPROP instead).<br>
  Example: When explicitVars are set to \"ph\" and p and T are given, the specificEnthalpy is calculated first using the inverse function of 
  Temperature_phX --> specificEnthalpy_pTX. With p and h known all other variables are calculated by setstate_phX.
<p>

<p>
<ul>
</ul>
</p>


<h3> Created by</h3>
Henning Francke<br/>
Helmholtz Centre Potsdam<br/>
GFZ German Research Centre for Geosciences<br/>
Telegrafenberg, D-14473 Potsdam<br/>
Germany
<p>
<a href=mailto:francke@gfz-potsdam.de>francke@gfz-potsdam.de</a>
</html>
", revisions="<html>

</html>"));
end REFPROPMixtureTwoPhaseMedium;
