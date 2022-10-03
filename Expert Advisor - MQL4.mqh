//+------------------------------------------------------------------+
//|                                                       Family.mq4 |
//|                                                Ntavigwa Bashombe |
//|                                         https://www.bashombe.com |
//+------------------------------------------------------------------+
#property copyright "Ntavigwa Bashombe"
#property link      "https://www.bashombe.com"
#property version   "1.00"
#property strict
#include <Methods.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

/*
OPTIMIZED RESULTS - TEST 1
-----------------
2105	30.24	18	0.00	1.68	17.37	16.59%	0.00000000	pipsProfit=17 	pipsLoss=17 	maxOpenTrades=16 	noisyFactor=32 	maxValuesInRange=17 	trend_EMA_Value=136 	breakEvenIndex=20 	breakEvenProfit=1 	liveTradesAllowed=9 	slippage=5 	signalPipsDifference=8	
*/

// PIPS FOR PROFITS
input int pipsProfit = 20;
// PIPS FOR LOSS
input int pipsLoss = 16;
// TOTAL AMOUNT OF OPEN TRADES
input int maxOpenTrades = 20;
// METHODS VARIABLES
input int noisyFactor = 200; // AMOUNT OF PIPS TO BE INCLUDED IN A RANGE
input int maxValuesInRange = 5; // MAX VALUES TO BE IN THE RANGE
input int trend_EMA_Value = 100; // VALUES OF EMA FOR TREND DETECTOR
input int breakEvenIndex = 14; // APPLY BREAK EVEN WHEN AT THIS VALUE
input int breakEvenProfit = 3; // MOVE THE STOP LOSS WHEN AT THIS VALUE
input int liveTradesAllowed = 10; // MAXIMUM NUMBER OF TRADES ALLOWED PER SYMBOL
input int slippage = 3; // IF PIPS HAVE GONE BEYOND 3 PIPS FROM THE LAST KNOWN PRICE, IGNORE THE TRADE
input int signalPipsDifference = 5; // THE DIFFERENCE OF PIPS FROM THE 100EMA TO THE LATEST CLOSING PRICE
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
//---
   Print("NTAVIGWA BASHOMBE - E.A. V1.0.0.0");
   // Print("THE SIGNAL IS: " + checkEntry());
   // checkSignal();
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   // WE SEND A REQUEST EVERY SINGLE TIME
   sendOrder(checkSignal(noisyFactor, maxValuesInRange, trend_EMA_Value, signalPipsDifference));
   // WE CHECK FOR CURRENT OPEN POSITION AND APPLY OUR BREAK EVEN STOP
   CheckBreakEven();
   // Print("ASK PRICE: " + Ask);
   // Print("NEW PRICE: " + (Ask + 18 * getPipsValue()));
   // Print("Points : " + (Ask + 18 * _Point));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*double positionSizeCalculator(double stopLossPips) {
// WE SHOULD SET THE MAXIMUM POURCENTAGE TO LOOSE AND THE PIPS TTO THE STOP LOSS
   // MAX RISK PER TRADE IS 1% ONLY
   double maxRiskPerTrade = 1;
   // THE LOT OF THE CURRENT TRADE
   double lotSize = 0;
   // WE GET THE VALUE OF A TICK
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   // IF THE DIGITS ARE 3, WE NORMALIZE MULTIPLYING BY 10.
   if(Digits == 3 || Digits == 5) {
      nTickValue = nTickValue * 10;
   }

   // WE APPLY THE FORMULA TO CALCULATE THE POSITION SIZE AND ASSIGN THE VALUE TO THE VARIABLE
   lotSize = (AccountBalance() * maxRiskPerTrade / 100 ) / (stopLossPips * nTickValue);
   // ROUNDING THE LOT SIZE TO THE ACCEPTED FORMAT
   lotSize = MathRound(lotSize / MarketInfo(Symbol(), MODE_LOTSTEP )) * MarketInfo(Symbol(), MODE_LOTSTEP);
   // NORMALIZE TO 2 NUMBER AFTER DECIMAL POINT
   // lotSize =  NormalizeDouble( lotSize, 2);
   //Print("THE LOT SIZE IS: " + lotSize);
   // WE RETURN THE LOT SIZE
   return lotSize;
} */

