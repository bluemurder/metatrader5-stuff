//+------------------------------------------------------------------+
//|                                                     RSITrend.mq5 |
//|                                 Copyright 2015, Alessio Leoncini |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Alessio Leoncini"
#property link      ""
#property version   "1.00"
//--- input parameters
input int      StopLoss=38; // StopLoss percentage
input int      TakeProfit=1000; // TakeProfit percentage
input int      RSIPeriod=20; // RSI period
input double   RSIStartLong=30; // 
input double   RSIEndLong=62; //
input double   RSIStartShort=70.2; //
input double   RSIEndShort=34; //
input int      EA_Magic=12345; // EA Magic Number
input double   Lot=0.1;          // Lots to Trade
int rsiHandle; // handle for our rsi indicator
double p_close; // Variable to store the close value of a bar
double rsiVal[]; // Dynamic array to hold the values of RSI for each bar
int STP,TKP;   // To be used for Stop Loss & Take Profit values
MqlTradeRequest   m_request;         // request data
MqlTradeResult    m_result;          // result data
MqlTradeCheckResult m_check_result;  // result check data
ENUM_ORDER_TYPE_FILLING m_type_filling;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClearStructures(void)
  {
   ZeroMemory(m_request);
   ZeroMemory(m_result);
   ZeroMemory(m_check_result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PositionClose(const string symbol,const ulong percent,const ulong deviation)
  {
   bool   partial_close=false;
   int    retry_count  =10;
   uint   retcode      =TRADE_RETCODE_REJECT;
//--- check stopped
   if(IsStopped()) return(false);
//--- clean
   ClearStructures();
   do
     {
      //--- checking
      if(PositionSelect(symbol))
        {
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
           {
            //--- prepare request for close BUY position
            m_request.type =ORDER_TYPE_SELL;
            m_request.price=SymbolInfoDouble(symbol,SYMBOL_BID);
           }
         else
           {
            //--- prepare request for close SELL position
            m_request.type =ORDER_TYPE_BUY;
            m_request.price=SymbolInfoDouble(symbol,SYMBOL_ASK);
           }
        }
      else
        {
         //--- position not found
         m_result.retcode=retcode;
         return(false);
        }
      //--- setting request
      m_request.action      =TRADE_ACTION_DEAL;
      m_request.symbol      =symbol;
      m_request.deviation   =(deviation==ULONG_MAX) ? 100 : deviation;
      m_request.type_filling=m_type_filling;
      m_request.volume      =NormalizeDouble(PositionGetDouble(POSITION_VOLUME)*percent/100, 2);
      //--- check volume
      double max_volume=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
      if(m_request.volume>max_volume)
        {
         m_request.volume=max_volume;
         partial_close=true;
        }
      else
         partial_close=false;
      //--- order send
      if(!OrderSend(m_request,m_result))
        {
         if(--retry_count!=0) continue;
         if(retcode==TRADE_RETCODE_DONE_PARTIAL)
            m_result.retcode=retcode;
         return(false);
        }
      //--- WARNING. If position volume exceeds the maximum volume allowed for deal,
      //--- and when the asynchronous trade mode is on, for safety reasons, position is closed not completely,
      //--- but partially. It is decreased by the maximum volume allowed for deal.
      //if(m_async_mode) break;
      retcode=TRADE_RETCODE_DONE_PARTIAL;
      if(partial_close) Sleep(1000);
     }
   while(partial_close);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
// Handle for RSI indicator
   rsiHandle=iRSI(_Symbol,_Period,RSIPeriod,PRICE_CLOSE);
// Check handle creation
   if(rsiHandle<0)
     {
      Alert("Error Creating Handles for indicators - error: ",GetLastError(),"!!");
     }

//--- Let us handle currency pairs with 5 or 3 digit prices instead of 4
   STP = StopLoss;
   TKP = TakeProfit;
   if(_Digits==5 || _Digits==3)
     {
      STP = STP*10;
      TKP = TKP*10;
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(rsiHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Do we have enough bars to work with
   if(Bars(_Symbol,_Period)<60) // if total bars is less than 60 bars
     {
      Alert("We have less than 60 bars, EA will now exit!!");
      return;
     }
// We will use the static Old_Time variable to serve the bar time.
// At each OnTick execution we will check the current bar time with the saved one.
// If the bar time isn't equal to the saved time, it indicates that we have a new tick.
   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;

// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
        }
     }
   else
     {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return;
     }

//--- Do we have positions opened already?
   bool Buy_opened=false;  // variable to hold the result of Buy opened position
   bool Sell_opened=false; // variable to hold the result of Sell opened position

   if(PositionSelect(_Symbol)==true) // we have an opened position
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         Buy_opened=true;  //It is a Buy
        }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         Sell_opened=true; // It is a Sell
        }
     }

//--- EA should only check for new trade if we have a new bar
//   if(Sell_opened==false)
//     {
   if(IsNewBar==false)
     {
      return;
     }
//     }

//--- Do we have enough bars to work with
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<60) // if total bars is less than 60 bars
     {
      Alert("We have less than 60 bars, EA will now exit!!");
      return;
     }
//--- Define some MQL5 Structures we will use for our trade
   MqlTick latest_price;     // To be used for getting recent/latest price quotes
   MqlRates mrate[];         // To be used to store the prices, volumes and spread of each bar
   ZeroMemory(m_request);     // Initialization of mrequest structure

   if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);

//--- Get the last price quote using the MQL5 MqlTick Structure
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return;
     }

//--- Get the details of the latest 3 bars
   if(CopyRates(_Symbol,_Period,0,1,mrate)<0)
     {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      return;
     }

