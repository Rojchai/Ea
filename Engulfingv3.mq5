//+------------------------------------------------------------------+
//|                    Engulfing_1M_Backtest.mq5                     |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>

CTrade trade;

input double Lots = 0.1;
input ulong  MagicNumber = 123456;

// เวลาของแท่งล่าสุดที่ EA ตรวจแล้ว
datetime lastBarTime = 0;

// เวลาที่เปิด Position
datetime entryBarTime = 0;


//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);

   // EA นี้ออกแบบสำหรับ M1
   if(_Period != PERIOD_M1)
   {
      Print("ERROR: Please run this EA on M1 timeframe.");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| ตรวจ Position ของ EA                                             |
//+------------------------------------------------------------------+
bool HasOurPosition()
{
   if(!PositionSelect(_Symbol))
      return false;

   ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);

   return (magic == MagicNumber);
}


//+------------------------------------------------------------------+
//| ปิด Position เมื่อหมดอายุ 1 แท่ง                                |
//+------------------------------------------------------------------+
void CheckExpiry()
{
   if(!HasOurPosition())
   {
      entryBarTime = 0;
      return;
   }

   datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);

   // เปิดตอนต้นแท่งหนึ่ง
   // เมื่อเข้าสู่ต้นแท่งถัดไป = ครบ 1 นาที
   if(currentBarTime > entryBarTime)
   {
      if(trade.PositionClose(_Symbol))
      {
         Print("Position closed after 1 minute.");
         entryBarTime = 0;
      }
   }
}


//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   //===============================================================
   // ตรวจหมดอายุก่อน
   //===============================================================
   CheckExpiry();


   //===============================================================
   // ถ้ายังมี Position อยู่ ห้ามเปิดใหม่
   //===============================================================
   if(HasOurPosition())
      return;


   //===============================================================
   // เวลาของแท่งปัจจุบัน
   //===============================================================
   datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);

   if(currentBarTime == 0)
      return;


   // ยังไม่เกิดแท่งใหม่
   if(currentBarTime == lastBarTime)
      return;


   // เกิดแท่งใหม่แล้ว
   lastBarTime = currentBarTime;


   //===============================================================
   // ต้องมีอย่างน้อย 3 แท่ง
   //===============================================================
   if(Bars(_Symbol, PERIOD_M1) < 3)
      return;


   //===============================================================
   // Candle 2 = แท่งก่อนหน้า
   // Candle 1 = แท่งล่าสุดที่เพิ่งปิด
   //===============================================================

   double open2  = iOpen(_Symbol, PERIOD_M1, 2);
   double close2 = iClose(_Symbol, PERIOD_M1, 2);

   double open1  = iOpen(_Symbol, PERIOD_M1, 1);
   double close1 = iClose(_Symbol, PERIOD_M1, 1);


   //===============================================================
   // Bullish Engulfing
   //===============================================================

   bool bullishEngulfing =
      (close2 < open2) &&
      (close1 > open1) &&
      (open1 <= open2) &&
      (close1 >= close2);


   //===============================================================
   // Bearish Engulfing
   //===============================================================

   bool bearishEngulfing =
      (close2 > open2) &&
      (close1 < open1) &&
      (open1 >= open2) &&
      (close1 <= close2);


   //===============================================================
   // BUY
   //===============================================================

   if(bullishEngulfing)
   {
      if(trade.Buy(Lots, _Symbol, 0.0, 0.0, 0.0,
                   "Bullish Engulfing"))
      {
         entryBarTime = currentBarTime;

         Print("BUY opened at ",
               TimeToString(entryBarTime, TIME_DATE|TIME_SECONDS));
      }

      return;
   }


   //===============================================================
   // SELL
   //===============================================================

   if(bearishEngulfing)
   {
      if(trade.Sell(Lots, _Symbol, 0.0, 0.0, 0.0,
                    "Bearish Engulfing"))
      {
         entryBarTime = currentBarTime;

         Print("SELL opened at ",
               TimeToString(entryBarTime, TIME_DATE|TIME_SECONDS));
      }

      return;
   }
}
