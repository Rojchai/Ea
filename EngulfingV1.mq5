//+------------------------------------------------------------------+
//|                                                   EngulfingEA.mq5 |
//|                        Simple Engulfing Backtest EA              |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>

CTrade trade;

//--- ตั้งค่าจำนวนเงินที่ใช้ต่อการเทรด
input double LotSize = 0.01;

//--- เก็บเวลาที่แท่งล่าสุดที่ตรวจไปแล้ว
datetime LastBarTime = 0;

//--- เก็บเวลาที่เปิดออเดอร์
datetime EntryTime = 0;

//--- สถานะว่าตอนนี้มีออเดอร์ของ EA อยู่หรือไม่
bool TradeActive = false;


//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //==============================================================
   // 1. ถ้ามีออเดอร์อยู่ ให้ตรวจว่าครบ 1 นาทีหรือยัง
   //==============================================================

   if(TradeActive)
   {
      if(TimeCurrent() >= EntryTime + 60)
      {
         CloseTrade();

         TradeActive = false;
         EntryTime = 0;
      }

      return;
   }


   //==============================================================
   // 2. ตรวจว่ามีแท่งใหม่ปิดแล้วหรือยัง
   //==============================================================

   datetime CurrentBarTime = iTime(_Symbol, _Period, 0);

   if(CurrentBarTime == LastBarTime)
      return;

   LastBarTime = CurrentBarTime;


   //==============================================================
   // 3. ดึงข้อมูลแท่งเทียน 2 แท่งที่ปิดแล้ว
   //
   //    shift 1 = แท่งล่าสุดที่เพิ่งปิด
   //    shift 2 = แท่งก่อนหน้า
   //==============================================================

   double Open1  = iOpen(_Symbol, _Period, 1);
   double Close1 = iClose(_Symbol, _Period, 1);

   double Open2  = iOpen(_Symbol, _Period, 2);
   double Close2 = iClose(_Symbol, _Period, 2);


   //==============================================================
   // 4. ตรวจสีของแท่ง
   //==============================================================

   bool PreviousBearish = (Close2 < Open2);
   bool PreviousBullish = (Close2 > Open2);

   bool CurrentBullish = (Close1 > Open1);
   bool CurrentBearish = (Close1 < Open1);


   //==============================================================
   // 5. Bullish Engulfing
   //
   //    แท่งก่อนหน้า = แดง
   //    แท่งปัจจุบัน = เขียว
   //    Body ปัจจุบันกลืน Body ก่อนหน้า
   //==============================================================

   bool BullishEngulfing =
      PreviousBearish &&
      CurrentBullish &&
      Open1 <= Open2 &&
      Close1 >= Close2;


   //==============================================================
   // 6. Bearish Engulfing
   //
   //    แท่งก่อนหน้า = เขียว
   //    แท่งปัจจุบัน = แดง
   //    Body ปัจจุบันกลืน Body ก่อนหน้า
   //==============================================================

   bool BearishEngulfing =
      PreviousBullish &&
      CurrentBearish &&
      Open1 >= Open2 &&
      Close1 <= Close2;


   //==============================================================
   // 7. เปิด Buy
   //==============================================================

   if(BullishEngulfing)
   {
      if(trade.Buy(LotSize, _Symbol))
      {
         TradeActive = true;
         EntryTime = TimeCurrent();
      }

      return;
   }


   //==============================================================
   // 8. เปิด Sell
   //==============================================================

   if(BearishEngulfing)
   {
      if(trade.Sell(LotSize, _Symbol))
      {
         TradeActive = true;
         EntryTime = TimeCurrent();
      }

      return;
   }
}


//+------------------------------------------------------------------+
//| ปิด Position                                                     |
//+------------------------------------------------------------------+
void CloseTrade()
{
   if(PositionSelect(_Symbol))
   {
      trade.PositionClose(_Symbol);
   }
}