/*double pipsCalculator() {
   // VARIABLES DECLARATION
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double point = MarketInfo(Symbol(), MODE_POINT);

   // CALCULATION
   double tickPerPoints = tickSize / point;
   double pointValue = tickValue / tickPerPoints;

   // LOT TO RISK
   double riskLot = 0.01;
   double riskAmount = 1;

   // PIPS TO RISK
   double riskPips = riskAmount/(pointValue*riskLot);

   return riskPips;

}*/

double positionCalculator(double _pips) {

   // WE GET THE LAST TRADES IN HISTORY
   // WE NEED TO GET THE LAST TRADES IN HISTORY AND CHECK FOR LOST TRADES
   // WE WILL START WITH THE LAST CLOSED TRADES
   int lastClosedTrades = OrdersHistoryTotal();
   // RISK MANAGEMENT TRACKER
   int shrinkIndex = 0;

   for(int i = 0; i < lastClosedTrades; i++) {
      // SELECT A CURRENT ORDER
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
         // SELECT ONLY BUY AND SELL HISTORY TRADES
         if(OrderType() == ORDER_TYPE_BUY || OrderType() == ORDER_TYPE_SELL) {
            // CHECK IF WE HAD A PROFIT ON THE LAST TRADES
            if(OrderProfit() <= 0) {
               // INCREMENT THE RISK MANAGEMENT TRACKER
               shrinkIndex ++;
            } else {
               // IF WE NO LONGER HAVE ANY NEGATIVE VALUE, BREAK THE LOOP
               break;
            }
         }
      }
   }


   // VARIABLES DECLARATION
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double point = MarketInfo(Symbol(), MODE_POINT);

   // CALCULATION
   double tickPerPoints = tickSize / point;
   double pointValue = tickValue / tickPerPoints;

   // RISK AMOUNT CALCULATION
   double riskAmount = AccountBalance() * 1 / 1000;
   // riskAmount = riskAmount / 2;
   double shrinker = 0;

   // CONDITION FOR BETTER MONEY MANAGEMENT
   if(shrinkIndex > 0) {

      // THE TOTAL AMOUNT TO REMOVE
      // double shrinker = 0;
      int incrementer = 2;
      // WE LOOP TO SUBSTRACT THE AMOUNT n TIMES
      for(int i = 0; i < shrinkIndex; i++) {

         shrinker =  shrinker + (riskAmount / incrementer);
         // INCREASE THE DIVIDER
         incrementer = incrementer + 2;
      }
      // THE DIVIDER SHOULD START AT INDEX 2
      // shrinker = (AccountBalance() * 1 / 1000) / shrinkIndex;
      riskAmount = riskAmount - shrinker;
   }

   // PIPS TO LOOSE PER SINGLE TRADE
   double riskPoints = _pips;
   // LOTS TO TRADE
   double riskLots = riskAmount / (pointValue * riskPoints);

   riskLots = NormalizeDouble(riskLots,2);
   if(riskLots == 0) riskLots = 0.01;
   // Print("AMOUNT TO RISK: " + riskAmount + " SHRINKER : "+ shrinker +" AND LOTS IS: " + riskLots);
   return riskLots;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBreakEven() {
   // Print("BREAK EVEN CALLED");
   // IF THE PROFIT HAS REACHED 35% OF TARGET PROFITS, THEN MOVE THE STOP LOSS PLUS SOME PIPS IN PROFITS
   // WE LOOP THROUGH ALL ACTIVE AND PENDING ORDERS
   for(int i = 0; i < OrdersTotal(); i++) {

      // IF WE HAVE A OPEN POSITION
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         // WE CHECK IF THE SYMBOL IS EQUAL TO CURRENT SYMBOL ON CHART
         if(OrderSymbol() == Symbol()) {

            // IF WE HAVE A BUY POSITION
            if(OrderType() == OP_BUY) {
               // IF THE STOP LOSS IS BELOW THE ORDER OPEN PRICE
               if(OrderStopLoss() < OrderOpenPrice()) {
                  // CHECK IF THE CURRENT ASK PRICE IS GREATER THAN ORDER ASK PRICE
                  // IF WE HAVE MADE AT LEAST 12 PIPS IN PROFITS
                  // Ask - pipsLoss * getPipsValue()
                  if(Ask > OrderOpenPrice() + breakEvenIndex *  getPipsValue() ) {
                     // WE MODIFY THE ORDER
                     // MOVE THE STOP LOSS TO 4 POINTS ABOVE THE OPEN PRICE
                     bool modifyBuyOrder = OrderModify(OrderTicket(),OrderOpenPrice(),(OrderOpenPrice() + (breakEvenProfit * getPipsValue())), OrderTakeProfit(),0, clrNONE);

                     // CHECK FOR BUY UPDATE RESULT STATUS
                     if(modifyBuyOrder) {
                        // Print("BUY ORDER SUCCESSFULLY MODIFIED");
                     } else {
                        // Print("UNABLE TO MODIFY BUY ORDER");
                     }
                  }
               }
            }

            // IF WE HAVE A SELL SIGNAL
            if(OrderType() == OP_SELL) {
               // IF THE STOP LOSS IS STILL ABOVE THE ORDER OPEN PPRICE
               if(OrderStopLoss() > OrderOpenPrice()) {
                  // LET US CHECK IF WE HAVE MAKE AT LEAST 12 PIPS IN PROFITS
                  if(Bid < OrderOpenPrice() - breakEvenIndex *  getPipsValue() ) {
                     // MOVE THE STOP LOSS 4 POINTS BELOW THE OPEN PRICE
                     bool modifySellOrder = OrderModify(OrderTicket(),OrderOpenPrice(), (OrderOpenPrice() - (breakEvenProfit * getPipsValue())), OrderTakeProfit(),0, clrNONE );

                     // CHECK FOR SELL UPDATE RESULT STATUS
                     if(modifySellOrder) {
                        // Print("SELL ORDER SUCCESSFULLY MODIFIED");
                     } else {
                        // Print("UNABLE TO MODIFY SELL ORDER");
                     }
                  }

               }
            }

         }
      }

   }
}

