//+------------------------------------------------------------------+
//|                                         Fixed risk assistant.mq5 |
//|                                          Copyleft 2020, zebedeig |
//|                           https://www.mql5.com/en/users/zebedeig |
//+------------------------------------------------------------------+

// Usage:
// The default risk (percentage of your account) is set to 1%. You can"
// change it in the indicator properties panel."
// 1) Click center mouse button to enter pip distance evaluation tool;"
// 2) Drag crosshair cursor to select the pip distance you want to risk."
// 3) Present tool immediately evaluates the order lot size to match "
//    the predefined risk. You MUST put a stop loss with just specified"
//    pips distance."
// 4) Press 'B' to open a buy order on selected price level"
//    (BUY STOP or MARKET BUY depending on actual symbol price)."
//    Press 'S' to open a sell order on clicked price level"
//    (SELL STOP or MARKET SELL depending on actual symbol price)."
//    Press 'C' to erase just painted level lines.

#property copyright    "Copyleft 2020, by zebedeig"
#property link         "https://www.mql5.com/en/users/zebedeig"
#property version      "3.03"
#property description  "Tool used to calculate the correct lot size to trade, given a fixed risk and a number of pips."
#property description  "You can also open orders by a single keyboard hit on just evaluated lot size."

#define KEY_B 66
#define KEY_S 83
#define KEY_C 67
//#define DEBUGGING
#define NAME_LINE1 "HLine1LC"
#define NAME_LINE2 "HLine2LC"

double Pips = 0; // Stop loss distance from open order
input double Risk = 0.05; // Free margin fraction you want to risk for the trade
input bool useTrueAccountBalance = true; // Check to read the actual free margin of your balance, uncheck to specify it
input int SimulatedAccountBalance = 2000; // Specify here a simulated balance value 
double point; // Used to handle the correct digits number
double firstPrice = 0.; // Used to set Pips value by clicking on the chart
double secondPrice = 0.; // Used to set Pips value by clicking on the chart
int pipsMultiplier;
double lots;
enum ProgramStates
{
  Idle,
  WaitCrossHairPress,
  WaitSetFirstPrice,     // Flag to enable evaluating Pips value by clicking on the chart
  WaitSetSecondPrice    // Flag to enable evaluating Pips value by clicking on the chart
};
ProgramStates programState = WaitCrossHairPress;

int OnInit()
{
  // Enable CHART_EVENT_MOUSE_MOVE messages 
  ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1); 
  // Forced updating of chart properties ensures readiness for event processing 
  ChartRedraw(); 

  // Broker digits
  point = _Point;
  
  pipsMultiplier = 1;

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
  
  DoWork();
  
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
  Comment("");  // Cleanup
  Print(__FUNCTION__,"_UninitReason = ",getUninitReasonText(_UninitReason));
  return;
}

