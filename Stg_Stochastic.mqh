/**
 * @file
 * Implements Stochastic strategy based on the Stochastic Oscillator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Stochastic.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float Stochastic_LotSize = 0;               // Lot size
INPUT int Stochastic_SignalOpenMethod = 0;        // Signal open method
INPUT int Stochastic_SignalOpenLevel = 30;        // Signal open level
INPUT int Stochastic_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int Stochastic_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int Stochastic_SignalCloseMethod = 0;       // Signal close method
INPUT int Stochastic_SignalCloseLevel = 30;       // Signal close level
INPUT int Stochastic_PriceStopMethod = 0;         // Price stop method
INPUT float Stochastic_PriceStopLevel = 0;        // Price stop level
INPUT int Stochastic_TickFilterMethod = 0;        // Tick filter method
INPUT float Stochastic_MaxSpread = 6.0;           // Max spread to trade (pips)
INPUT int Stochastic_Shift = 0;                   // Shift (relative to the current bar)
INPUT string __Stochastic_Indi_Stochastic_Parameters__ =
    "-- Stochastic strategy: Stochastic indicator params --";  // >>> Stochastic strategy: Stochastic indicator <<<
INPUT int Indi_Stochastic_KPeriod = 5;                         // K line period
INPUT int Indi_Stochastic_DPeriod = 5;                         // D line period
INPUT int Indi_Stochastic_Slowing = 5;                         // Slowing
INPUT ENUM_MA_METHOD Indi_Stochastic_MA_Method = MODE_SMA;     // Moving Average method
INPUT ENUM_STO_PRICE Indi_Stochastic_Price_Field = 0;          // Price (0 - Low/High or 1 - Close/Close)

// Structs.

// Defines struct with default user indicator values.
struct Indi_Stochastic_Params_Defaults : StochParams {
  Indi_Stochastic_Params_Defaults()
      : StochParams(::Indi_Stochastic_KPeriod, ::Indi_Stochastic_DPeriod, ::Indi_Stochastic_Slowing,
                    ::Indi_Stochastic_MA_Method, ::Indi_Stochastic_Price_Field) {}
} indi_stoch_defaults;

// Defines struct to store indicator parameter values.
struct Indi_Stochastic_Params : public StochParams {
  // Struct constructors.
  void Indi_Stochastic_Params(StochParams &_params, ENUM_TIMEFRAMES _tf) : StochParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_Stochastic_Params_Defaults : StgParams {
  Stg_Stochastic_Params_Defaults()
      : StgParams(::Stochastic_SignalOpenMethod, ::Stochastic_SignalOpenFilterMethod, ::Stochastic_SignalOpenLevel,
                  ::Stochastic_SignalOpenBoostMethod, ::Stochastic_SignalCloseMethod, ::Stochastic_SignalCloseLevel,
                  ::Stochastic_PriceStopMethod, ::Stochastic_PriceStopLevel, ::Stochastic_TickFilterMethod,
                  ::Stochastic_MaxSpread, ::Stochastic_Shift) {}
} stg_stoch_defaults;

// Struct to define strategy parameters to override.
struct Stg_Stochastic_Params : StgParams {
  Indi_Stochastic_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_Stochastic_Params(Indi_Stochastic_Params &_iparams, StgParams &_sparams)
      : iparams(indi_stoch_defaults, _iparams.tf), sparams(stg_stoch_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Stochastic : public Strategy {
 public:
  Stg_Stochastic(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Stochastic *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_Stochastic_Params _indi_params(indi_stoch_defaults, _tf);
    StgParams _stg_params(stg_stoch_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_Stochastic_Params>(_indi_params, _tf, indi_stoch_m1, indi_stoch_m5, indi_stoch_m15,
                                            indi_stoch_m30, indi_stoch_h1, indi_stoch_h4, indi_stoch_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_stoch_m1, stg_stoch_m5, stg_stoch_m15, stg_stoch_m30, stg_stoch_h1,
                               stg_stoch_h4, stg_stoch_h8);
    }
    // Initialize indicator.
    StochParams stoch_params(_indi_params);
    _stg_params.SetIndicator(new Indi_Stochastic(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Stochastic(_stg_params, "Stochastic");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_Stochastic *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: main line falls below level and goes above the signal line.
          _result = _indi[CURR][LINE_MAIN] < 50 - _level && _indi[CURR][LINE_MAIN] > _indi[CURR][LINE_SIGNAL];
          if (METHOD(_method, 0)) _result &= _indi[PPREV][LINE_MAIN] < _indi[PPREV][LINE_SIGNAL];
          if (METHOD(_method, 1)) _result &= _indi[CURR][0] < _level;
          break;
        case ORDER_TYPE_SELL:
          // Sell: main line rises above level and main line above the signal line.
          _result = _indi[CURR][LINE_MAIN] > 50 + _level && _indi[CURR][LINE_MAIN] < _indi[CURR][LINE_SIGNAL];
          if (METHOD(_method, 0)) _result &= _indi[PPREV][LINE_MAIN] > _indi[PPREV][LINE_SIGNAL];
          if (METHOD(_method, 1)) _result &= _indi[CURR][0] > _level;
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_Stochastic *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 1: {
          int _bar_count0 = (int)_level * (int)_indi.GetKPeriod();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count0))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count0));
          break;
        }
        case 2: {
          int _bar_count1 = (int)_level * (int)_indi.GetDPeriod();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count1))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count1));
          break;
        }
        case 3: {
          int _bar_count2 = (int)_level * (int)_indi.GetSlowing();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count2))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count2));
          break;
        }
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
