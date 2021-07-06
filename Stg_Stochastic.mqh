/**
 * @file
 * Implements Stochastic strategy based on the Stochastic Oscillator.
 */

// User input params.
INPUT string __Stochastic_Parameters__ = "-- Stochastic strategy params --";  // >>> Stochastic <<<
INPUT float Stochastic_LotSize = 0;                                           // Lot size
INPUT int Stochastic_SignalOpenMethod = 2;                                    // Signal open method
INPUT int Stochastic_SignalOpenLevel = 0.0f;                                  // Signal open level
INPUT int Stochastic_SignalOpenFilterMethod = 32;                             // Signal open filter method
INPUT int Stochastic_SignalOpenBoostMethod = 0;                               // Signal open boost method
INPUT int Stochastic_SignalCloseMethod = 2;                                   // Signal close method
INPUT int Stochastic_SignalCloseLevel = 0.0f;                                 // Signal close level
INPUT int Stochastic_PriceStopMethod = 1;                                     // Price stop method
INPUT float Stochastic_PriceStopLevel = 0;                                    // Price stop level
INPUT int Stochastic_TickFilterMethod = 1;                                    // Tick filter method
INPUT float Stochastic_MaxSpread = 4.0;                                       // Max spread to trade (pips)
INPUT short Stochastic_Shift = 0;                                             // Shift (relative to the current bar)
INPUT int Stochastic_OrderCloseTime = -20;  // Order close time in mins (>0) or bars (<0)
INPUT string __Stochastic_Indi_Stochastic_Parameters__ =
    "-- Stochastic strategy: Stochastic indicator params --";  // >>> Stochastic strategy: Stochastic indicator <<<
INPUT int Stochastic_Indi_Stochastic_KPeriod = 5;              // K line period
INPUT int Stochastic_Indi_Stochastic_DPeriod = 3;              // D line period
INPUT int Stochastic_Indi_Stochastic_Slowing = 3;              // Slowing
INPUT ENUM_MA_METHOD Stochastic_Indi_Stochastic_MA_Method = MODE_SMA;  // Moving Average method
INPUT ENUM_STO_PRICE Stochastic_Indi_Stochastic_Price_Field = 0;       // Price (0 - Low/High or 1 - Close/Close)
INPUT int Stochastic_Indi_Stochastic_Shift = 0;                        // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_Stochastic_Params_Defaults : StochParams {
  Indi_Stochastic_Params_Defaults()
      : StochParams(::Stochastic_Indi_Stochastic_KPeriod, ::Stochastic_Indi_Stochastic_DPeriod,
                    ::Stochastic_Indi_Stochastic_Slowing, ::Stochastic_Indi_Stochastic_MA_Method,
                    ::Stochastic_Indi_Stochastic_Price_Field, ::Stochastic_Indi_Stochastic_Shift) {}
} indi_stoch_defaults;

// Defines struct with default user strategy values.
struct Stg_Stochastic_Params_Defaults : StgParams {
  Stg_Stochastic_Params_Defaults()
      : StgParams(::Stochastic_SignalOpenMethod, ::Stochastic_SignalOpenFilterMethod, ::Stochastic_SignalOpenLevel,
                  ::Stochastic_SignalOpenBoostMethod, ::Stochastic_SignalCloseMethod, ::Stochastic_SignalCloseLevel,
                  ::Stochastic_PriceStopMethod, ::Stochastic_PriceStopLevel, ::Stochastic_TickFilterMethod,
                  ::Stochastic_MaxSpread, ::Stochastic_Shift, ::Stochastic_OrderCloseTime) {}
} stg_stoch_defaults;

// Struct to define strategy parameters to override.
struct Stg_Stochastic_Params : StgParams {
  StochParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_Stochastic_Params(StochParams &_iparams, StgParams &_sparams)
      : iparams(indi_stoch_defaults, _iparams.tf.GetTf()), sparams(stg_stoch_defaults) {
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
  Stg_Stochastic(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Stochastic *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    StochParams _indi_params(indi_stoch_defaults, _tf);
    StgParams _stg_params(stg_stoch_defaults);
#ifdef __config__
    SetParamsByTf<StochParams>(_indi_params, _tf, indi_stoch_m1, indi_stoch_m5, indi_stoch_m15, indi_stoch_m30,
                               indi_stoch_h1, indi_stoch_h4, indi_stoch_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_stoch_m1, stg_stoch_m5, stg_stoch_m15, stg_stoch_m30, stg_stoch_h1,
                             stg_stoch_h4, stg_stoch_h8);
#endif
    // Initialize indicator.
    StochParams stoch_params(_indi_params);
    _stg_params.SetIndicator(new Indi_Stochastic(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_Stochastic(_stg_params, _tparams, _cparams, "Stochastic");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_Stochastic *_indi = GetIndicator();
    bool _is_valid = _indi[_shift].IsValid() && _indi[_shift + 1].IsValid() && _indi[_shift + 2].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      IndicatorSignal _signals = _indi.GetSignals(4, _shift, LINE_MAIN, LINE_SIGNAL);
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy: main line falls below level and goes above the signal line.
          _result &= _indi.GetMin<double>(_shift, 4) < 50 - _level;
          _result &= _indi[_shift][(int)LINE_SIGNAL] < _indi[_shift][(int)LINE_MAIN];
          _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
          break;
        case ORDER_TYPE_SELL:
          // Sell: main line rises above level and main line above the signal line.
          _result &= _indi.GetMin<double>(_shift, 4) > 50 + _level;
          _result &= _indi[_shift][(int)LINE_SIGNAL] > _indi[_shift][(int)LINE_MAIN];
          _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
          break;
      }
    }
    return _result;
  }
};
