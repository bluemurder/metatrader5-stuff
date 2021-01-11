#include <Trade\Trade.mqh>

input int DistanceInPoints = 150;

CTrade trade;
double askorbid;
bool isbuy = true;
double mytrailingstoploss;
string symbolstring;

void OnTick()
{
  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
  {
    askorbid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
    isbuy = true;
  }
  else
  {
    askorbid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
    isbuy = false;
  }
    
  CheckTrailingStop();
}

void CheckTrailingStop()
{
  if(isbuy)
    mytrailingstoploss = NormalizeDouble(askorbid - DistanceInPoints * _Point, _Digits);
  else
    mytrailingstoploss = NormalizeDouble(askorbid + DistanceInPoints * _Point, _Digits);
    
  for(int i = 0; i<PositionsTotal(); i++)
  {
    symbolstring = PositionGetSymbol(i);
    if(symbolstring == _Symbol)
    {
      ulong positionTicket = PositionGetInteger(POSITION_TICKET);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      if(isbuy)
      {
        if(currentSL < mytrailingstoploss)
        {
          trade.PositionModify(positionTicket, mytrailingstoploss, currentTP);
        }
      }
      else
      {
        if(currentSL > mytrailingstoploss)
        {
          trade.PositionModify(positionTicket, mytrailingstoploss, currentTP);
        }
      }
    }
  }
}
