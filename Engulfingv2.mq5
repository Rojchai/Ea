//+------------------------------------------------------------------+
//|                  Engulfing_1M_Backtest.mq5                       |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>

CTrade trade;

input double Lots = 0.01;

datetime lastBarTime = 0;

//--- ข้อมูลออเดอร์ที่กำลังถือ
ulong    positionTicket = 0;
datetime entryTime      = 0;


//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(123456);

   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   //===============================================================
   // 1. ถ้ามี Position ของ EA อยู่
   //    ตรวจว่าถือครบ 60 วินาทีหรือยัง
   //===============================================================

   if(positionTicket != 0)
   {
      if(PositionSelectByTicket(positionTicket))
      {
         if(TimeCurrent() - entryTime >= 60)
         {
            trade.PositionClose(positionTicket);

            positionTicket = 0;
            entryTime      = 0;
         }
      }
      else
      {
         // Position ถูกปิดไปแล้ว
         positionTicket = 0;
         entryTime      = 0;
      }

      return;
   }


   //===============================================================
   // 2. ตรวจว่ามีแท่งใหม่เกิดขึ้นหรือยัง
   //===============================================================

   datetime currentBarTime = iTime(_Symbol, _Period, 0);

   if(currentBarTime == 0)
      return;

   if(currentBarTime == lastBarTime)
      return;

   lastBarTime = currentBarTime;


   //===============================================================
   // 3. ตรวจว่ามีข้อมูลอย่างน้อย 3 แท่ง
   //===============================================================

   if(Bars(_Symbol, _Period) < 3)
      return;


   //===============================================================
   // 4. แท่งที่ใช้ตรวจ
   //
   //    Candle 2 = แท่งก่อนหน้า
   //    Candle 1 = แท่ง Engulfing ที่เพิ่งปิด
   //===============================================================

   double open2  = iOpen(_Symbol, _Period, 2);
   double close2 = iClose(_Symbol, _Period, 2);

   double open1  = iOpen(_Symbol, _Period, 1);
   double close1 = iClose(_Symbol, _Period, 1);


   //===============================================================
   // 5. Bullish Engulfing
   //
   // Candle 2 = แดง
   // Candle 1 = เขียว
   //
   // Body Candle 1 กลืน Body Candle 2
   //===============================================================

   bool bullishEngulfing =
      (close2 < open2) &&
      (close1 > open1) &&
      (open1 <= open2) &&
      (close1 >= close2);


   //===============================================================
   // 6. Bearish Engulfing
   //
   // Candle 2 = เขียว
   // Candle 1 = แดง
   //
   // Body Candle 1 กลืน Body Candle 2
   //===============================================================

   bool bearishEngulfing =
      (close2 > open2) &&
      (close1 < open1) &&
      (open1 >= open2) &&
      (close1 <= close2);


   //===============================================================
   // 7. BUY
   //===============================================================

   if(bullishEngulfing)
   {
      if(trade.Buy(Lots, _Symbol, 0, 0, 0, "Bullish Engulfing"))
      {
         positionTicket = trade.ResultOrder();

         if(PositionSelect(_Symbol))
         {
            positionTicket = PositionGetInteger(POSITION_TICKET);
            entryTime = TimeCurrent();
         }
      }

      return;
   }


   //===============================================================
   // 8. SELL
   //===============================================================

   if(bearishEngulfing)
   {
      if(trade.Sell(Lots, _Symbol, 0, 0, 0, "Bearish Engulfing"))
      {
         positionTicket = trade.ResultOrder();

         if(PositionSelect(_Symbol))
         {
            positionTicket = PositionGetInteger(POSITION_TICKET);
            entryTime = TimeCurrent();
         }
      }

      return;
   }
}
