//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements Stochastic strategy based on the Stochastic Oscillator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Stochastic.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __Stochastic_Parameters__ = "-- Settings for --";  // >>> STOCHASTIC <<<
INPUT int Stochastic_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT int Stochastic_KPeriod = 5;    // K line period
INPUT int Stochastic_DPeriod = 5;    // D line period
INPUT int Stochastic_Slowing = 5;    // Slowing
INPUT ENUM_MA_METHOD Stochastic_MA_Method = MODE_SMA;                        // Moving Average method
INPUT ENUM_STO_PRICE Stochastic_Price_Field = 0;                             // Price (0 - Low/High or 1 - Close/Close)
INPUT int Stochastic_Shift = 0;                                              // Shift (relative to the current bar)
INPUT ENUM_TRAIL_TYPE Stochastic_TrailingStopMethod = 22;                    // Trail stop method
INPUT ENUM_TRAIL_TYPE Stochastic_TrailingProfitMethod = 1;                   // Trail profit method
INPUT double Stochastic_SignalOpenLevel = 0.00000000;                        // Signal open level
INPUT int Stochastic1_SignalBaseMethod = 0;                                  // Signal base method (0-
INPUT int Stochastic1_OpenCondition1 = 0;                                    // Open condition 1 (0-1023)
INPUT int Stochastic1_OpenCondition2 = 0;                                    // Open condition 2 (0-)
INPUT ENUM_MARKET_EVENT Stochastic1_CloseCondition = C_STOCHASTIC_BUY_SELL;  // Close condition for M1
INPUT double Stochastic_MaxSpread = 6.0;                                     // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Stochastic_Params : Stg_Params {
  unsigned int Stochastic_Period;
  ENUM_APPLIED_PRICE Stochastic_Applied_Price;
  int Stochastic_Shift;
  ENUM_TRAIL_TYPE Stochastic_TrailingStopMethod;
  ENUM_TRAIL_TYPE Stochastic_TrailingProfitMethod;
  double Stochastic_SignalOpenLevel;
  long Stochastic_SignalBaseMethod;
  long Stochastic_SignalOpenMethod1;
  long Stochastic_SignalOpenMethod2;
  double Stochastic_SignalCloseLevel;
  ENUM_MARKET_EVENT Stochastic_SignalCloseMethod1;
  ENUM_MARKET_EVENT Stochastic_SignalCloseMethod2;
  double Stochastic_MaxSpread;

  // Constructor: Set default param values.
  Stg_Stochastic_Params()
      : Stochastic_Period(::Stochastic_Period),
        Stochastic_Applied_Price(::Stochastic_Applied_Price),
        Stochastic_Shift(::Stochastic_Shift),
        Stochastic_TrailingStopMethod(::Stochastic_TrailingStopMethod),
        Stochastic_TrailingProfitMethod(::Stochastic_TrailingProfitMethod),
        Stochastic_SignalOpenLevel(::Stochastic_SignalOpenLevel),
        Stochastic_SignalBaseMethod(::Stochastic_SignalBaseMethod),
        Stochastic_SignalOpenMethod1(::Stochastic_SignalOpenMethod1),
        Stochastic_SignalOpenMethod2(::Stochastic_SignalOpenMethod2),
        Stochastic_SignalCloseLevel(::Stochastic_SignalCloseLevel),
        Stochastic_SignalCloseMethod1(::Stochastic_SignalCloseMethod1),
        Stochastic_SignalCloseMethod2(::Stochastic_SignalCloseMethod2),
        Stochastic_MaxSpread(::Stochastic_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_Stochastic : public Strategy {
 public:
  Stg_Stochastic(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Stochastic *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_Stochastic_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_Stochastic_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_Stochastic_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_Stochastic_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_Stochastic_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_Stochastic_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_Stochastic_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    Stochastic_Params adx_params(_params.Stochastic_Period, _params.Stochastic_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_Stochastic);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Stochastic(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Stochastic_SignalBaseMethod, _params.Stochastic_SignalOpenMethod1,
                       _params.Stochastic_SignalOpenMethod2, _params.Stochastic_SignalCloseMethod1,
                       _params.Stochastic_SignalCloseMethod2, _params.Stochastic_SignalOpenLevel,
                       _params.Stochastic_SignalCloseLevel);
    sparams.SetStops(_params.Stochastic_TrailingProfitMethod, _params.Stochastic_TrailingStopMethod);
    sparams.SetMaxSpread(_params.Stochastic_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Stochastic(sparams, "Stochastic");
    return _strat;
  }

  /**
   * Check if Stochastic indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double stoch_0 = ((Indi_Stochastic *)this.Data()).GetValue(0);
    double stoch_1 = ((Indi_Stochastic *)this.Data()).GetValue(1);
    double stoch_2 = ((Indi_Stochastic *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
        /* TODO:
              // if(iStochastic(NULL,0,5,3,3,MODE_SMA,0,LINE_MAIN,0)>iStochastic(NULL,0,5,3,3,MODE_SMA,0,LINE_SIGNAL,0))
           return(0);
              // if(stoch4h<stoch4h2){ //Sell signal
              // if(stoch4h>stoch4h2){//Buy signal

              //28. Stochastic Oscillator (1)
              //Buy: main lline rises above 20 after it fell below this point
              //Sell: main line falls lower than 80 after it rose above this point
              if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_MAIN,1)<20
              &&iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_MAIN,0)>=20)
              {f28=1;}
              if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_MAIN,1)>80
              &&iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_MAIN,0)<=80)
              {f28=-1;}

              //29. Stochastic Oscillator (2)
              //Buy: main line goes above the signal line
              //Sell: signal line goes above the main line
              if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_MAIN,1)<iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_SIGNAL,1)
              &&
           iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_MAIN,0)>=iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_SIGNAL,0))
              {f29=1;}
              if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_MAIN,1)>iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_SIGNAL,1)
              &&
           iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_MAIN,0)<=iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,LINE_SIGNAL,0))
              {f29=-1;}
        */
      case ORDER_TYPE_BUY:
        /*
          bool _result = Stochastic_0[LINE_LOWER] != 0.0 || Stochastic_1[LINE_LOWER] != 0.0 || Stochastic_2[LINE_LOWER]
          != 0.0; if (METHOD(_signal_method, 0)) _result &= Open[CURR] > Close[CURR]; if (METHOD(_signal_method, 1))
          _result &= !Stochastic_On_Sell(tf); if (METHOD(_signal_method, 2)) _result &= Stochastic_On_Buy(fmin(period +
          1, M30)); if (METHOD(_signal_method, 3)) _result &= Stochastic_On_Buy(M30); if (METHOD(_signal_method, 4))
          _result &= Stochastic_2[LINE_LOWER] != 0.0; if (METHOD(_signal_method, 5)) _result &=
          !Stochastic_On_Sell(M30);
          */
        break;
      case ORDER_TYPE_SELL:
        /*
          bool _result = Stochastic_0[LINE_UPPER] != 0.0 || Stochastic_1[LINE_UPPER] != 0.0 || Stochastic_2[LINE_UPPER]
          != 0.0; if (METHOD(_signal_method, 0)) _result &= Open[CURR] < Close[CURR]; if (METHOD(_signal_method, 1))
          _result &= !Stochastic_On_Buy(tf); if (METHOD(_signal_method, 2)) _result &= Stochastic_On_Sell(fmin(period +
          1, M30)); if (METHOD(_signal_method, 3)) _result &= Stochastic_On_Sell(M30); if (METHOD(_signal_method, 4))
          _result &= Stochastic_2[LINE_UPPER] != 0.0; if (METHOD(_signal_method, 5)) _result &= !Stochastic_On_Buy(M30);
          */
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