void OnTick()
{
  if(programState == ProgramStates::Idle)
  {
    DoWork();
  }
}

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
    Comment("Invalid 'Pips' value. Use crosshair again (click on first price level and release to second price level).");
    return;
  }

  lots = Risk * freeMargin / (pipValue * Pips);
  if(lots <= 0)
  {
    Comment("Unable to get lot value...");
    return;
  }

  // Truncate lot quantity to 2 decimal digits without rounding it
  lots = floor(lots * 100) / 100;

  string commentString = "Summary: to risk " + DepositCurrency +" "+ DoubleToString(Risk * freeMargin, 2) + " in " + DoubleToString(Pips, 1) + " pips, you can trade up to " + DoubleToString(lots, 2) + " lots of " + Symbol() + "\n";
  commentString += "Your free margin: "+ DepositCurrency + " " + DoubleToString(freeMargin, 2) + "\n";
  // commentString += "Value of one pip trading 1 lot of " + Symbol() + ": " + DepositCurrency + " " + DoubleToString(pipValue, 3) + "\n";
  commentString += "Risk selected: " + DoubleToString(Risk * 100, 0) + "% (" + DepositCurrency + " " + DoubleToString(Risk * freeMargin, 2) + ")\n";
  commentString += "Pips selected: " + DoubleToString(Pips, 1) + "\n";
  commentString += "Max lots: " + DoubleToString(lots, 2) + "\n";
  commentString += "Press B/S to set a BUY/SELL order, C to erase painted lines.\n";

  Comment(commentString);
}

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
  
  // See https://www.mql5.com/en/forum/93077
  // See https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.keys?redirectedfrom=MSDN&view=netframework-4.7.2
  // https://www.mql5.com/en/docs/chart_operations/chartxytotimeprice
  
  if (id == CHARTEVENT_KEYDOWN)
  {
    uint keyCode = (uint)lparam;
    switch (keyCode) 
    { 
    case KEY_B:
      if(Pips <= 0)
      {
        Comment("Invalid 'Pips' value. Use crosshair again (click on first price level and release to second price level).");
        programState = ProgramStates::WaitCrossHairPress;
        break;
      }
      if(ObjectFind(0, NAME_LINE1) < 0)
      {
        Comment("Red lines not found. Use crosshair again (click on first price level and release to second price level).");
        programState = ProgramStates::WaitCrossHairPress;
        break;
      }
      SendOrder(true);
      break;
    case KEY_S:
      if(Pips <= 0)
      {
        Comment("Invalid 'Pips' value. Use crosshair again (click on first price level and release to second price level).");
        programState = ProgramStates::WaitCrossHairPress;
        break;
      }
      if(ObjectFind(0, NAME_LINE1) < 0)
      {
        Comment("Red lines not found. Use crosshair again (click on first price level and release to second price level).");
        programState = ProgramStates::WaitCrossHairPress;
        break;
      }
      SendOrder(false);
      break;
    case KEY_C:
      ObjectDelete(0, NAME_LINE1);
      ObjectDelete(0, NAME_LINE2);
      ChartRedraw();
      programState = ProgramStates::WaitCrossHairPress;
      break;
    default:
      programState = ProgramStates::WaitCrossHairPress;
      break;
    }
  }
  else if (id == CHARTEVENT_MOUSE_MOVE)
  {
    uint mouseState = (uint)sparam;
    
    // If the center mouse button is pressed for the first time,
    // AND state is not already "WaitSetFirstPrice",
    // THEN enter "WaitSetFirstPrice" state
    if ( ((mouseState & 16) == 16) && (programState != ProgramStates::WaitSetFirstPrice) )
    {
      #ifdef DEBUGGING
      Print("check center button pressed");
      #endif
      
      // Erase previous lines
      ObjectDelete(0, NAME_LINE1);
      ObjectDelete(0, NAME_LINE2);
      
      Comment("Waiting user to measure pip distance with crosshair cursor...");
      firstPrice = 0.;
      secondPrice = 0.;
      programState = ProgramStates::WaitSetFirstPrice;
    }
    
    // Else, if state is "WaitSetFirstPrice"
    else if ( ((mouseState & 1) == 1) && (programState == ProgramStates::WaitSetFirstPrice) )
    {
      #ifdef DEBUGGING
      Print("set first price");
      #endif
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
        programState = ProgramStates::WaitSetSecondPrice;
        DrawHorizontalLine(firstPrice, dt, window, NAME_LINE1);
      }
    }
    
    // Else if the left mouse button is released for the first time,
    // AND state is "WaitSetSecondPrice"
    // THEN set second price
    else if ( ((mouseState & 1) != 1) && (programState == ProgramStates::WaitSetSecondPrice) )
    {
      #ifdef DEBUGGING
      Print("set second price");
      #endif
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
        programState = ProgramStates::Idle;
        Pips = MathAbs(firstPrice - secondPrice) * pipsMultiplier;
        Print("secondPrice: ", secondPrice, ", pip distance: ", DoubleToString(Pips, 1));
        DrawHorizontalLine(secondPrice, dt, window, NAME_LINE2);
        DoWork();
        ChartRedraw();
      }
    }
  }
}

void DrawHorizontalLine(double price, datetime dt, int window, const string name)
{
  ObjectCreate(0, name, OBJ_HLINE, window, dt, price);
  ChartRedraw();
}