void sendOrder(string signal) {

   // WE HAVE TO CHECK FOR THE LAST RESULT OF THE LAST TRADE
   // IF IT IS THE SAME TYPE AND WAS A FAILURE, IGNORE THIS TRADE
   // PLACE ONLY ONE TRADE PER SYMBOL
   // WE MUST SET A CUSTOM BREAK EVEN METHOD FOR OUR TRADES

   int openTrades = OrdersTotal();
   // RISK MANAGEMENT TRACKER
   int isLive = 0;

   for(int i = 0; i < openTrades; i++) {
      // SELECT A CURRENT ORDER
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         // SELECT ONLY BUY AND SELL HISTORY TRADES
         // IF WE HAVE THE SYMBOL IN ACTIVE TRADES, IGNORE THE TRADE
         if(OrderSymbol() == Symbol()) {
            isLive ++;
            // Print("WE HAVE ALREADY HAVE THIS OPEN TRADE: " + Symbol());
         }
      }
   }

   // WE CHECK IF THE LAST TRADE IN HISTORY OF THE SYMBOL IS LOSS AND SAME TYPE, IGNORE THE TRADE
   int closeTrades = OrdersHistoryTotal();
   // GET THE LAST STATUS RESULT
   string lastResult = "";
   // LOOP THROUGH ALL HISTORY
   for(int i = 0; i < closeTrades; i++) {
      // SELECT THE OPEN TRADE
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
         // CHECK THE RESULT OF THE LAST TRADE OF THE SAME SYMBOL
         if(OrderSymbol() == Symbol()) {
            if(OrderProfit() <= 0 && OrderType() == ORDER_TYPE_BUY ) {
               lastResult = "not buy";
               // Print("LAST BUY WAS A FAILURE");
               break;
            } else if(OrderProfit() <= 0 && OrderType()  == ORDER_TYPE_SELL) {
               lastResult = "not sell";
               // Print("LAST SELL WAS A FAILURE");
               break;
            }

         }

      }
   }

   // IF WE DO NOT HAVE ANY TRADE WITH THE SYMBOL, PLACE THE TRADE
   if(isLive < liveTradesAllowed) {
      if(signal == "BUY" && lastResult != "not buy") {
         // SEND A BUY ORDER
         buyOrder();
      } else if(signal == "SELL" && lastResult != "not sell") {
         // SEND A SELL ORDER
         sellOrder();
      }
   }


}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


// WE SHOULD SET OUR DYNAMIC STOP LOSS AND TAKE PROFIT CALCULATOR AFTER ANALYSIS

