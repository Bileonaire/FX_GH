//+------------------------------------------------------------------+
//|                                                     Leon Bot.mq4 |
//|                                                       Bileonaire |
//|                                                         leon.com |
//+------------------------------------------------------------------+
#property copyright "Bileonaire"
#property link      "leon.com"
#property version   "1.00"
#property strict

string comment = "leonbot";
extern double Percentage_Risk = 1.75;
double Poin;
double target = 11000;

double Balance;

double ND(double val)
{
return(NormalizeDouble(val, Digits));
}

double pips;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  if (Point == 0.00001) Poin = 0.0001;
   else {
      if (Point == 0.001) Poin = 0.01;
      else {
         if (Point == 0.01) Poin = 0.1;
         else {
            if (Point == 0.1) Poin = 1;
            else Poin = 0;
         }
      }
   }

//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {


    double orderplaced = 1;
    double trading_time = 1;
    double target_reached = 1;

    double h4_12 = iMA(NULL,240,12,0,MODE_SMA,PRICE_CLOSE,0);
    double m15_20 = iMA(NULL,15,20,0,MODE_SMA,PRICE_CLOSE,0);
    double m15_200 = iMA(NULL,15,200,0,MODE_SMA,PRICE_CLOSE,0);
    double m15_100 = iMA(NULL,15,100,0,MODE_SMA,PRICE_CLOSE,0);
    double sl = m15_20;

    double buying_pressure = 0;
    double selling_pressure = 0;


    for(int i=0;i<OrdersTotal();i++) {
     int order = OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
      if (OrderComment() == comment && OrderSymbol() == Symbol()) orderplaced = 0;
    }

    if (Hour()>22 && Hour()<23 && Balance != AccountBalance()) {
        Balance = AccountBalance();
    }

// Close trades at night
    if (Hour()<10 || Hour()>22) {
      trading_time = 0;
      int ticket;
      for (int i = OrdersTotal() - 1; i >= 0; i--)
          {
          if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
            {
              if (OrderType() == 0 && OrderComment() == comment && OrderSymbol() == Symbol())
                {
                ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_BID), 3, CLR_NONE);
                if (ticket == -1) Print ("Error: ", GetLastError());
                if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
                }
              if (OrderType() == 1 && OrderComment() == comment && OrderSymbol() == Symbol())
                {
                ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_ASK), 3, CLR_NONE);
                if (ticket == -1) Print ("Error: ",  GetLastError());
                if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
                }
            }
          }
    }
// Closes trades when max daily loss is reached
    if (((Balance - AccountEquity()) > Balance*0.0475)) {
      target_reached = 0;
      int ticket;
      for (int i = OrdersTotal() - 1; i >= 0; i--)
          {
          if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
            {
              if (OrderType() == 0 && OrderComment() == comment && OrderSymbol() == Symbol())
                {
                ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_BID), 3, CLR_NONE);
                if (ticket == -1) Print ("Error: ", GetLastError());
                if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
                }
              if (OrderType() == 1 && OrderComment() == comment && OrderSymbol() == Symbol())
                {
                ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_ASK), 3, CLR_NONE);
                if (ticket == -1) Print ("Error: ",  GetLastError());
                if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
                }
            }
          }
    }

    // if (AccountBalance() > 12000) {
    //   target_reached = 0;
    // }

// max drawdown
    if (AccountBalance() < 9000 || ((Balance - AccountBalance()) > Balance*0.045)) {
        target_reached = 0;
    }