//--- Copy the new values of our indicators to buffers (arrays) using the handle

   if(CopyBuffer(rsiHandle,0,0,3,rsiVal)<0)
     {
      Alert("Error copying Moving Average indicator buffer - error:",GetLastError());
      return;
     }

//--- we have no errors, so continue

// Copy the bar close price for the previous bar prior to the current bar, that is Bar 1
//p_close=mrate[1].close;  // bar 1 close price

/*
    2. Check for a Short/Sell Setup : RSI > RSIHighThreshold
*/
//--- Declare bool type variables to hold our Sell/Stop Sell Conditions
   bool Sell_Condition_1=(rsiVal[2]>RSIStartShort);
   bool Stop_Sell_Condition_1=(rsiVal[2]<RSIEndShort);
   bool Buy_Condition_1=(rsiVal[2]<RSIStartLong);
   bool Stop_Buy_Condition_1=(rsiVal[2]>RSIEndLong);

// Need to close current order?
   if(Stop_Sell_Condition_1 && Sell_opened)
     {
      for(int i=0;i<PositionsTotal();i++)
        {
         // processing orders with "our" symbols only
         if(PositionGetSymbol(i)==_Symbol)
           {
            // processing Sell orders
            if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_SELL)
              {
               // we will delete this pending order
               //mrequest.action=TRADE_ACTION_REMOVE;
               // sending request to trade server
               //bool ordererror=OrderSend(mrequest,mresult);
               bool ordererror=PositionClose(_Symbol,100,ULONG_MAX);
               if(!ordererror)
                 {
                  Alert("The position close request could not be completed -error:",GetLastError());
                  ResetLastError();
                  return;
                 }
               // exiting from the OnTick() function
               return;
              }
           }
        }
     }

   if(Stop_Buy_Condition_1 && Buy_opened)
     {
      for(int i=0;i<PositionsTotal();i++)
        {
         // processing orders with "our" symbols only
         if(PositionGetSymbol(i)==_Symbol)
           {
            // processing Sell orders
            if(PositionGetInteger(POSITION_TYPE)==ORDER_TYPE_BUY)
              {
               // we will delete this pending order
               //mrequest.action=TRADE_ACTION_REMOVE;
               // sending request to trade server
               //bool ordererror=OrderSend(mrequest,mresult);
               bool ordererror=PositionClose(_Symbol,100,ULONG_MAX);
               if(!ordererror)
                 {
                  Alert("The position close request could not be completed -error:",GetLastError());
                  ResetLastError();
                  return;
                 }
               // exiting from the OnTick() function
               return;
              }
           }
        }
     }

   if(Sell_Condition_1)
     {
      // any opened Sell position?
      if(Sell_opened || Buy_opened)
        {
         Alert("We already have a Sell Position!!!");
         return;    // Don't open a new Sell Position
        }
      m_request.action=TRADE_ACTION_DEAL;                                // immediate order execution
      m_request.price=NormalizeDouble(latest_price.bid,_Digits);          // latest ask price
      m_request.sl = NormalizeDouble(latest_price.bid + STP*_Point,_Digits); // Stop Loss
      m_request.tp = NormalizeDouble(latest_price.bid - TKP*_Point,_Digits); // Take Profit
      m_request.symbol= _Symbol;                                         // currency pair
      m_request.volume = Lot;                                            // number of lots to trade
      m_request.magic = EA_Magic;                                        // Order Magic Number
      m_request.type= ORDER_TYPE_SELL;                                     // Sell Order
      m_request.type_filling = ORDER_FILLING_FOK;                          // Order execution type
      m_request.deviation=100;                                            // Deviation from current price
      //--- send order
      bool ordererror=OrderSend(m_request,m_result);
      if(!ordererror)
        {
         Alert("The Sell order request could not be completed -error:",GetLastError());
         ResetLastError();
         return;
        }

      // get the result code
      if(m_result.retcode==10009 || m_result.retcode==10008) //Request is completed or order placed
        {
         Alert("A Sell order has been successfully placed with Ticket#:",m_result.order,"!!");
        }
      else
        {
         Alert("The Sell order request could not be completed -error:",GetLastError());
         ResetLastError();
         return;
        }
     }

   if(Buy_Condition_1)
     {
      // any opened Buy position?
      if(Buy_opened || Sell_opened)
        {
         Alert("We already have a Position!!!");
         return;    // Don't open a new Buy Position
        }
      m_request.action=TRADE_ACTION_DEAL;                                // immediate order execution
      m_request.price=NormalizeDouble(latest_price.ask,_Digits);          // latest ask price
      m_request.sl = NormalizeDouble(latest_price.ask - STP*_Point,_Digits); // Stop Loss
      m_request.tp = NormalizeDouble(latest_price.ask + TKP*_Point,_Digits); // Take Profit
      m_request.symbol= _Symbol;                                         // currency pair
      m_request.volume = Lot;                                            // number of lots to trade
      m_request.magic = EA_Magic;                                        // Order Magic Number
      m_request.type= ORDER_TYPE_BUY;                                     // Sell Order
      m_request.type_filling= ORDER_FILLING_FOK;                          // Order execution type
      m_request.deviation=100;                                            // Deviation from current price
      //--- send order
      bool ordererror=OrderSend(m_request,m_result);
      if(!ordererror)
        {
         Alert("The Buy order request could not be completed -error:",GetLastError());
         ResetLastError();
         return;
        }

      // get the result code
      if(m_result.retcode==10009 || m_result.retcode==10008) //Request is completed or order placed
        {
         Alert("A Buy order has been successfully placed with Ticket#:",m_result.order,"!!");
        }
      else
        {
         Alert("The Buy order request could not be completed -error:",GetLastError());
         ResetLastError();
         return;
        }
     }
  }
//+------------------------------------------------------------------+
