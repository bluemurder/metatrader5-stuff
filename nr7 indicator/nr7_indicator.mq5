//+------------------------------------------------------------------+
//|                                                nr7_indicator.mq5 |
//|                                               Copyright 2020, AL |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, AL"
#property link          "https://mql5.com"
#property version       "1.00"
#property description   "Marks candles with range less than the previous six"
#property description   "according to the Narrow Range 7 pattern (NR7)."
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2
//--- plot HighSize
#property indicator_label1  "HighSize"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  Magenta
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Sundays
#property indicator_label2  "Sundays"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  BlueViolet
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- enums
enum ENUM_INPUT_YES_NO
  {
   INPUT_YES   =  1,    // Yes
   INPUT_NO    =  0     // No
  };
//--- input parameters
input uint              InpLevelSize   =  20;         // Size level
input ENUM_INPUT_YES_NO InpEnableAlert =  INPUT_NO;   // Use alerts
input double InpOffset = 50.0;
//--- indicator buffers
double         BufferNR7Position[];
double         BufferSunday[];
double         BufferRange[];
//--- global variables
bool sundaysPresent = false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferNR7Position,INDICATOR_DATA); // store position of indicator
   SetIndexBuffer(1,BufferSunday,INDICATOR_DATA); // store position of indicator
   SetIndexBuffer(2,BufferRange,INDICATOR_CALCULATIONS); // store calculations of range // INDICATOR_CALCULATIONS
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,108);
   PlotIndexSetInteger(1,PLOT_ARROW,159);//108
//--- setting a indicators short name
   IndicatorSetString(INDICATOR_SHORTNAME,"Candle size alert");
//---
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
  // Set arrays as time series
  ArraySetAsSeries(BufferNR7Position,true);
  ArraySetAsSeries(BufferSunday,true);
  ArraySetAsSeries(BufferRange,true);
  ArraySetAsSeries(high,true);
  ArraySetAsSeries(low,true);
  ArraySetAsSeries(time,true);
  // Checking for minimum number of bars
  if(rates_total<8) return 0;
   
  if(NameTimeframe() != "D1") return 0;
  
  // if it's the first call
  if(prev_calculated == 0)
  {
    ArrayInitialize(BufferRange,0.0);
    ArrayInitialize(BufferNR7Position,EMPTY_VALUE);
    ArrayInitialize(BufferSunday,EMPTY_VALUE);
  }
  
  double priceMin=ChartGetDouble(0,CHART_PRICE_MIN,0);
  double priceMax=ChartGetDouble(0,CHART_PRICE_MAX,0);
  double offset = (priceMax - priceMin) / InpOffset;
  
  int start;
  if(prev_calculated==0) start=1;  // start filling out buffers from the 1st index
  else start=prev_calculated-1;    // else, set start equal to the last index in the arrays

  // evaluates all the required data  
  for(int i=start;i<rates_total;i++)
  {
    if(IsSunday(time[i]))
    {
      sundaysPresent |= true;
      BufferSunday[i]=high[i] + offset;
    }
    else
    {
      BufferRange[i] = high[i] - low[i];
    }
  }

  for(int i=start;i<rates_total;i++)
  {
  
    // ensure not out of bounds
    if(sundaysPresent)
      if(i + 7 >= rates_total) continue;
    else
      if(i + 6 >= rates_total) continue;
  
    // skip if today is Sunday
    if(BufferSunday[i] != EMPTY_VALUE) continue;
 
    // Evaluate presence of NR7 candle. If the check is against a sunday, skip that candle.
    bool found = false;
    if((BufferRange[i+1] > BufferRange[i]) || (BufferSunday[i+1] != EMPTY_VALUE))
    {
      if((BufferRange[i+2] > BufferRange[i]) || (BufferSunday[i+2] != EMPTY_VALUE))
      { 
        if((BufferRange[i+3] > BufferRange[i]) || (BufferSunday[i+3] != EMPTY_VALUE))
        {
          if((BufferRange[i+4] > BufferRange[i]) || (BufferSunday[i+4] != EMPTY_VALUE))
          {
            if((BufferRange[i+5] > BufferRange[i]) || (BufferSunday[i+5] != EMPTY_VALUE))
            {
              if((BufferRange[i+6] > BufferRange[i]) || (BufferSunday[i+6] != EMPTY_VALUE))
              {
                if(sundaysPresent)
                {
                  if((BufferRange[i+7] > BufferRange[i]) || (BufferSunday[i+7] != EMPTY_VALUE))
                  {
                    found = true;
                  }
                }
                else
                {
                  found = true;
                }
              }
            }         
          }
        } 
      }   
    }

    if(found)
    {
      if(InpEnableAlert && i==0 && BufferNR7Position[i]==EMPTY_VALUE)
        Alert(Symbol(),", ",NameTimeframe(),": Candle NR7 found!");
      BufferNR7Position[i]=high[i] + offset;
      continue;
    }
    else
      BufferNR7Position[i]=EMPTY_VALUE;
  }
  // return value of prev_calculated for next call
  return(rates_total);
}

//+------------------------------------------------------------------+
string NameTimeframe(void)
  {
   switch(Period())
     {
      case 1      : return "M1";
      case 2      : return "M2";
      case 3      : return "M3";
      case 4      : return "M4";
      case 5      : return "M5";
      case 6      : return "M6";
      case 10     : return "M10";
      case 12     : return "M12";
      case 15     : return "M15";
      case 20     : return "M20";
      case 30     : return "M30";
      case 16385  : return "H1";
      case 16386  : return "H2";
      case 16387  : return "H3";
      case 16388  : return "H4";
      case 16390  : return "H6";
      case 16392  : return "H8";
      case 16396  : return "H12";
      case 16408  : return "D1";
      case 32769  : return "W1";
      case 49153  : return "MN1";
      default     : return "Unknown Period";
     }
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSunday(datetime time)
{
  int dayofweek;
  MqlDateTime date;
  TimeToStruct(time, date);
    dayofweek = date.day_of_week;
	// day_of_week = (0-Sunday, 1-Monday, ... 6-Saturday)
	if(dayofweek == 0) 
	{
	  return true;
	}
  return false;
}

double Range(double high, double low)
{
  return high - low;
}
//+------------------------------------------------------------------+
