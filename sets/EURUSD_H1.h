//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Stochastic_EURUSD_H1_Params : Stg_Stochastic_Params {
  Stg_Stochastic_EURUSD_H1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H1;
    Stochastic_Period = 2;
    Stochastic_Applied_Price = 3;
    Stochastic_Shift = 0;
    Stochastic_SignalOpenMethod = 0;
    Stochastic_SignalOpenLevel = 36;
    Stochastic_SignalCloseMethod = 1;
    Stochastic_SignalCloseLevel = 36;
    Stochastic_PriceLimitMethod = 0;
    Stochastic_PriceLimitLevel = 0;
    Stochastic_MaxSpread = 6;
  }
};
