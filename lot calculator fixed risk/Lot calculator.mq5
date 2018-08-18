//+------------------------------------------------------------------+
//|                                               Lot Calculator.mq5 |
//|                                         Copyleft 2018, zebedeig |
//|                           https://www.mql5.com/en/users/zebedeig |
//+------------------------------------------------------------------+

#property copyright    "Copyleft 2018, by zebedeig"
#property link         "https://www.mql5.com/en/users/zebedeig"
#property version      "1.00"
#property description  "Tool used to calculate the correct lot size to trade, given a fixed risk"
#property description  " and a number of pips."
#property description  "Simply enter the number of pips of your desired stop loss order, and the"
#property description  " indicator will show you the number of lots to trade based on your"
#property description  " total account amount, your account currency and present chart currency"
#property description  " pair."

#property strict
#property indicator_chart_window
#property indicator_plots 0

#define MODE_TICKVALUE 
#define MODE_TICKSIZE 
#define MODE_DIGITS
#define KEY_F 70
#define KEY_CTRL 17

int Pips = 165; // Stop loss distance from open order
input double Risk = 0.02; // Free margin fraction you want to risk for the trade
input bool useTrueAccountBalance = true; // Check to read the actual free margin of your balance, uncheck to specify it
input int SimulatedAccountBalance = 2000; // Specify here a simulated balance value 
double point; // Used to handle the correct digits number
double firstPrice = 0.; // Used to set Pips value by clicking on the chart
double secondPrice = 0.; // Used to set Pips value by clicking on the chart
bool setPipsWithMouse = false; // Flag to enable setting Pips value by clicking on the chart
int pipsMultiplier = 1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
  // Enable CHART_EVENT_MOUSE_MOVE messages 
  ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1); 
  // Forced updating of chart properties ensures readiness for event processing 
  ChartRedraw(); 

  // Broker digits
  point = _Point;

  if((_Digits == 3) || (_Digits == 5))
  {
    point *= 10;
  }
  else
  {
    pipsMultiplier *= 10;
  }
  
  // pipsMultiplier is 10 ^ (_Digits - 1) if _Digits is 3 or 5,
  // or 10^_Digits otherwise
  for(int i = 0; i < _Digits-1; ++i)
  {
    pipsMultiplier *= 10;
  }
  
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator de-init function                         |
//+------------------------------------------------------------------+  
void OnDeinit(const int reason)
{
  Comment("");  // Cleanup
  Print(__FUNCTION__,"_UninitReason = ",getUninitReasonText(_UninitReason));
  return;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function (callback)                   |
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
                const int &spread[]
                )
{
  DoWork();
  return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function (called by main indicator    |
//| callback and mouse events handler)                               |
//+------------------------------------------------------------------+
void DoWork()
{
  string DepositCurrency = AccountInfoString(ACCOUNT_CURRENCY);
  
  double freeMargin = 0;

  // Evaluate free margin
  if(useTrueAccountBalance)
  {
    freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
  }
  else
  {
    freeMargin = SimulatedAccountBalance;
  }
  
  // Check possible errors
  if(freeMargin <= 0)
  {
    Comment("Unable to get free margin value...");
    return;
  }

  double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
  if(tickSize <= 0)
  {
    Comment("Unable to get tick size value...");
    return;
  }
  
  double pipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE)) * point) / tickSize);
  if(pipValue <= 0)
  {
    Comment("Unable to get pip value...");
    return;
  }

  // Check if point-and-click issue determined zero pips
  if(Pips <= 0)
  {
    Comment("Invalid 'Pips' value. Use crosshair again.");
    return;
  }

  double lots = Risk * freeMargin / (pipValue * Pips);
  if(lots <= 0)
  {
    Comment("Unable to get lot value...");
    return;
  }

  // Truncate lot quantity to 2 decimal digits without rounding it
  lots = floor(lots * 100) / 100;

  string CommentString = "\n" + "Your free margin: "+ DepositCurrency + " " + DoubleToString(freeMargin, 2) + "\n";
  CommentString += "Risk selected: " + DoubleToString(Risk * 100, 0) + "%\n";
  CommentString += "Risk selected: " + DepositCurrency + " " + DoubleToString(Risk * freeMargin, 2) + "\n";
  CommentString += "-----------------------------------------------------------------\n";
  CommentString += "Value of one pip trading 1 lot of " + Symbol() + ": " + DepositCurrency + " " + DoubleToString(pipValue, 3) + "\n";
  CommentString += "Max lots of " + Symbol() + " to trade while risking " + IntegerToString(Pips) + " pips: " + DoubleToString(lots, 2) + "\n";
  CommentString += "-----------------------------------------------------------------\n";

  Comment(CommentString);
}

