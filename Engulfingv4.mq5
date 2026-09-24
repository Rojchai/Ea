//+------------------------------------------------------------------+
//|                 Engulfing_1M_Backtest.mq5                       |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>

CTrade trade;

input double Lots = 0.1;
input ulong  MagicNumber = 123456;

datetime lastBarTime = 0;
datetime entryBarTime = 0;


//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(_Period != PERIOD_M1)
   {
      Print("EA requires M1 timeframe.");
      return(INIT_FAILED);
   }

   trade.SetExpertMagicNumber(MagicNumber);

   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Check our position                                               |
//+------------------------------------------------------------------+
bool HasOurPosition()
{
   if(!PositionSelect(_Symbol))
      return false;

   return((ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber);
}


//+------------------------------------------------------------------+
//| Close after exactly one M1 candle                                 |
//+------------------------------------------------------------------+
void CheckExpiry()
{
   if(!HasOurPosition())
   {
      entryBarTime = 0;
      return;
   }

   datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);

   if(currentBarTime > entryBarTime)
   {
      if(trade.PositionClose(_Symbol))
      {
         entryBarTime = 0;
      }
   }
}


//+------------------------------------------------------------------+
//| Main                                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // ตรวจหมดอายุ
   CheckExpiry();

   // ถ้ายังมี Position อยู่ ห้ามเปิดใหม่
   if(HasOurPosition())
      return;

   // เวลาแท่งปัจจุบัน
   datetime currentBarTime = iTime(_Symbol, PERIOD_M1, 0);

   if(currentBarTime == 0)
      return;

   // ยังไม่มีแท่งใหม่
   if(currentBarTime == lastBarTime)
      return;

   // มีแท่งใหม่ = แท่งก่อนหน้าเพิ่งปิด
   lastBarTime = currentBarTime;


   // ต้องมีข้อมูลอย่างน้อย 3 แท่ง
   if(Bars(_Symbol, PERIOD_M1) < 3)
      return;


   //==============================================================
   // Candle 2 = แท่งเก่า
   // Candle 1 = Engulfing candle ที่เพิ่งปิด
   //==============================================================

   double open2  = iOpen(_Symbol, PERIOD_M1, 2);
   double close2 = iClose(_Symbol, PERIOD_M1, 2);

   double open1  = iOpen(_Symbol, PERIOD_M1, 1);
   double close1 = iClose(_Symbol, PERIOD_M1, 1);


   //==============================================================
   // สีของแท่ง
   //==============================================================

   bool candle2Bearish = close2 < open2;
   bool candle2Bullish = close2 > open2;

   bool candle1Bullish = close1 > open1;
   bool candle1Bearish = close1 < open1;


   //==============================================================
   // BULLISH ENGULFING
   //
   // แท่งเก่าแดง
   // แท่งใหม่เขียว
   //
   // Body ใหม่ต้องครอบ Body เก่าทั้งหมด
   //
   //       Open2
   //         |
   //         v
   //      +-----+
   //      |     |
   //      |     |  Body เก่า
   //      |     |
   //      +-----+
   //         ^
   //         |
   //       Close2
   //
   // Body ใหม่:
   // Open1 <= Close2
   // Close1 >= Open2
   //==============================================================

   bool bullishEngulfing =
      candle2Bearish &&
      candle1Bullish &&
      open1 <= close2 &&
      close1 >= open2;


   //==============================================================
   // BEARISH ENGULFING
   //
   // แท่งเก่าเขียว
   // แท่งใหม่แดง
   //
   // Body ใหม่ต้องครอบ Body เก่าทั้งหมด
   //==============================================================

   bool bearishEngulfing =
      candle2Bullish &&
      candle1Bearish &&
      open1 >= close2 &&
      close1 <= open2;


   //==============================================================
   // BUY
   //==============================================================

   if(bullishEngulfing)
   {
      if(trade.Buy(
            Lots,
            _Symbol,
            0.0,
            0.0,
            0.0,
            "Bullish Engulfing"))
      {
         entryBarTime = currentBarTime;

         Print(
            "BUY | Engulfing | ",
            TimeToString(currentBarTime,
                         TIME_DATE|TIME_SECONDS)
         );
      }

      return;
   }


   //==============================================================
   // SELL
   //==============================================================

   if(bearishEngulfing)
   {
      if(trade.Sell(
            Lots,
            _Symbol,
            0.0,
            0.0,
            0.0,
            "Bearish Engulfing"))
      {
         entryBarTime = currentBarTime;

         Print(
            "SELL | Engulfing | ",
            TimeToString(currentBarTime,
                         TIME_DATE|TIME_SECONDS)
         );
      }

      return;
   }
}
