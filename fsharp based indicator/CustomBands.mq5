//+------------------------------------------------------------------+
//|                                                  CustomBands.mq5 |
//|                                 Copyright 2016, Alessio Leoncini |
//|                                             https://www.mql5.com |
//|       Original code: https://github.com/callmekohei/MetaTraderFs |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Alessio Leoncini"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5

double ema10Buffer[];
double sma13Buffer[];
double ema25Buffer[];
double ExtUpperBuffer[];
double ExtLowerBuffer[];

#import "mt5lib.dll"

   void BandsCustomed (
      double &array[],
      int    arraySize,
      int    prev,
      double &ema10Buf[],
      double &sma13Buf[],
      double &ema25Buf[],
      double &upperBuf[],
      double &lowerBuf[] );
      
#import 

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   SetIndexBuffer(0, ema10Buffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrAquamarine);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 1);
   PlotIndexSetString(0, PLOT_LABEL, "EMA10"); 
   
   SetIndexBuffer(1, sma13Buffer, INDICATOR_DATA);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrYellow);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 1);
   PlotIndexSetString(1, PLOT_LABEL, "SMA13"); 
   
   SetIndexBuffer(2, ema25Buffer, INDICATOR_DATA);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(2, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrRed);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, 1);
   PlotIndexSetString(2, PLOT_LABEL, "EMA25"); 
   
   SetIndexBuffer(3, ExtUpperBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(3, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, clrSienna);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, 1);
   PlotIndexSetString(3, PLOT_LABEL, "BUP"); 
  
   SetIndexBuffer(4, ExtLowerBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(4, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, clrSienna);
   PlotIndexSetInteger(4, PLOT_LINE_WIDTH, 1);
   PlotIndexSetString(4, PLOT_LABEL, "BLOW"); 

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int      rates_total,
                const int      prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
   // Counting from 0 to rates_total
   ArraySetAsSeries(ema10Buffer, false);
   ArraySetAsSeries(sma13Buffer, false);
   ArraySetAsSeries(ema25Buffer, false);
   ArraySetAsSeries(ExtUpperBuffer, false);
   ArraySetAsSeries(ExtLowerBuffer, false);
   ArraySetAsSeries(close, false);

   // Initial zero
   int i;
   if(prev_calculated<1)
   {
      for(i=0; i<10; i++)
      {
         ema10Buffer[i] = EMPTY_VALUE;
      }

      for(i=0; i<13; i++)
      {
         sma13Buffer[i] = EMPTY_VALUE;
      }

      for(i=0; i<25; i++)
      {
         ema25Buffer[i]    = EMPTY_VALUE;
         ExtUpperBuffer[i] = EMPTY_VALUE;
         ExtLowerBuffer[i] = EMPTY_VALUE;
      }
   }

   // Clone array of close prices
   double myClose[];
   ArraySetAsSeries (myClose, false);
   int bars = Bars(_Symbol, _Period); 
   ArrayResize(myClose, bars);
   for(int j = 0; j < bars; j++)
   {
         myClose[j] = close[j];
   }

   // DLL function
   BandsCustomed(
      myClose,
      ArraySize(myClose),
      prev_calculated,
      ema10Buffer,
      sma13Buffer,
      ema25Buffer,
      ExtUpperBuffer,
      ExtLowerBuffer );

   return(rates_total);
}