//+------------------------------------------------------------------+
//BUY
    if (Close[1] > Close[2] && Close[1] > Close[3] && Close[1] > Close[4] && Close[1] > Close[5] && Close[1] > Close[6]){
      buying_pressure = 1;
    }

    if (Close[1] < Close[2] && Close[1] < Close[3] && Close[1] < Close[4] && Close[1] < Close[5] && Close[1] > Close[6]){
      selling_pressure = 1;
    }

    if (orderplaced && trading_time && target_reached) {

      if (Close[1] > h4_12 && Close[1] > m15_200 && Close[1] > m15_100 && Close[1] > m15_20 && Ask > High[1] && Close[1] > Open[1] && buying_pressure) {
        pips = (Ask-sl)/Poin;
        double Risk = (AccountBalance()*Percentage_Risk*0.01 / pips) / ((MarketInfo(Symbol(), MODE_TICKVALUE))*10);
        Risk = NormalizeDouble(Risk,2);

        int ticket = OrderSend(Symbol(), OP_BUY, Risk, ND(Ask), 3, 0.000, 0.000, comment, 11, 0, CLR_NONE);
        bool res = OrderModify(ticket, 0, ND(Ask-pips*Poin), ND(Bid+pips*1.2*Poin), 0);
        if (ticket) orderplaced = 0;
      }

//+------------------------------------------------------------------+
// Sell
      if (Close[1] < h4_12 && Close[1] < m15_200 && Close[1] < m15_100 && Close[1] < m15_20 && Bid < Low[1] && Close[1] < Open[1] && selling_pressure) {
        pips = (sl-Bid)/Poin;
        double Risk = (AccountBalance()*Percentage_Risk*0.01 / pips) / ((MarketInfo(Symbol(), MODE_TICKVALUE))*10);
        Risk = NormalizeDouble(Risk,2);

        int ticket = OrderSend(Symbol(), OP_SELL, Risk, ND(Bid),3, 0.000, 0.000,comment,3,0,Red);
        bool res = OrderModify(ticket, 0, ND(Ask+pips*Poin), ND(Bid-pips*1.2*Poin), 0);

        if (ticket) orderplaced = 0;
      }
    }

    if (orderplaced == 0) {
      double stoploss;
      double takeprofit;


      int ordertotal = OrdersTotal();
      for (int i=0; i<ordertotal; i++)
      {
          int order = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
          if (OrderSymbol() == Symbol())
            if (OrderComment() == comment && (OrderType()==OP_BUY || OrderType()==OP_BUYSTOP))
            {
                double profit = (Ask-OrderOpenPrice())/Poin;
                double profitable_06 = 0;

                if (OrderStopLoss() != m15_20 && OrderStopLoss() < m15_20 && OrderStopLoss() < OrderOpenPrice()) {
                  stoploss = m15_20;
                  takeprofit = OrderTakeProfit();
                  int ticket = OrderModify(OrderTicket(), OrderOpenPrice(), ND(stoploss),  takeprofit, 0);
                }

                if ((profit/pips) > 0.5) {
                  profitable_06 = 1;
                  stoploss = Low[2];
                  takeprofit = OrderTakeProfit();
                  int ticket = OrderModify(OrderTicket(), OrderOpenPrice(), ND(stoploss),  takeprofit, 0);
                }

                if (profitable_06) {
                  stoploss = Low[2];
                  takeprofit = OrderTakeProfit();
                  int ticket = OrderModify(OrderTicket(), OrderOpenPrice(), ND(stoploss),  takeprofit, 0);
                }

            }

            if (OrderComment() == comment && (OrderType()==OP_SELL || OrderType()==OP_SELLSTOP))
            {
                double profit = (OrderOpenPrice()-Bid)/Poin;
                double profitable_06_sell = 0;

                if (OrderStopLoss() != m15_20 && OrderStopLoss() > m15_20 && OrderStopLoss() > OrderOpenPrice()) {
                  stoploss = m15_20;
                  takeprofit = OrderTakeProfit();
                  int ticket = OrderModify(OrderTicket(), OrderOpenPrice(), ND(stoploss),  takeprofit, 0);
                }

                if ((profit/pips) > 0.5) {
                  profitable_06_sell = 1;
                  stoploss = High[2];
                  takeprofit = OrderTakeProfit();
                  int ticket = OrderModify(OrderTicket(), OrderOpenPrice(), ND(stoploss),  takeprofit, 0);
                }

                if (profitable_06_sell) {
                  stoploss = High[2];
                  takeprofit = OrderTakeProfit();
                  int ticket = OrderModify(OrderTicket(), OrderOpenPrice(), ND(stoploss),  takeprofit, 0);
                }

            }
          }
    }
//---
  }
//+------------------------------------------------------------------+
