/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Stochastic_Params_M15 : StochParams {
  Indi_Stochastic_Params_M15() : StochParams(indi_stoch_defaults, PERIOD_M15) {
    dperiod = 3;
    kperiod = 5;
    ma_method = (ENUM_MA_METHOD)0;
    price_field = (ENUM_STO_PRICE)0;
    shift = 0;
    slowing = 3;
  }
} indi_stoch_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Stochastic_Params_M15 : StgParams {
  // Struct constructor.
  Stg_Stochastic_Params_M15() : StgParams(stg_stoch_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_stoch_m15;
