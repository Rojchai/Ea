//+------------------------------------------------------------------+
//|                  Engulfing_Backtest.mq5                          |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>

CTrade trade;

//====================================================================
// INPUT
//====================================================================

// Timeframe สำหรับทดสอบ
input ENUM_TIMEFRAMES TestTimeframe = PERIOD_M1;

// Lot
input double Lots = 0.1;

// Magic Number
input ulong MagicNumber = 123456;


//====================================================================
// GLOBAL
//====================================================================

datetime LastBarTime = 0;
datetime EntryBarTime = 0;


//====================================================================
// INIT
//====================================================================

int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);

   return(INIT_SUCCEEDED);
}


//====================================================================
// ตรวจว่า Position ของ EA มีอยู่หรือไม่
//====================================================================

bool HasPosition()
{
   if(!PositionSelect(_Symbol))
      return false;

   ulong magic =
      (ulong)PositionGetInteger(POSITION_MAGIC);

   return(magic == MagicNumber);
}


//====================================================================
// ปิดเมื่อครบ 1 แท่งของ Timeframe ที่เลือก
//====================================================================

void CheckExpiry()
{
   if(!HasPosition())
   {
      EntryBarTime = 0;
      return;
   }

   datetime CurrentBarTime =
      iTime(_Symbol, TestTimeframe, 0);

   if(CurrentBarTime > EntryBarTime)
   {
      if(trade.PositionClose(_Symbol))
      {
         EntryBarTime = 0;
      }
   }
}


//====================================================================
// MAIN
//====================================================================

void OnTick()
{
   // ---------------------------------------------------------------
   // เช็กว่าถึงเวลาปิดหรือยัง
   // ---------------------------------------------------------------

   CheckExpiry();


   // ---------------------------------------------------------------
   // ถ้ายังมี Position อยู่ ไม่เปิดเพิ่ม
   // ---------------------------------------------------------------

   if(HasPosition())
      return;


   // ---------------------------------------------------------------
   // เวลาแท่งปัจจุบัน
   // ---------------------------------------------------------------

   datetime CurrentBarTime =
      iTime(_Symbol, TestTimeframe, 0);

   if(CurrentBarTime == 0)
      return;


   // ยังเป็นแท่งเดิม → ไม่ต้องคำนวณซ้ำ
   if(CurrentBarTime == LastBarTime)
      return;


   // เกิดแท่งใหม่
   LastBarTime = CurrentBarTime;


   // ---------------------------------------------------------------
   // ต้องมีอย่างน้อย 3 แท่ง
   // ---------------------------------------------------------------

   if(Bars(_Symbol, TestTimeframe) < 3)
      return;


   // ===============================================================
   // Candle [2]
   // ===============================================================

   double Open2 =
      iOpen(_Symbol, TestTimeframe, 2);

   double Close2 =
      iClose(_Symbol, TestTimeframe, 2);


   // ===============================================================
   // Candle [1]
   // ===============================================================

   double Open1 =
      iOpen(_Symbol, TestTimeframe, 1);

   double Close1 =
      iClose(_Symbol, TestTimeframe, 1);


   // ===============================================================
   // Body Size
   //
   // Body = |Open - Close|
   // ===============================================================

   double Body2 =
      MathAbs(Open2 - Close2);

   double Body1 =
      MathAbs(Open1 - Close1);


   // ===============================================================
   // สีแท่ง
   // ===============================================================

   bool Candle2Red =
      (Close2 < Open2);

   bool Candle2Green =
      (Close2 > Open2);

   bool Candle1Red =
      (Close1 < Open1);

   bool Candle1Green =
      (Close1 > Open1);


   // ===============================================================
   // BUY
   //
   // [2] แดง
   // [1] เขียว
   // Body[1] > Body[2]
   // ===============================================================

   bool BuySignal =
      Candle2Red &&
      Candle1Green &&
      Body1 > Body2;


   // ===============================================================
   // SELL
   //
   // [2] เขียว
   // [1] แดง
   // Body[1] > Body[2]
   // ===============================================================

   bool SellSignal =
      Candle2Green &&
      Candle1Red &&
      Body1 > Body2;


   // ===============================================================
   // BUY
   // ===============================================================

   if(BuySignal)
   {
      if(trade.Buy(
         Lots,
         _Symbol,
         0.0,
         0.0,
         0.0,
         "Engulfing BUY"))
      {
         EntryBarTime = CurrentBarTime;
      }

      return;
   }


   // ===============================================================
   // SELL
   // ===============================================================

   if(SellSignal)
   {
      if(trade.Sell(
         Lots,
         _Symbol,
         0.0,
         0.0,
         0.0,
         "Engulfing SELL"))
      {
         EntryBarTime = CurrentBarTime;
      }

      return;
   }
}