//+------------------------------------------------------------------+
//| Print details when indicator stops working                       |
//+------------------------------------------------------------------+
string getUninitReasonText(int reasonCode) // Return reason for De-init function
{
  string text="";

  switch(reasonCode)
  {
  case REASON_ACCOUNT:
    text="Account was changed";
    break;
  case REASON_CHARTCHANGE:
    text="Symbol or timeframe was changed";
    break;
  case REASON_CHARTCLOSE:
    text="Chart was closed";
    break;
  case REASON_PARAMETERS:
    text="Input-parameter was changed";
    break;
  case REASON_RECOMPILE:
    text="Program "+__FILE__+" was recompiled";
    break;
  case REASON_REMOVE:
    text="Program "+__FILE__+" was removed from chart";
    break;
  case REASON_TEMPLATE:
    text="New template was applied to chart";
    break;
  default:
    text="Another reason";
  }

  return text;
}

//+------------------------------------------------------------------+ 
//| Mouse state details                                              | 
//+------------------------------------------------------------------+ 
string MouseState(uint state) 
{ 
  string res; 
  res+="\nML: "   +(((state& 1)== 1)?"DN":"UP");   // mouse left 
  res+="\nMR: "   +(((state& 2)== 2)?"DN":"UP");   // mouse right  
  res+="\nMM: "   +(((state&16)==16)?"DN":"UP");   // mouse middle 
  res+="\nMX: "   +(((state&32)==32)?"DN":"UP");   // mouse first X key 
  res+="\nMY: "   +(((state&64)==64)?"DN":"UP");   // mouse second X key 
  res+="\nSHIFT: "+(((state& 4)== 4)?"DN":"UP");   // shift key 
  res+="\nCTRL: " +(((state& 8)== 8)?"DN":"UP");   // control key 
  return(res); 
} 

//+------------------------------------------------------------------+ 
//| ChartEvent function                                              | 
//+------------------------------------------------------------------+ 
void OnChartEvent(const int id, 
                  const long &lparam, 
                  const double &dparam, 
                  const string &sparam)
{
  // Show the event parameters on the chart 
  //Comment(__FUNCTION__,": id=",id," lparam=",lparam," dparam=",dparam," sparam=",sparam);
  
  // When pressing CTRL key, the pip distance evaluation by clicking on 
  // the chart area is activated. The first mouse click sets the first 
  // price; the second click sets the second price; other mouse clicks 
  // are ignored while another CTRL key is pressed.
  // See https://www.mql5.com/en/forum/93077
  // See https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.keys?redirectedfrom=MSDN&view=netframework-4.7.2
  
  //if(id == CHARTEVENT_KEYDOWN)
  //{
  //  switch(lparam) 
  //  { 
  //  case KEY_CTRL:
  //    Comment("Waiting user to measure pip distance with crosshair cursor...");
  //    firstPrice = 0.;
  //    secondPrice = 0.;
  //    setPipsWithMouse = true;
  //    break;
  //  default:
  //    break;
  //  } 
  //  ChartRedraw();
  //}
  if (id == CHARTEVENT_MOUSE_MOVE && !setPipsWithMouse)
  {
    // If the center mouse button is pressed for the first time, set user input waiting state
    if ((((uint)sparam) & 16) == 16)
    {
      Comment("Waiting user to measure pip distance with crosshair cursor...");
      firstPrice = 0.;
      secondPrice = 0.;
      setPipsWithMouse = true;
    }
  }
  else if (id == CHARTEVENT_MOUSE_MOVE && setPipsWithMouse)
  {
    // If the left mouse button is pressed for the first time, set first price
    if((firstPrice == 0.) && 
      ((((uint)sparam) & 1) == 1))
    {
      // Prepare variables 
      int x =(int)lparam; 
      int y =(int)dparam; 
      datetime dt = 0; 
      //double price = 0; 
      int window = 0;
      
      bool ok = ChartXYToTimePrice(0, x, y, window, dt, firstPrice);
      
      if(!ok)
      {
        Print("ChartXYToTimePrice return error code: ",GetLastError());
        firstPrice = 0.;
      }
      else
      {
        Print("firstPrice: ", firstPrice);
      }
    }
    // If the left mouse button is released for the first time, set second price
    else if((firstPrice != 0.) && 
      (secondPrice == 0.) && 
      ((((uint)sparam) & 1) != 1))
    {
      // Prepare variables 
      int x =(int)lparam; 
      int y =(int)dparam; 
      datetime dt = 0; 
      //double price = 0; 
      int window = 0;
      
      bool ok = ChartXYToTimePrice(0, x, y, window, dt, secondPrice);
      
      if(!ok)
      {
        Print("ChartXYToTimePrice return error code: ",GetLastError());
        secondPrice = 0.;
      }
      else
      {
        setPipsWithMouse = false;
        Pips = (int)(MathRound(MathAbs(firstPrice - secondPrice) * pipsMultiplier));
        Print("secondPrice: ", secondPrice, ", pip distance (rounded): ", Pips);
        DoWork();
        ChartRedraw();
      }
    }
  }
}

//+------------------------------------------------------------------+