void SendOrder(bool buy)
{
  #ifdef DEBUGGING
  Print("launch buy");
  #endif
  
  double price;
  double stoploss;
  
  // BUY case
  if(buy)
  {
    // Get price and stoploss values
    if (firstPrice > secondPrice)
    {
      price = firstPrice;
      stoploss = secondPrice;
    }
    else
    {
      price = secondPrice;
      stoploss = firstPrice;
    }
  
    // If ask < clicked price, time to set a BUY Stop
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    if(ask < price)
    {
      #ifdef DEBUGGING
      Print("buy stop");
      #endif
      MqlTradeRequest request = {0};
      request.action = TRADE_ACTION_PENDING;
      request.symbol = Symbol();
      request.volume = lots;
      request.sl = stoploss;
      request.tp = 0;
      request.deviation = 4;
      request.price = price;
      request.type = ORDER_TYPE_BUY_STOP; // order type ORDER_TYPE_BUY_LIMIT, ORDER_TYPE_SELL_LIMIT, ORDER_TYPE_BUY_STOP, ORDER_TYPE_SELL_STOP
      request.type_filling = ORDER_FILLING_FOK;
      request.expiration = ORDER_TIME_GTC;
      MqlTradeResult result = {0};
      if(!OrderSend(request, result))
      {
        PrintFormat("OrderSend error %d", GetLastError());     // if unable to send the request, output the error code
      }
      // Information about the operation
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
    }
    
    // Else, need to set a MARKET BUY
    else
    {
      #ifdef DEBUGGING
      Print("market buy");
      #endif
      MqlTradeRequest request = {0};
      request.action = TRADE_ACTION_DEAL;
      request.symbol = Symbol();
      request.volume = lots;
      request.sl = stoploss;
      request.tp = 0;
      request.deviation = 4;
      request.price = price;
      request.type = ORDER_TYPE_BUY;
      request.type_filling = ORDER_FILLING_FOK;
      MqlTradeResult result = {0};
      if(!OrderSend(request, result))
      {
        PrintFormat("OrderSend error %d", GetLastError());     // if unable to send the request, output the error code
      }
      // Information about the operation
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
    }
    
    // Return to normal state
    DoWork();
    programState = ProgramStates::Idle;
    ObjectDelete(0, NAME_LINE1);
    ObjectDelete(0, NAME_LINE2);
  }
  
  // SELL case 
  else
  {
    // Get price and stoploss values
    if (firstPrice < secondPrice)
    {
      price = firstPrice;
      stoploss = secondPrice;
    }
    else
    {
      price = secondPrice;
      stoploss = firstPrice;
    }
    
    // If bid > clicked price, time to set a SELL Stop
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    if(bid > price)
    {
      #ifdef DEBUGGING
      Print("sell stop");
      #endif
      MqlTradeRequest request = {0};
      request.action = TRADE_ACTION_PENDING;
      request.symbol = Symbol();
      request.volume = lots;
      request.sl = stoploss;
      request.tp = 0;
      request.deviation = 4;
      request.price = price;
      request.type = ORDER_TYPE_SELL_STOP; // order type ORDER_TYPE_BUY_LIMIT, ORDER_TYPE_SELL_LIMIT, ORDER_TYPE_BUY_STOP, ORDER_TYPE_SELL_STOP
      request.type_filling = ORDER_FILLING_FOK;
      request.expiration = ORDER_TIME_GTC;
      MqlTradeResult result = {0};
      if(!OrderSend(request, result))
      {
        PrintFormat("OrderSend error %d", GetLastError());     // if unable to send the request, output the error code
      }
      // Information about the operation
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
    }

    // Else, need to set a MARKET SELL
    else
    {
      #ifdef DEBUGGING
      Print("market sell");
      #endif
      MqlTradeRequest request = {0};
      request.action = TRADE_ACTION_DEAL;
      request.symbol = Symbol();
      request.volume = lots;
      request.sl = stoploss;
      request.tp = 0;
      request.deviation = 4;
      request.price = price;
      request.type = ORDER_TYPE_SELL;
      request.type_filling = ORDER_FILLING_FOK;
      MqlTradeResult result = {0};
      if(!OrderSend(request, result))
      {
        PrintFormat("OrderSend error %d", GetLastError());     // if unable to send the request, output the error code
      }
      // Information about the operation
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
    }

    // Return to normal state
    DoWork();
    programState = ProgramStates::Idle;
    ObjectDelete(0, NAME_LINE1);
    ObjectDelete(0, NAME_LINE2);
  }
}
