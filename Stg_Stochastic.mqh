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
INPUT int Stochastic_KPeriod = 5;                               // K line period
INPUT int Stochastic_DPeriod = 5;                               // D line period
INPUT int Stochastic_Slowing = 5;                               // Slowing
INPUT ENUM_MA_METHOD Stochastic_MA_Method = MODE_SMA;           // Moving Average method
INPUT ENUM_STO_PRICE Stochastic_Price_Field = 0;                // Price (0 - Low/High or 1 - Close/Close)
INPUT int Stochastic_Shift = 0;                                 // Shift (relative to the current bar)
INPUT int Stochastic_SignalOpenMethod = 0;                      // Signal open method
INPUT int Stochastic_SignalOpenLevel = 30;                      // Signal open level
INPUT int Stochastic_SignalOpenFilterMethod = 0;                // Signal open filter method
INPUT int Stochastic_SignalOpenBoostMethod = 0;                 // Signal open boost method
INPUT int Stochastic_SignalCloseMethod = 0;                     // Signal close method
INPUT int Stochastic_SignalCloseLevel = 30;                     // Signal close level
INPUT int Stochastic_PriceLimitMethod = 0;                      // Price limit method
INPUT double Stochastic_PriceLimitLevel = 0;                    // Price limit level
INPUT double Stochastic_MaxSpread = 6.0;                        // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Stochastic_Params : StgParams {
  int Stochastic_KPeriod;
  int Stochastic_DPeriod;
  int Stochastic_Slowing;
  ENUM_MA_METHOD Stochastic_MA_Method;
  ENUM_STO_PRICE Stochastic_Price_Field;
  int Stochastic_Shift;
  int Stochastic_SignalOpenMethod;
  int Stochastic_SignalOpenLevel;
  int Stochastic_SignalOpenFilterMethod;
  int Stochastic_SignalOpenBoostMethod;
  int Stochastic_SignalCloseMethod;
  int Stochastic_SignalCloseLevel;
  int Stochastic_PriceLimitMethod;
  double Stochastic_PriceLimitLevel;
  double Stochastic_MaxSpread;

  // Constructor: Set default param values.
  Stg_Stochastic_Params()
      : Stochastic_KPeriod(::Stochastic_KPeriod),
        Stochastic_DPeriod(::Stochastic_DPeriod),
        Stochastic_Slowing(::Stochastic_Slowing),
        Stochastic_MA_Method(::Stochastic_MA_Method),
        Stochastic_Price_Field(::Stochastic_Price_Field),
        Stochastic_Shift(::Stochastic_Shift),
        Stochastic_SignalOpenMethod(::Stochastic_SignalOpenMethod),
        Stochastic_SignalOpenLevel(::Stochastic_SignalOpenLevel),
        Stochastic_SignalOpenFilterMethod(::Stochastic_SignalOpenFilterMethod),
        Stochastic_SignalOpenBoostMethod(::Stochastic_SignalOpenBoostMethod),
        Stochastic_SignalCloseMethod(::Stochastic_SignalCloseMethod),
        Stochastic_SignalCloseLevel(::Stochastic_SignalCloseLevel),
        Stochastic_PriceLimitMethod(::Stochastic_PriceLimitMethod),
        Stochastic_PriceLimitLevel(::Stochastic_PriceLimitLevel),
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
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_Stochastic_Params>(_params, _tf, stg_stoch_m1, stg_stoch_m5, stg_stoch_m15, stg_stoch_m30,
                                           stg_stoch_h1, stg_stoch_h4, stg_stoch_h4);
    }
    // Initialize strategy parameters.
    StochParams stoch_params(_params.Stochastic_KPeriod, _params.Stochastic_DPeriod, _params.Stochastic_Slowing,
                             _params.Stochastic_MA_Method, _params.Stochastic_Price_Field);
    stoch_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Stochastic(stoch_params), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Stochastic_SignalOpenMethod, _params.Stochastic_SignalOpenLevel,
                       _params.Stochastic_SignalOpenFilterMethod, _params.Stochastic_SignalOpenBoostMethod,
                       _params.Stochastic_SignalCloseMethod, _params.Stochastic_SignalCloseLevel);
    sparams.SetPriceLimits(_params.Stochastic_PriceLimitMethod, _params.Stochastic_PriceLimitLevel);
    sparams.SetMaxSpread(_params.Stochastic_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Stochastic(sparams, "Stochastic");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    Indicator *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: main line falls below level and goes above the signal line.
          _result = _indi[CURR].value[LINE_MAIN] < 50 - _level &&
                    _indi[CURR].value[LINE_MAIN] > _indi[CURR].value[LINE_SIGNAL];
          if (METHOD(_method, 0)) _result &= _indi[PPREV].value[LINE_MAIN] < _indi[PPREV].value[LINE_SIGNAL];
          if (METHOD(_method, 1)) _result &= _indi[CURR].value[0] < _level;
          break;
        case ORDER_TYPE_SELL:
          // Sell: main line rises above level and main line above the signal line.
          _result = _indi[CURR].value[LINE_MAIN] > 50 + _level &&
                    _indi[CURR].value[LINE_MAIN] < _indi[CURR].value[LINE_SIGNAL];
          if (METHOD(_method, 0)) _result &= _indi[PPREV].value[LINE_MAIN] > _indi[PPREV].value[LINE_SIGNAL];
          if (METHOD(_method, 1)) _result &= _indi[CURR].value[0] > _level;
          break;
      }
    }
    return _result;
  }

  /**
   * Check strategy's opening signal additional filter.
   */
  bool SignalOpenFilter(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = true;
    if (_method != 0) {
      // if (METHOD(_method, 0)) _result &= Trade().IsTrend(_cmd);
      // if (METHOD(_method, 1)) _result &= Trade().IsPivot(_cmd);
      // if (METHOD(_method, 2)) _result &= Trade().IsPeakHours(_cmd);
      // if (METHOD(_method, 3)) _result &= Trade().IsRoundNumber(_cmd);
      // if (METHOD(_method, 4)) _result &= Trade().IsHedging(_cmd);
      // if (METHOD(_method, 5)) _result &= Trade().IsPeakBar(_cmd);
    }
    return _result;
  }

  /**
   * Gets strategy's lot size boost (when enabled).
   */
  double SignalOpenBoost(ENUM_ORDER_TYPE _cmd, int _method = 0) {
    bool _result = 1.0;
    if (_method != 0) {
      // if (METHOD(_method, 0)) if (Trade().IsTrend(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 1)) if (Trade().IsPivot(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 2)) if (Trade().IsPeakHours(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 3)) if (Trade().IsRoundNumber(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 4)) if (Trade().IsHedging(_cmd)) _result *= 1.1;
      // if (METHOD(_method, 5)) if (Trade().IsPeakBar(_cmd)) _result *= 1.1;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  double PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, double _level = 0.0) {
    Indicator *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0:
        // @todo
        break;
    }
    return _result;
  }
};
