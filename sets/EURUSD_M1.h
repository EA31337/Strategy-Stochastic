//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Stochastic_EURUSD_M1_Params : Stg_Stochastic_Params {
  Stg_Stochastic_EURUSD_M1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M1;
    Stochastic_Period = 32;
    Stochastic_Applied_Price = 3;
    Stochastic_Shift = 0;
    Stochastic_TrailingStopMethod = 6;
    Stochastic_TrailingProfitMethod = 11;
    Stochastic_SignalOpenLevel = 36;
    Stochastic_SignalBaseMethod = 0;
    Stochastic_SignalOpenMethod1 = 0;
    Stochastic_SignalOpenMethod2 = 0;
    Stochastic_SignalCloseLevel = 36;
    Stochastic_SignalCloseMethod1 = 0;
    Stochastic_SignalCloseMethod2 = 0;
    Stochastic_MaxSpread = 2;
  }
};