void buyOrder() {

   // CALCULATING THE TAKE PROFIT
   double takeProfit = Ask + pipsProfit * getPipsValue();
   // CALCULATING THE STOP LOSS
   double stopLoss = Ask - pipsLoss * getPipsValue();

   // Print("SENDING A BUY ORDER");

   // LOGIC HERE FOR PLACING A BUY ORDER
   if(OrdersTotal() <= maxOpenTrades) {
      // CALCULATE THE POSITION SIZE
      double positionSize = positionCalculator(pipsLoss);
      // Print("LOT SIZE IN BUY: " + positionSize);
      // PLACE AN ORDER IF WE HAVE LESS THAN OR 20 ACTIVE TRADES
      int buyPosition = OrderSend(Symbol(), OP_BUY, positionSize, Ask, slippage, stopLoss, takeProfit, "BUY",0,0, Green);
      // int buyPosition = OrderSend(Symbol(), OP_BUY, 0.01, Ask, 3, stopLoss, takeProfit, "BUY",0,0, clrNONE);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellOrder() {

   // CALCULATING THE TAKE PROFIT
   double takeProfit = Bid - pipsProfit * getPipsValue();
   // CALCULATING THE STOP LOSS
   double stopLoss = Bid + pipsLoss * getPipsValue();

   // Print("SENDING A SELL ORDER");

   // LOGIC HERE FOR PLACING A SELL ORDER
   if(OrdersTotal() <= maxOpenTrades) {
      // CALCULATE THE POSITION SIZE
      double positionSize = positionCalculator(pipsLoss);
      // Print("LOT SIZE IN SELL: " + positionSize);
      // PLACE AN ORDER IF WE HAVE LESS THAN OR 20 ACTIVE TRADES
      int sellPosition = OrderSend(_Symbol,OP_SELL,positionSize,Bid,slippage,stopLoss,takeProfit,"SELL",0,0, Green);
      // int sellPosition = OrderSend(Symbol(),OP_SELL,0.01,Bid,3,stopLoss,takeProfit,"SELL",0,0, clrNONE);
   }
}
//+------------------------------------------------------------------+
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//|                                                Signal_Filter.mqh |
//|                                                Ntavigwa Bashombe |
//|                                         https://www.bashombe.com |
//+------------------------------------------------------------------+
#property copyright "Ntavigwa Bashombe"
#property link      "https://www.bashombe.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
string checkSignal(int noisyFactor, int maxValuesInRange, int trend_EMA_Value, int signalPipsDifference) {

// CONTAINS DATA PRICES
   double MACD_Line_Data[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}; // MACD LINE DATA
   double SIGNAL_Line_Data[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0,}; // SIGNAL LINE DATA

   double MARKET_TREND; // MARKET TREND ANALYSER

// LET US STORE THE LAST TWENTY CLOSING PRICE AND THE LAST 20 100EMA VALUES
   double last25_ClosingPrice[50]; // LAST 25 CLOSING PRICES
   double last25_OpenPrice[50]; // LAST 25 OPEN PRICES
   double last25_100EMA[50]; // LAST 25 100EMA VALUES

// CONTAINS THE SIGNAL TO TRADE
   string entry = "";

// WE STORE FROM THE NEWEST CANDLES VALUES TO THE OLDEST CANDLES VALUES
   // ArraySetAsSeries(MACD_LINE_DATA, true); // MACD LINE DATA
   // ArraySetAsSeries(SIGNAL_LINE_DATA, true); // SIGNAL LINE DATA
   // ArraySetAsSeries(MARKET_TREND, true); // 100 EMA DATA
   // ArraySetAsSeries(last25_ClosingPrice, true); // LAST 25 CLOSE PRICE
   // ArraySetAsSeries(last25_OpenPrice, true); // LAST 25 OPEN PRICE
   // ArraySetAsSeries(last25_100EMA, true); // LAST 25 100EMA VALUES

// LET US STORE THE LAST FIVE ELEMENTS OF EACH INDICATOR
   for(int i = 0; i < ArraySize(MACD_Line_Data); i++) {
      // STORE MACD DATA
      MACD_Line_Data[i] = iMACD(Symbol(),PERIOD_M5,12,26,9,PRICE_CLOSE,MODE_MAIN,i);
      // STORE SIGNAL DATA
      SIGNAL_Line_Data[i] = iMACD(Symbol(),PERIOD_M5,12,26,9,PRICE_CLOSE,MODE_SIGNAL,i);
      // Print(i + ") " + MACD_LINE_DATA[i] + " - " + SIGNAL_LINE_DATA[i] + " - " + MARKET_TREND[i]);
   }

   // STORE TREND MARKET DATA
   MARKET_TREND = iMA(Symbol(), PERIOD_M5, trend_EMA_Value, 0, MODE_EMA, PRICE_CLOSE,0);

   // LET US GET THE BID AND ASK PRICE TO DETERMINE THE TREND OF THE MARKET
   double closingPrice = iClose(Symbol(), PERIOD_M5, 0);

   // Print("THE LAST MOVING AVERAGE IS: " + MARKET_TREND[0] + " AND THE LAST CLOSING PRICE IS: " + closingPrice);

   // WE HAVE TO DETECT A NOISY MARKET TO AVOID TRADING IN THAT TIME
   // NOISY MARKET FILTER CONDITION GOES HERE
   // COUNTER THE AMOUNT OF TIME THE 100 EMA WAS BETWEEN
   // THE CLOSING AND THE OPEN PRICE FOR THE LAST 20 CANDLES
   int increment = 0;
   // NOISY FACTOR
   // THIS INCREASE THE RANGE IN WHICH THE SIGNAL SHOULD NEVER BE INCLUDED
   // OPEN PRICE - 40
   // CLOSE PRICE + 40
   // IF THE 100 EMA IS BETWEEN THOSE TWO RANGES, IGNORE THE SIGNAL


   // LET US LOOP TO STORE THE VALUES
   for(int i = 0; i < ArraySize(last25_100EMA); i++ ) {
      // STORING THE CLOSING PRICE
      last25_ClosingPrice[i] = iClose(Symbol(), PERIOD_M5, i);
      // STORING THE LAST 15 OPEN PRICE
      last25_OpenPrice[i] = iOpen(Symbol(),PERIOD_M5,i);
      // STORING THE LAST 100 EMA VALUES
      last25_100EMA[i] = iMA(Symbol(), PERIOD_M5, trend_EMA_Value, 0, MODE_EMA, PRICE_CLOSE,i);

      // DECLARATION OF LOCAL VARIABLES
      // WE ADD 10 PIPS TO ALL VALUES FOR A NOISY TREND DETECTOR
      double closePrice = last25_ClosingPrice[i] + (noisyFactor *  getPipsValue() );
      double openPrice  = last25_OpenPrice[i] + (noisyFactor *  getPipsValue()) ;
      // LAST 100EMA VALUE
      double lastEMA    = last25_100EMA[i];

      // BUY CANDLES CONDITION
      // BUY CANDLE ==> CLOSE PRICE > OPEN PRICE
      // SELL CANDLE ==> OPEN PRICE > CLOSE PRICE
      if((closePrice >= lastEMA && openPrice <= lastEMA) || (closePrice <= lastEMA && openPrice >= lastEMA)) {
         increment++;
      }
   }

   // IF WE HAVE MORE THAN 10 VALUES THAT TOUCHES THE 100 EMA, IGNORE ANY SIGNAL AT THIS TIME
   // IF WE HAVE MORE THAN 5/25 VALUE, IGNORE THE TRADE [5/25 is 20%]
   if(increment > maxValuesInRange) {

      // Print("NOISY MARKET...");

   } else {

      // LET US DETECT HOW MANY CANDLE ARE BULLISH AND HOW MANY ARE BEAR
      // FIRST PART OF THE CONDITION
      int bullishPart1 = 0;
      int bearPart1 = 0;
      // SECOND PART OF THE CONDITION
      int bullishPart2 = 0;
      int bearPart2 = 0;
      // SEPARATOR OF FIRST PART TO CONSIDER AND SECOND PART OF CONFIRMATION
      int signal_Index = 2;
      // LOOP THROUGH THE VALUES TO GET THE NUMBER OF BULLISSH AND BEAR CANDLES
      for(int i = 0; i < ArraySize(MACD_Line_Data); i++) {
         // WE COUNT THE NUMBER OF BULL AND BEAR CANDLES IN THE FIRST PART
         if(i < signal_Index) {
            if(iClose(Symbol(),PERIOD_M5,i) > iOpen(Symbol(),PERIOD_M5,i)) {
               bullishPart1++;
            } else {
               bearPart1++;
            }
         }
         // WE COUNT THE BULL AND BEAR IN SECOND PART, LEAVING THE SIGNAL VALIDATOR CANDLE
         else if(i > signal_Index) {
            if(iClose(Symbol(),PERIOD_M5,i) > iOpen(Symbol(),PERIOD_M5,i)) {
               bullishPart2++;
            } else {
               bearPart2++;
            }
         }

      }

      // Print("NO NOISY MARKET DETECTED");
      // Print("WE TRUST THIS SIGNAL IN THIS AREA, WE CAN TRADE THOSE SIGNALS");
      // CONDITION FOR TREND FILTERING

      if(MARKET_TREND < closingPrice) {
         // Print("WE ARE IN A BULLISH MARKET: ONLY BUY SIGNAL");
         // Comment("WE ARE IN A BULLISH MARKET: ONLY BUY SIGNAL");
         // WE HAVE TO ADD A DELAY TO OUR SIGNAL AND WAIT FOR THE TREND CONFIRMATION WITH 2 or 3 CANDLES
         // IF WE HAVE AT LEAST ONE BULL CANDLE IN THE PREEVIOUS CANDLE, CONSIDER THE SIGNAL
         // IF WE HAVE AT LEAST 2/3 CANDLE AFTER THE SIGNAL THAT ARE BULLISH CANDLE, CONSIDER THE SIGNAL
         if(bullishPart1 >= 1 && bullishPart2 >= 2) {
            // Print("BULLISH PART 1: " + bullishPart1 + " - BULLISH PART 2: " + bullishPart2);
            // SEND A BUY SIGNAL
            if((MACD_Line_Data[signal_Index] > SIGNAL_Line_Data[signal_Index]) && (MACD_Line_Data[signal_Index + 1] < SIGNAL_Line_Data[signal_Index + 1])) {

               // IF THE DISTANCE FROM 100EMA AND THE CLOSING PRICE IS GREATER THAN 10 PIPS
               // THE DIFFERENCE IN PIPS HAS TO BE LESS THAN THE VALUE SPECIFIED
               if(((closingPrice - MARKET_TREND) / getPipsValue()) < signalPipsDifference) {
                  // WE HAVE A BUY SIGNAL
                  entry = "BUY";
                  // Print("BUYING");
               }

            }
         }


      } else if(MARKET_TREND > closingPrice) {
         // WE HAVE TO ADD A DELAY TO OUR SIGNAL AND WAIT FOR THE TREND CONFIRMATION WITH 2 or 3 CANDLES
         // IF WE HAVE AT LEAST ONE BEAR CANDLE IN THE PREVIOUS TRENS, CONSIDER THE SIGNAL
         // IF WE HAVE AT LEAST 2/3 CANDLE AFTER THE SIGNAL THAT ARE BEARISH CANDLE, CONSIDER THE SIGNAL
         if(bearPart1 >= 1 && bearPart2 >= 2) {
            // Print("WE ARE IN A BEARISH MARKET: ONLY SELL SIGNAL");
            //Print("BEAR PART 1: " + bearPart1 + " - BEAR PART 2: " + bearPart2);
            // Comment("WE ARE IN A BEARISH MARKET: ONLY SELL SIGNAL");
            // SEND A SELL SIGNAL
            if((MACD_Line_Data[signal_Index] < SIGNAL_Line_Data[signal_Index]) && (MACD_Line_Data[signal_Index + 1] > SIGNAL_Line_Data[signal_Index + 1])) {
               // IF THE DISTANCE FROM 100EMA AND THE CLOSING PRICE IS GREATER THAN 10 PIPS
               if(((MARKET_TREND - closingPrice) / getPipsValue()) < signalPipsDifference) {
                  // WE HAVE A SELL SIGNAL
                  entry = "SELL";
                  // Print("SELLING");
               }
            }
         }
      }
      /*else if(MARKET_TREND == closingPrice) {
         Print("WE ARE IN A STAGGERING MARKET: DO NOT TRADE");
         Comment("WE ARE IN A STAGGERING MARKET: DO NOT TRADE");
      } else {
         Print("SORRY! WE WERE UNABLE TO DETERMINE THE TREND.");
         Comment("SORRY! WE WERE UNABLE TO DETERMINE THE TREND.");
      }*/
   }

   return entry;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPipsValue() {
   // FOR 5 DECIMAL PPLACES CURRENCY
   if(Digits >= 4) {
      return 0.0001;
   } else {
      // FOR 3 DECIAML PLACES CURRENCY
      return 0.01;
   }
}
//+------------------------------------------------------------------+
