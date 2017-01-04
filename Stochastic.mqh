//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of Stochastic strategy based on the Stochastic Oscillator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iStochastic
 * - https://www.mql5.com/en/docs/indicators/iStochastic
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __Stochastic_Parameters__ = "-- Settings for the Stochastic Oscillator --"; // >>> STOCHASTIC <<<
#ifdef __input__ input #endif double Stochastic_SignalLevel = 0.00000000; // Signal level
#ifdef __input__ input #endif int Stochastic_SignalMethod = 0; // Signal method for M1 (0-

class Stochastic: public Strategy {
protected:

  double stochastic[H1][FINAL_ENUM_INDICATOR_INDEX][FINAL_SLINE_ENTRY];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

    public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Stochastic Oscillator.
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      stochastic[index][i][MODE_MAIN]   = iStochastic(symbol, PERIOD_H1, 15, 9, 9, MODE_EMA, 0, MODE_MAIN, i);
      stochastic[index][i][MODE_SIGNAL] = iStochastic(symbol, PERIOD_H1, 15, 9, 9, MODE_EMA, 0, MODE_SIGNAL, i);
    }
    if (VerboseDebug) PrintFormat("Stochastic M%d: %s", tf, Arrays::ArrToString3D(stochastic, ",", Digits));
    success = stochastic[index][CURR][MODE_MAIN];
  }

  /**
   * Checks whether signal is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_STOCHASTIC, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_STOCHASTIC, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_STOCHASTIC, tf, 0.0);
    switch (cmd) {
        /* TODO:
              //   if(iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0)>iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0)) return(0);
              // if(stoch4h<stoch4h2){ //Sell signal
              // if(stoch4h>stoch4h2){//Buy signal

              //28. Stochastic Oscillator (1)
              //Buy: main lline rises above 20 after it fell below this point
              //Sell: main line falls lower than 80 after it rose above this point
              if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,1)<20
              &&iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,0)>=20)
              {f28=1;}
              if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,1)>80
              &&iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,0)<=80)
              {f28=-1;}

              //29. Stochastic Oscillator (2)
              //Buy: main line goes above the signal line
              //Sell: signal line goes above the main line
              if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,1)<iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_SIGNAL,1)
              && iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,0)>=iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_SIGNAL,0))
              {f29=1;}
              if(iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,1)>iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_SIGNAL,1)
              && iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_MAIN,0)<=iStochastic(NULL,pisto,pistok,pistod,istslow,MODE_EMA,0,MODE_SIGNAL,0))
              {f29=-1;}
        */
      case OP_BUY:
        /*
          bool result = Stochastic[period][CURR][LOWER] != 0.0 || Stochastic[period][PREV][LOWER] != 0.0 || Stochastic[period][FAR][LOWER] != 0.0;
          if ((signal_method &   1) != 0) result &= Open[CURR] > Close[CURR];
          if ((signal_method &   2) != 0) result &= !Stochastic_On_Sell(tf);
          if ((signal_method &   4) != 0) result &= Stochastic_On_Buy(fmin(period + 1, M30));
          if ((signal_method &   8) != 0) result &= Stochastic_On_Buy(M30);
          if ((signal_method &  16) != 0) result &= Stochastic[period][FAR][LOWER] != 0.0;
          if ((signal_method &  32) != 0) result &= !Stochastic_On_Sell(M30);
          */
      break;
      case OP_SELL:
        /*
          bool result = Stochastic[period][CURR][UPPER] != 0.0 || Stochastic[period][PREV][UPPER] != 0.0 || Stochastic[period][FAR][UPPER] != 0.0;
          if ((signal_method &   1) != 0) result &= Open[CURR] < Close[CURR];
          if ((signal_method &   2) != 0) result &= !Stochastic_On_Buy(tf);
          if ((signal_method &   4) != 0) result &= Stochastic_On_Sell(fmin(period + 1, M30));
          if ((signal_method &   8) != 0) result &= Stochastic_On_Sell(M30);
          if ((signal_method &  16) != 0) result &= Stochastic[period][FAR][UPPER] != 0.0;
          if ((signal_method &  32) != 0) result &= !Stochastic_On_Buy(M30);
          */
      break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    return result;
  }
};
