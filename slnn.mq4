#property copyright "xvk3"
#property link      "xvk3"
#property version   "1.00"
#property strict

#define UNDEFINED    0
#define PROFIT       1
#define LOSS         2

//notifyStopLossNearing input parameters
input bool           ibStopLossNearing;      //StopLossNearing : Enabled
input double         idThreshold;            //StopLossNearing : Threshold
input uint           iuDebounce;             //StopLossNearing : Debounce Time

//notifyNet input parameters
input bool           ibProfitChange;         //ProfitChange    : Enabled
input double         idHysteresis;           //ProfitChange    : Hysteresis

//initialisation procedure
int OnInit()  {
   EventSetTimer(10);
   SendNotification("Net Notifier Running");
   return(INIT_SUCCEEDED);
}
int Count=0;
void OnDeinit(const int reason)  {
   EventKillTimer();
   SendNotification("Net Notifier Stopping");
}
 
//pushes notification when price nears stop loss
int notifyStopLossNearing(int iIndex, double dThreshold, uint uDebounce) {

   //check for invalid order index
   if(iIndex < 0) {
      Print("notifyStopLossNearing error - invalid order index");
      return 0;
   }
   
   //select order by index/position
   if(!OrderSelect(iIndex, SELECT_BY_POS, MODE_TRADES))   {
      int iLastError = GetLastError();
      Print("notifyStopLossNearing error - OrderSelect failed with error code ", iLastError);
      ResetLastError();
      return 0;
   }
   
   double dStopLoss = OrderStopLoss();
   double dDifference;
   string sOrderType;
   
   //determine difference between price and stop loss & initialises order type
   switch(OrderType())  {
   case OP_BUY:
      dDifference = Ask - dStopLoss;
      sOrderType = "BUY";
   case OP_SELL:
      dDifference = dStopLoss - Bid;
      sOrderType = "SELL";
   default:
      Print("notifyStopLossNearing error - invalid order type for procedure");
      return 0;
   }
   
   //monitors price and stop loss difference for maximum debounce time
   if(dDifference < dThreshold)  {
      uint uStartTime = GetTickCount();
      while(dDifference < dThreshold)  {
         uint uCurrentTime = GetTickCount();
         if((uCurrentTime - uStartTime) >= uDebounce) {
            //build string for notification
            string sNotification = StringConcatenate(OrderSymbol(), ", ", sOrderType, " ", DoubleToStr(OrderLots()), " Nearing Stop Loss");
            SendNotification(sNotification);
            return true;
         }
      }
   }
   return true;
}


  
bool nofityOnProfitChange(double dHysteresis)   {
   int iIndex;
   int iTotalNumberOfOrders = OrdersTotal();
   string sSymbol;
   string sDifference;
   string sNotification;
  
  
   //generate array of booleans to indicate change in profit
   int bProfitChange[];
   if(ArrayResize(bProfitChange, iTotalNumberOfOrders) == -1)  {
      return false;
   }
   ArrayFill(bProfitChange, 0, iTotalNumberOfOrders, 0);
   
   if(!iTotalNumberOfOrders)  {
      return false;
   }
   double dOpenPrice;
   double dDifference;
   
   for(iIndex = iTotalNumberOfOrders - 1; iIndex >= 0; iIndex--)  {
      if(!OrderSelect(iIndex, SELECT_BY_POS, MODE_TRADES))   {
         Print("OrderSelect for order ", iIndex, " failed error : ", GetLastError());
         continue;
      }
      
      sSymbol = OrderSymbol();
      dOpenPrice = OrderOpenPrice();
      
      //for longs
      if(OrderType() == OP_BUY) {
         //profit for long
         if(dOpenPrice < Ask) {
            dDifference = Ask - dOpenPrice;
            if(bProfitChange[iIndex] == LOSS) {
               //build string for notification
               sDifference = DoubleToStr(dDifference, 5);
               sNotification = StringConcatenate("Change to PROFIT ", sSymbol, " : ", sDifference);
               SendNotification(sNotification);
            }
             bProfitChange[iIndex] = PROFIT;
         }
         //loss for long
         if(dOpenPrice < Ask) {
            dDifference = dOpenPrice - Ask;
            if(bProfitChange[iIndex] == PROFIT) {
               //build string for notification
               sDifference = DoubleToStr(dDifference, 5);
               sNotification = StringConcatenate("Change to LOSS ", sSymbol, " : ", sDifference);
               SendNotification(sNotification);
            }
            bProfitChange[iIndex] = LOSS;
         }
      }
      
      //for shorts
      if(OrderType() == OP_SELL) {
         //profit for short
         if(dOpenPrice > Bid) {
            dDifference = dOpenPrice - Bid;
            if(bProfitChange[iIndex] == LOSS) {
               //build string for notification
               sDifference = DoubleToStr(dDifference, 5);
               sNotification = StringConcatenate("Change to PROFIT ", sSymbol, " : ", sDifference);
               SendNotification(sNotification);
            }
             bProfitChange[iIndex] = PROFIT;
         }
         //loss for short
         if(dOpenPrice < Bid) {
            dDifference = Bid - dOpenPrice;
            if(bProfitChange[iIndex] == PROFIT) {
               //build string for notification
               sDifference = DoubleToStr(dDifference, 5);
               sNotification = StringConcatenate("Change to LOSS ", sSymbol, " : ", sDifference);
               SendNotification(sNotification);
            }
            bProfitChange[iIndex] = LOSS;
         }
      } 
      
      Sleep(6001);
      
           
   }
   return true;
}

void OnTimer() {

   bool returnValue = nofityOnProfitChange(0);
}