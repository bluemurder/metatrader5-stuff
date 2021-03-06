﻿//+------------------------------------------------------------------+
//|                                                    bigshadow.mq5 |
//|                                       Copyright © 2018, zebedeig |
//|                                https://www.technologytourist.com |
//+------------------------------------------------------------------+

// Author
#property copyright "Copyright © 2018, zebedeig"
// Link to author's site
#property link      "https://www.technologytourist.com"
// Indicator version
#property version   "1.00"
// Draw the indicator in the main window
#property indicator_chart_window 
// To calculate and draw the indicator use three buffers
#property indicator_buffers 3
// Only two graphic constructions are used
#property indicator_plots   2

//+----------------------------------------------+
//|  Parameters of the bearish indicator         |
//+----------------------------------------------+
// Draw the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
// Color of the bearish indicator is orange
#property indicator_color1  clrOrange
// Thickness of the indicator 1 is 2
#property indicator_width1  2
// Bullish indicator label
#property indicator_label1 "Bearish big shadow"

//+----------------------------------------------+
//|  Parameters of the bullish indicator         |
//+----------------------------------------------+
// Draw the indicator 2 as a symbol
#property indicator_type2   DRAW_ARROW
// Color of the bearish indicator is blue
#property indicator_color2  clrBlue
// Thickness of the indicator 2 is 2
#property indicator_width2  2
// Bearish indicator label
#property indicator_label2 "Bearish big shadow"

//+----------------------------------------------+
//|  Constants                                   |
//+----------------------------------------------+
// Constant for returning to the terminal the command to recalculate the indicator
#define RESET  0 

//+----------------------------------------------+
//| Input parameters                             |
//+----------------------------------------------+
input double tolerance = 0.1; // Tolerance on big shadow candle high/low. 0.1 = 10%
input double position = 1; // Shift arrows (up or down) of such percentage of the range of a candle. 1 = 100%

//+----------------------------------------------+
// Declaration of dynamic arrays, used as indicator buffers
double SellBuffer[], BuyBuffer[], Table_value2[];
// Minimum number of bars needed to perform indicator evaluations
int min_rates_total;
// Range of the big shadow candle
double candleRange;
// Average range of last 10 candles
double AvgRange;
// Counter declared here for performance purpose
int counter;
// Marker position
double markerPosition;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
  // Global variables
  min_rates_total = 12;
  // Transformation of a dynamic array into an indicator buffer
  SetIndexBuffer(0, SellBuffer, INDICATOR_DATA);
  // Shift of the origin of the indicator 1
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, min_rates_total);
  // Symbol for the indicator
  PlotIndexSetInteger(0, PLOT_ARROW, 234);
  // Indexing of elements in the buffer as in the timeseries
  ArraySetAsSeries(SellBuffer, true);
  // Transformation of a dynamic array into an indicator buffer
  SetIndexBuffer(1, BuyBuffer, INDICATOR_DATA);
  // Shift of the origin of the indicator 2
  PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, min_rates_total);
  // Symbol for the indicator
  PlotIndexSetInteger(1, PLOT_ARROW, 233);
  // indexing of elements in the buffer as in the timeseries
  ArraySetAsSeries(BuyBuffer, true);
  // transformation of a dynamic array into an indicator buffer
  SetIndexBuffer(2, Table_value2, INDICATOR_CALCULATIONS);
  // indexing of elements in the buffer as in the timeseries
  ArraySetAsSeries(Table_value2, true);
  // Setting the display accuracy format
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
  // Name for data windows and a label for the sub-window
  string short_name = "Big shadow";
  IndicatorSetString(INDICATOR_SHORTNAME, short_name);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
  // Checking the number of bars for sufficiency for calculating
  if(rates_total < min_rates_total) return(RESET);

  // Declarations of local variables 
  int limit, bar;

  // Calculations of the required number of copied data and the limit start number for the bar recalculation cycle

  if((prev_calculated > rates_total) || (prev_calculated <= 0))// check for the first start of calculating the indicator
  {
    limit = rates_total - min_rates_total; // starting number for calculating all bars
    for(bar = rates_total - 1; bar >= 0 && !IsStopped(); bar--) Table_value2[bar] = NULL;
  }
  else
  {
    limit = rates_total - prev_calculated; // starting number for calculating new bars
  }

  // indexing of elements in arrays as in timeseries  
  ArraySetAsSeries(open, true);
  ArraySetAsSeries(close, true);
  ArraySetAsSeries(high, true);
  ArraySetAsSeries(low, true);

  // basic cycle of calculating the indicator
  for(bar = limit; bar >= 0 && !IsStopped(); bar--)
  {
    Table_value2[bar] = NULL;
    BuyBuffer[bar] = NULL;
    SellBuffer[bar] = NULL;

    // Check if current candle is a big shadow candidate
    // The tolerance factor applies a smooth constraint on the dimensions of the big shadow candle
    // Possible big candles:
    // - If the high of second candle is higher than high of first candle AND low is lower than lower of first candle 
    candleRange = high[bar] - low[bar];
    if(
       ((high[bar] > high[bar + 1]) && (low[bar] < (low[bar + 1] + tolerance * candleRange))) ||
       ((high[bar] > (high[bar + 1] - tolerance * candleRange)) && (low[bar] < low[bar + 1]))
      )
    {
      // Bullish or bearish?
      if(open[bar] < close[bar] && open[bar + 1] > close[bar + 1])
      {
        Table_value2[bar] = 1;
      }
      else if(open[bar] > close[bar] && open[bar + 1] < close[bar + 1])
      {
        Table_value2[bar] = -1;
      }
    }

    // Graphics

    // Evaluate average range
    AvgRange = 0.0;
    for(counter = bar + 9; counter >= bar; counter--)
    {
      AvgRange += MathAbs(high[counter] - low[counter]);
    }
    AvgRange = AvgRange / 10.0;

    // Evaluate position of the marker
    if(Table_value2[bar] == 1)
    {
      BuyBuffer[bar] = high[bar] + position * AvgRange;
    }
    else if(Table_value2[bar] == -1)
    {
      SellBuffer[bar] = low[bar] - position * AvgRange;
    }
  }

  // End of indicator evaluation
  return(rates_total);
}
//+------------------------------------------------------------------+
